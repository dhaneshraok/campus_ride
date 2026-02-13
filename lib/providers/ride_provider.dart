import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/ride_model.dart';
import '../models/ride_offer_model.dart';
import '../models/user_model.dart';
import '../services/ride_service.dart';
import '../services/ride_offer_service.dart';
import '../services/chat_service.dart';
import '../services/notification_service.dart';
import '../constants/notification_types.dart';

class RideProvider extends ChangeNotifier {
  final RideService _rideService;
  final RideOfferService _offerService;
  final ChatService _chatService;
  final NotificationService _notificationService;

  List<Ride> _openRides = [];
  List<Ride> _myRiderRides = [];
  List<Ride> _myDriverRides = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  StreamSubscription? _openRidesSub;
  StreamSubscription? _riderRidesSub;
  StreamSubscription? _driverRidesSub;

  RideProvider({
    RideService? rideService,
    RideOfferService? offerService,
    ChatService? chatService,
    NotificationService? notificationService,
  })  : _rideService = rideService ?? RideService(),
        _offerService = offerService ?? RideOfferService(),
        _chatService = chatService ?? ChatService(),
        _notificationService = notificationService ?? NotificationService();

  List<Ride> get openRides {
    if (_searchQuery.isEmpty) return _openRides;
    final q = _searchQuery.toLowerCase();
    return _openRides.where((r) {
      return r.destination.toLowerCase().contains(q) ||
          r.pickupArea.toLowerCase().contains(q) ||
          r.riderName.toLowerCase().contains(q);
    }).toList();
  }

  List<Ride> get myRiderRides => _myRiderRides;
  List<Ride> get myDriverRides => _myDriverRides;

  List<Ride> get allMyRides {
    final combined = [..._myRiderRides, ..._myDriverRides];
    final seen = <String>{};
    combined.retainWhere((r) => seen.add(r.id));
    combined.sort((a, b) => (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000)));
    return combined;
  }

  List<Ride> get activeRides =>
      allMyRides.where((r) => r.isActive && !r.isStaleOpenRide).toList();

  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void initStreams(String uid) {
    _openRidesSub?.cancel();
    _riderRidesSub?.cancel();
    _driverRidesSub?.cancel();

    _openRidesSub = _rideService.openRidesStream().listen(
      (rides) {
        _openRides = rides;
        notifyListeners();
      },
      onError: (e) {
        _error = 'Failed to load rides';
        notifyListeners();
      },
    );

    _riderRidesSub = _rideService.riderRidesStream(uid).listen(
      (rides) {
        _myRiderRides = rides;
        notifyListeners();
      },
    );

    _driverRidesSub = _rideService.driverRidesStream(uid).listen(
      (rides) {
        _myDriverRides = rides;
        notifyListeners();
      },
    );
  }

  Future<String?> createRide(Ride ride) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final rideId = await _rideService.createRide(ride);
      await _chatService.sendSystemMessage(
        rideId: rideId,
        text: '${ride.riderName} created a ride request.',
      );
      return rideId;
    } catch (e) {
      _error = 'Failed to create ride';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Offer Flow Methods ───────────────────────────────────────────

  /// Driver creates an offer on an OPEN ride
  Future<bool> createOffer(String rideId, AppUser driver) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (await _offerService.driverHasActiveRide(driver.uid)) {
        _error =
            'You already have an active ride. Complete it before offering a new one.';
        return false;
      }

      final success = await _offerService.createOffer(rideId, driver);
      if (success) {
        // Best-effort side effects: the offer is already created.
        try {
          final ride = await _rideService.getRide(rideId);
          if (ride != null) {
            await _chatService.sendSystemMessage(
              rideId: rideId,
              text: '${driver.fullName} offered to drive.',
              threadDriverUid: driver.uid,
            );
            await _notificationService.createNotification(
              recipientUid: ride.riderUid,
              type: NotificationTypes.offerReceived,
              title: 'New Driver Offer',
              body:
                  '${driver.fullName} wants to drive your ride to ${ride.destination}.',
              rideId: rideId,
              senderUid: driver.uid,
            );
          }
        } catch (_) {}
      }
      return success;
    } on FirebaseException catch (e) {
      _error = e.message ?? 'Failed to create offer';
      return false;
    } catch (e) {
      _error = 'Failed to create offer';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Driver withdraws their offer
  Future<void> withdrawOffer(String rideId, AppUser driver) async {
    try {
      await _offerService.withdrawOffer(rideId, driver.uid);
      final ride = await _rideService.getRide(rideId);
      if (ride != null) {
        await _chatService.sendSystemMessage(
          rideId: rideId,
          text: '${driver.fullName} withdrew their offer.',
          threadDriverUid: driver.uid,
        );
        await _notificationService.createNotification(
          recipientUid: ride.riderUid,
          type: NotificationTypes.offerWithdrawn,
          title: 'Offer Withdrawn',
          body:
              '${driver.fullName} withdrew their offer for your ride to ${ride.destination}.',
          rideId: rideId,
          senderUid: driver.uid,
        );
      }
    } catch (e) {
      _error = 'Failed to withdraw offer';
      notifyListeners();
    }
  }

  /// Rider confirms a specific driver (step 1)
  Future<void> riderConfirmOffer(
    String rideId,
    String driverUid,
    String driverName,
  ) async {
    try {
      await _offerService.riderConfirmOffer(rideId, driverUid);
      final ride = await _rideService.getRide(rideId);
      await _chatService.sendSystemMessage(
        rideId: rideId,
        text: 'Rider selected $driverName. Waiting for driver confirmation.',
        threadDriverUid: driverUid,
      );
      if (ride != null) {
        await _notificationService.createNotification(
          recipientUid: driverUid,
          type: NotificationTypes.riderConfirmed,
          title: 'You Were Selected!',
          body: 'The rider chose you. Tap to confirm the ride.',
          rideId: rideId,
          senderUid: ride.riderUid,
        );
      }
    } catch (e) {
      _error = 'Failed to confirm driver';
      notifyListeners();
    }
  }

  /// Driver confirms back (step 2 — mutual confirmation)
  Future<bool> driverConfirmOffer(String rideId, AppUser driver) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (await _offerService.driverHasActiveRide(
        driver.uid,
        excludeRideId: rideId,
      )) {
        _error =
            'You already have an active ride. Complete it before accepting another.';
        return false;
      }

      final success =
          await _offerService.driverConfirmOffer(rideId, driver);
      if (success) {
        // Decline all other offers
        await _offerService.declineOtherOffers(rideId, driver.uid);

        final ride = await _rideService.getRide(rideId);
        if (ride != null) {
          // Notify rider
          await _notificationService.createNotification(
            recipientUid: ride.riderUid,
            type: NotificationTypes.rideMutuallyConfirmed,
            title: 'Ride Confirmed!',
            body:
                '${driver.fullName} confirmed. Your ride to ${ride.destination} is set!',
            rideId: rideId,
            senderUid: driver.uid,
          );
          await _chatService.sendSystemMessage(
            rideId: rideId,
            text: 'Ride confirmed! ${driver.fullName} is your driver.',
            threadDriverUid: driver.uid,
          );

          // Notify declined drivers
          _notifyDeclinedDrivers(rideId, ride, driver.uid);
        }
      }
      return success;
    } catch (e) {
      _error = 'Failed to confirm ride';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Notify all declined drivers that the ride was confirmed with someone else
  Future<void> _notifyDeclinedDrivers(
    String rideId,
    Ride ride,
    String senderUid,
  ) async {
    try {
      final declinedUids =
          await _offerService.getDeclinedDriverUids(rideId);
      for (final driverUid in declinedUids) {
        await _notificationService.createNotification(
          recipientUid: driverUid,
          type: NotificationTypes.offerDeclined,
          title: 'Offer Not Selected',
          body:
              'Another driver was selected for the ride to ${ride.destination}.',
          rideId: rideId,
          senderUid: senderUid,
        );
        await _chatService.sendSystemMessage(
          rideId: rideId,
          text: 'Another driver was selected for this ride.',
          threadDriverUid: driverUid,
        );
      }
    } catch (_) {
      // Best-effort notification
    }
  }

  // ─── Stream Accessors for Offers ──────────────────────────────────

  Stream<List<RideOffer>> offersStream(String rideId) =>
      _offerService.offersStream(rideId);

  Stream<RideOffer?> myOfferStream(String rideId, String driverUid) =>
      _offerService.offerStream(rideId, driverUid);

  // ─── Existing Ride Lifecycle ──────────────────────────────────────

  Future<void> startRide(String rideId, AppUser _) async {
    try {
      await _rideService.startRide(rideId);
    } catch (e) {
      _error = 'Failed to start ride';
      notifyListeners();
    }
  }

  Future<void> completeRide(String rideId, AppUser _) async {
    try {
      await _rideService.completeRide(rideId);
    } catch (e) {
      _error = 'Failed to complete ride';
      notifyListeners();
    }
  }

  Future<void> cancelRide(
    String rideId,
    AppUser currentUser,
    String? reason,
  ) async {
    try {
      // Get ride before cancelling for offer cleanup + notification
      final ride = await _rideService.getRide(rideId);

      await _rideService.cancelRide(rideId, currentUser.uid, reason);

      if (ride != null) {
        // Decline all active offers when ride is cancelled.
        await _offerService.declineOtherOffers(rideId, '');
      }
    } catch (e) {
      _error = 'Failed to cancel ride';
      notifyListeners();
    }
  }

  Future<void> logPoints({
    required String rideId,
    required int points,
    required bool isDriver,
  }) async {
    try {
      await _rideService.logPoints(
        rideId: rideId,
        points: points,
        isDriver: isDriver,
      );
    } catch (e) {
      _error = 'Failed to log points';
      notifyListeners();
    }
  }

  Future<void> updateRide(String rideId, Map<String, dynamic> data) async {
    try {
      await _rideService.updateRide(rideId, data);
    } catch (e) {
      _error = 'Failed to update ride';
      notifyListeners();
    }
  }

  Stream<Ride> rideStream(String rideId) => _rideService.rideStream(rideId);

  @override
  void dispose() {
    _openRidesSub?.cancel();
    _riderRidesSub?.cancel();
    _driverRidesSub?.cancel();
    super.dispose();
  }
}

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService;

  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  StreamSubscription? _notifSub;
  StreamSubscription? _countSub;

  NotificationProvider({
    NotificationService? notificationService,
  }) : _notificationService = notificationService ?? NotificationService();

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;

  void initStreams(String uid) {
    _notifSub?.cancel();
    _countSub?.cancel();

    _notifSub = _notificationService.notificationsStream(uid).listen(
      (notifs) {
        _notifications = notifs;
        notifyListeners();
      },
    );

    _countSub = _notificationService.unreadCountStream(uid).listen(
      (count) {
        _unreadCount = count;
        notifyListeners();
      },
    );
  }

  Future<void> markAsRead(String notifId) async {
    await _notificationService.markAsRead(notifId);
  }

  Future<void> markAllAsRead(String uid) async {
    await _notificationService.markAllAsRead(uid);
  }

  Future<void> markMessageNotificationsAsRead(
    String uid, {
    String? rideId,
  }) async {
    await _notificationService.markMessageNotificationsAsRead(
      uid,
      rideId: rideId,
    );
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    _countSub?.cancel();
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import 'app_colors.dart';

enum RideStatus {
  open,
  accepted,
  inProgress,
  completed,
  cancelled;

  String get label {
    switch (this) {
      case RideStatus.open:
        return 'OPEN';
      case RideStatus.accepted:
        return 'ACCEPTED';
      case RideStatus.inProgress:
        return 'IN_PROGRESS';
      case RideStatus.completed:
        return 'COMPLETED';
      case RideStatus.cancelled:
        return 'CANCELLED';
    }
  }

  String get displayLabel {
    switch (this) {
      case RideStatus.open:
        return 'Open';
      case RideStatus.accepted:
        return 'Accepted';
      case RideStatus.inProgress:
        return 'In Progress';
      case RideStatus.completed:
        return 'Completed';
      case RideStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get color {
    switch (this) {
      case RideStatus.open:
        return AppColors.info;
      case RideStatus.accepted:
        return AppColors.rowanGold;
      case RideStatus.inProgress:
        return AppColors.warning;
      case RideStatus.completed:
        return AppColors.success;
      case RideStatus.cancelled:
        return AppColors.error;
    }
  }

  IconData get icon {
    switch (this) {
      case RideStatus.open:
        return Icons.access_time_rounded;
      case RideStatus.accepted:
        return Icons.handshake_rounded;
      case RideStatus.inProgress:
        return Icons.directions_car_rounded;
      case RideStatus.completed:
        return Icons.check_circle_rounded;
      case RideStatus.cancelled:
        return Icons.cancel_rounded;
    }
  }

  List<RideStatus> get allowedTransitions {
    switch (this) {
      case RideStatus.open:
        return [RideStatus.accepted, RideStatus.cancelled];
      case RideStatus.accepted:
        return [RideStatus.inProgress, RideStatus.cancelled];
      case RideStatus.inProgress:
        return [RideStatus.completed, RideStatus.cancelled];
      case RideStatus.completed:
        return [];
      case RideStatus.cancelled:
        return [];
    }
  }

  static RideStatus fromString(String s) {
    switch (s) {
      case 'ACCEPTED':
        return RideStatus.accepted;
      case 'IN_PROGRESS':
        return RideStatus.inProgress;
      case 'COMPLETED':
        return RideStatus.completed;
      case 'CANCELLED':
        return RideStatus.cancelled;
      default:
        return RideStatus.open;
    }
  }
}

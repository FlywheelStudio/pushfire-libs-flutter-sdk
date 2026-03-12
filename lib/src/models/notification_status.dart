/// Represents the current notification status for a device.
///
/// Combines OS-level permission state with the PushFire preference
/// set by the developer via [setNotificationEnabled].
class NotificationStatus {
  /// Whether the OS-level notification permission is granted.
  final bool isPermissionGranted;

  /// Whether PushFire notifications are enabled (developer-controlled preference).
  /// This is only meaningful when [isPermissionGranted] is true.
  final bool isEnabled;

  const NotificationStatus({
    required this.isPermissionGranted,
    required this.isEnabled,
  });

  @override
  String toString() {
    return 'NotificationStatus(isPermissionGranted: $isPermissionGranted, isEnabled: $isEnabled)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationStatus &&
        other.isPermissionGranted == isPermissionGranted &&
        other.isEnabled == isEnabled;
  }

  @override
  int get hashCode => Object.hash(isPermissionGranted, isEnabled);
}

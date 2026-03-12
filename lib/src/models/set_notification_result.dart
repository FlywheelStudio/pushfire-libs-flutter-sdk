/// Result of calling [setNotificationEnabled].
enum SetNotificationResult {
  /// Notification preference was updated on the server successfully.
  success,

  /// Cannot enable notifications because OS-level permission is denied.
  /// The user needs to enable notifications in device settings first.
  systemPermissionDenied,
}

/// Represents a subscriber in the PushFire system
class Subscriber {
  /// Unique subscriber identifier
  final String? id;

  /// Device ID associated with this subscriber
  final String? deviceId;

  /// External ID from your system
  final String externalId;

  /// Subscriber name
  final String? name;

  /// Subscriber email
  final String? email;

  /// Subscriber phone number
  final String? phone;

  /// Additional metadata as key-value pairs
  final Map<String, dynamic>? metadata;

  const Subscriber({
    this.id,
    this.deviceId,
    required this.externalId,
    this.name,
    this.email,
    this.phone,
    this.metadata,
  });

  /// Create a Subscriber from JSON
  factory Subscriber.fromJson(Map<String, dynamic> json) {
    return Subscriber(
      id: json['id'] as String?,
      deviceId: json['deviceId'] as String?,
      externalId: json['externalId'] as String,
      name: json['name'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      metadata: json['metadata'] != null
          ? (json['metadata'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Convert Subscriber to JSON
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};

    if (id != null) json['id'] = id;
    if (deviceId != null) json['deviceId'] = deviceId;
    json['externalId'] = externalId;
    if (name != null) json['name'] = name;
    if (email != null) json['email'] = email;
    if (phone != null) json['phone'] = phone;
    if (metadata != null) json['metadata'] = metadata;

    return json;
  }

  /// Create a copy of this subscriber with updated values
  Subscriber copyWith({
    String? id,
    String? deviceId,
    String? externalId,
    String? name,
    String? email,
    String? phone,
    Map<String, dynamic>? metadata,
  }) {
    return Subscriber(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      externalId: externalId ?? this.externalId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'Subscriber(id: $id, externalId: $externalId, name: $name, email: $email, metadata: $metadata)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Subscriber &&
        other.id == id &&
        other.deviceId == deviceId &&
        other.externalId == externalId &&
        other.name == name &&
        other.email == email &&
        other.phone == phone &&
        _mapEquals(other.metadata, metadata);
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      deviceId,
      externalId,
      name,
      email,
      phone,
      metadata == null ? null : _deepHashCode(metadata!),
    );
  }

  static int _deepHashCode(dynamic value) {
    if (value is Map) {
      final entries = value.entries.toList()
        ..sort((a, b) => a.key.toString().compareTo(b.key.toString()));
      return Object.hashAll(
        entries.map((e) => Object.hash(e.key, _deepHashCode(e.value))),
      );
    }
    if (value is List) {
      return Object.hashAll(value.map(_deepHashCode));
    }
    return value.hashCode;
  }

  static bool _deepEquals(dynamic a, dynamic b) {
    if (a == b) return true;
    if (a is Map && b is Map) {
      if (a.length != b.length) return false;
      for (final key in a.keys) {
        if (!b.containsKey(key) || !_deepEquals(a[key], b[key])) return false;
      }
      return true;
    }
    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (var i = 0; i < a.length; i++) {
        if (!_deepEquals(a[i], b[i])) return false;
      }
      return true;
    }
    return false;
  }

  static bool _mapEquals(Map<String, dynamic>? a, Map<String, dynamic>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return _deepEquals(a, b);
  }
}

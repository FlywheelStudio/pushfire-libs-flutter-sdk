import 'package:flutter_test/flutter_test.dart';
import 'package:pushfire_sdk/pushfire_sdk.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Shared fixtures
  // ---------------------------------------------------------------------------

  final fullSubscriber = Subscriber(
    id: 'sub-001',
    deviceId: 'device-abc',
    externalId: 'ext-123',
    name: 'Jane Doe',
    email: 'jane@example.com',
    phone: '+1234567890',
    metadata: {'plan': 'premium', 'age': 30},
  );

  final minimalSubscriber = Subscriber(externalId: 'ext-minimal');

  final nestedMetadataSubscriber = Subscriber(
    externalId: 'ext-nested',
    metadata: {
      'address': {
        'street': '123 Main St',
        'city': 'Springfield',
        'zip': '62704',
      },
      'tags': ['vip', 'early-adopter'],
      'preferences': {
        'notifications': {'email': true, 'sms': false},
        'theme': 'dark',
      },
    },
  );

  // ---------------------------------------------------------------------------
  // Construction
  // ---------------------------------------------------------------------------

  group('Construction', () {
    test('creates subscriber with all fields', () {
      expect(fullSubscriber.id, 'sub-001');
      expect(fullSubscriber.deviceId, 'device-abc');
      expect(fullSubscriber.externalId, 'ext-123');
      expect(fullSubscriber.name, 'Jane Doe');
      expect(fullSubscriber.email, 'jane@example.com');
      expect(fullSubscriber.phone, '+1234567890');
      expect(fullSubscriber.metadata, {'plan': 'premium', 'age': 30});
    });

    test('creates subscriber with only required field (externalId)', () {
      expect(minimalSubscriber.id, isNull);
      expect(minimalSubscriber.deviceId, isNull);
      expect(minimalSubscriber.externalId, 'ext-minimal');
      expect(minimalSubscriber.name, isNull);
      expect(minimalSubscriber.email, isNull);
      expect(minimalSubscriber.phone, isNull);
      expect(minimalSubscriber.metadata, isNull);
    });

    test('creates subscriber with flat metadata', () {
      final subscriber = Subscriber(
        externalId: 'ext-flat',
        metadata: {'key1': 'value1', 'key2': 42, 'key3': true},
      );

      expect(subscriber.metadata, isNotNull);
      expect(subscriber.metadata!['key1'], 'value1');
      expect(subscriber.metadata!['key2'], 42);
      expect(subscriber.metadata!['key3'], true);
    });

    test('creates subscriber with nested maps and lists in metadata', () {
      expect(nestedMetadataSubscriber.metadata, isNotNull);
      expect(nestedMetadataSubscriber.metadata!['address'], isA<Map>());
      expect(nestedMetadataSubscriber.metadata!['tags'], isA<List>());
      expect(
        (nestedMetadataSubscriber.metadata!['address']
            as Map<String, dynamic>)['city'],
        'Springfield',
      );
      expect(
        (nestedMetadataSubscriber.metadata!['preferences']
                as Map<String, dynamic>)['notifications']
            as Map<String, dynamic>,
        {'email': true, 'sms': false},
      );
    });
  });

  // ---------------------------------------------------------------------------
  // fromJson
  // ---------------------------------------------------------------------------

  group('fromJson', () {
    test('parses complete JSON with all fields', () {
      final json = {
        'id': 'sub-001',
        'deviceId': 'device-abc',
        'externalId': 'ext-123',
        'name': 'Jane Doe',
        'email': 'jane@example.com',
        'phone': '+1234567890',
        'metadata': {'plan': 'premium', 'age': 30},
      };

      final subscriber = Subscriber.fromJson(json);

      expect(subscriber.id, 'sub-001');
      expect(subscriber.deviceId, 'device-abc');
      expect(subscriber.externalId, 'ext-123');
      expect(subscriber.name, 'Jane Doe');
      expect(subscriber.email, 'jane@example.com');
      expect(subscriber.phone, '+1234567890');
      expect(subscriber.metadata, {'plan': 'premium', 'age': 30});
    });

    test('parses minimal JSON with only externalId', () {
      final json = <String, dynamic>{'externalId': 'ext-only'};

      final subscriber = Subscriber.fromJson(json);

      expect(subscriber.externalId, 'ext-only');
      expect(subscriber.id, isNull);
      expect(subscriber.deviceId, isNull);
      expect(subscriber.name, isNull);
      expect(subscriber.email, isNull);
      expect(subscriber.phone, isNull);
      expect(subscriber.metadata, isNull);
    });

    test('parses JSON with flat metadata', () {
      final json = <String, dynamic>{
        'externalId': 'ext-meta',
        'metadata': {'role': 'admin', 'level': 5},
      };

      final subscriber = Subscriber.fromJson(json);

      expect(subscriber.metadata, isNotNull);
      expect(subscriber.metadata!['role'], 'admin');
      expect(subscriber.metadata!['level'], 5);
    });

    test('parses JSON with nested metadata (maps within maps, lists)', () {
      final json = <String, dynamic>{
        'externalId': 'ext-deep',
        'metadata': {
          'profile': {
            'bio': 'Hello world',
            'links': ['https://a.com', 'https://b.com'],
          },
          'scores': [100, 200, 300],
        },
      };

      final subscriber = Subscriber.fromJson(json);

      expect(subscriber.metadata, isNotNull);
      final profile =
          subscriber.metadata!['profile'] as Map<String, dynamic>;
      expect(profile['bio'], 'Hello world');
      expect(profile['links'], ['https://a.com', 'https://b.com']);
      expect(subscriber.metadata!['scores'], [100, 200, 300]);
    });

    test('parses JSON with null metadata field', () {
      final json = <String, dynamic>{
        'externalId': 'ext-null-meta',
        'metadata': null,
      };

      final subscriber = Subscriber.fromJson(json);

      expect(subscriber.metadata, isNull);
    });

    test('parses JSON where externalId is present', () {
      final json = <String, dynamic>{
        'externalId': 'ext-present',
        'name': 'Test User',
      };

      final subscriber = Subscriber.fromJson(json);

      expect(subscriber.externalId, 'ext-present');
      expect(subscriber.name, 'Test User');
    });
  });

  // ---------------------------------------------------------------------------
  // toJson
  // ---------------------------------------------------------------------------

  group('toJson', () {
    test('serializes with all fields - verify all present', () {
      final json = fullSubscriber.toJson();

      expect(json['id'], 'sub-001');
      expect(json['deviceId'], 'device-abc');
      expect(json['externalId'], 'ext-123');
      expect(json['name'], 'Jane Doe');
      expect(json['email'], 'jane@example.com');
      expect(json['phone'], '+1234567890');
      expect(json['metadata'], {'plan': 'premium', 'age': 30});
      expect(json.length, 7);
    });

    test('serializes with only required fields - null fields omitted', () {
      final json = minimalSubscriber.toJson();

      expect(json['externalId'], 'ext-minimal');
      expect(json.containsKey('id'), isFalse);
      expect(json.containsKey('deviceId'), isFalse);
      expect(json.containsKey('name'), isFalse);
      expect(json.containsKey('email'), isFalse);
      expect(json.containsKey('phone'), isFalse);
      expect(json.containsKey('metadata'), isFalse);
      expect(json.length, 1);
    });

    test('serializes with metadata - verify metadata included', () {
      final subscriber = Subscriber(
        externalId: 'ext-with-meta',
        metadata: {'color': 'blue', 'count': 7},
      );

      final json = subscriber.toJson();

      expect(json.containsKey('metadata'), isTrue);
      expect(json['metadata'], {'color': 'blue', 'count': 7});
    });

    test('round-trip: fromJson(toJson(subscriber)) equals original', () {
      final json = fullSubscriber.toJson();
      final restored = Subscriber.fromJson(json);

      expect(restored, equals(fullSubscriber));
      expect(restored.id, fullSubscriber.id);
      expect(restored.deviceId, fullSubscriber.deviceId);
      expect(restored.externalId, fullSubscriber.externalId);
      expect(restored.name, fullSubscriber.name);
      expect(restored.email, fullSubscriber.email);
      expect(restored.phone, fullSubscriber.phone);
      expect(restored.metadata, fullSubscriber.metadata);
    });

    test('round-trip with nested metadata', () {
      final json = nestedMetadataSubscriber.toJson();
      final restored = Subscriber.fromJson(json);

      expect(restored, equals(nestedMetadataSubscriber));
    });

    test('round-trip with minimal subscriber', () {
      final json = minimalSubscriber.toJson();
      final restored = Subscriber.fromJson(json);

      expect(restored, equals(minimalSubscriber));
    });
  });

  // ---------------------------------------------------------------------------
  // copyWith
  // ---------------------------------------------------------------------------

  group('copyWith', () {
    test('copy with no changes produces equal subscriber', () {
      final copy = fullSubscriber.copyWith();

      expect(copy, equals(fullSubscriber));
      expect(copy.id, fullSubscriber.id);
      expect(copy.deviceId, fullSubscriber.deviceId);
      expect(copy.externalId, fullSubscriber.externalId);
      expect(copy.name, fullSubscriber.name);
      expect(copy.email, fullSubscriber.email);
      expect(copy.phone, fullSubscriber.phone);
      expect(copy.metadata, fullSubscriber.metadata);
    });

    test('copy with single field changed', () {
      final copy = fullSubscriber.copyWith(name: 'John Smith');

      expect(copy.name, 'John Smith');
      // All other fields remain the same
      expect(copy.id, fullSubscriber.id);
      expect(copy.deviceId, fullSubscriber.deviceId);
      expect(copy.externalId, fullSubscriber.externalId);
      expect(copy.email, fullSubscriber.email);
      expect(copy.phone, fullSubscriber.phone);
      expect(copy.metadata, fullSubscriber.metadata);
    });

    test('copy with metadata changed', () {
      final newMeta = {'tier': 'gold', 'active': true};
      final copy = fullSubscriber.copyWith(metadata: newMeta);

      expect(copy.metadata, newMeta);
      expect(copy.externalId, fullSubscriber.externalId);
      expect(copy.name, fullSubscriber.name);
    });

    test('copy preserves unchanged fields when multiple fields updated', () {
      final copy = fullSubscriber.copyWith(
        email: 'new@example.com',
        phone: '+9876543210',
      );

      expect(copy.email, 'new@example.com');
      expect(copy.phone, '+9876543210');
      expect(copy.id, fullSubscriber.id);
      expect(copy.deviceId, fullSubscriber.deviceId);
      expect(copy.externalId, fullSubscriber.externalId);
      expect(copy.name, fullSubscriber.name);
      expect(copy.metadata, fullSubscriber.metadata);
    });

    test('copy with externalId changed', () {
      final copy = fullSubscriber.copyWith(externalId: 'ext-new');

      expect(copy.externalId, 'ext-new');
      expect(copy.id, fullSubscriber.id);
    });
  });

  // ---------------------------------------------------------------------------
  // Equality (operator ==)
  // ---------------------------------------------------------------------------

  group('Equality', () {
    test('same data produces equal subscribers', () {
      final a = Subscriber(
        id: 'sub-001',
        deviceId: 'device-abc',
        externalId: 'ext-123',
        name: 'Jane Doe',
        email: 'jane@example.com',
        phone: '+1234567890',
        metadata: {'plan': 'premium', 'age': 30},
      );
      final b = Subscriber(
        id: 'sub-001',
        deviceId: 'device-abc',
        externalId: 'ext-123',
        name: 'Jane Doe',
        email: 'jane@example.com',
        phone: '+1234567890',
        metadata: {'plan': 'premium', 'age': 30},
      );

      expect(a, equals(b));
      expect(a == b, isTrue);
    });

    test('different externalId produces unequal subscribers', () {
      final a = Subscriber(externalId: 'ext-aaa');
      final b = Subscriber(externalId: 'ext-bbb');

      expect(a == b, isFalse);
    });

    test('different metadata produces unequal subscribers', () {
      final a = Subscriber(
        externalId: 'ext-same',
        metadata: {'key': 'value1'},
      );
      final b = Subscriber(
        externalId: 'ext-same',
        metadata: {'key': 'value2'},
      );

      expect(a == b, isFalse);
    });

    test('same metadata different insertion order produces equal subscribers',
        () {
      final a = Subscriber(
        externalId: 'ext-same',
        metadata: {'alpha': 1, 'beta': 2, 'gamma': 3},
      );
      // Construct map with reversed insertion order
      final reversedMap = <String, dynamic>{};
      reversedMap['gamma'] = 3;
      reversedMap['beta'] = 2;
      reversedMap['alpha'] = 1;

      final b = Subscriber(
        externalId: 'ext-same',
        metadata: reversedMap,
      );

      expect(a, equals(b));
    });

    test('nested metadata equality (deep comparison)', () {
      final a = Subscriber(
        externalId: 'ext-deep',
        metadata: {
          'nested': {'inner': 'value', 'list': [1, 2, 3]},
          'top': 'level',
        },
      );
      final b = Subscriber(
        externalId: 'ext-deep',
        metadata: {
          'nested': {'inner': 'value', 'list': [1, 2, 3]},
          'top': 'level',
        },
      );

      expect(a, equals(b));
    });

    test('nested metadata with different nested values are not equal', () {
      final a = Subscriber(
        externalId: 'ext-deep',
        metadata: {
          'nested': {'inner': 'value1'},
        },
      );
      final b = Subscriber(
        externalId: 'ext-deep',
        metadata: {
          'nested': {'inner': 'value2'},
        },
      );

      expect(a == b, isFalse);
    });

    test('null metadata on both produces equal subscribers', () {
      final a = Subscriber(externalId: 'ext-null');
      final b = Subscriber(externalId: 'ext-null');

      expect(a, equals(b));
    });

    test('null metadata on one side produces unequal subscribers', () {
      final a = Subscriber(
        externalId: 'ext-null-one',
        metadata: {'key': 'value'},
      );
      final b = Subscriber(externalId: 'ext-null-one');

      expect(a == b, isFalse);
    });

    test('not equal to non-Subscriber object', () {
      final subscriber = Subscriber(externalId: 'ext-type');

      // ignore: unrelated_type_equality_checks
      expect(subscriber == 'not a subscriber', isFalse);
      // ignore: unrelated_type_equality_checks
      expect(subscriber == 42, isFalse);
      // ignore: unrelated_type_equality_checks
      expect(subscriber == null, isFalse);
    });

    test('identical reference produces equality', () {
      final subscriber = Subscriber(externalId: 'ext-id');

      expect(identical(subscriber, subscriber), isTrue);
      expect(subscriber == subscriber, isTrue);
    });

    test('different id but same other fields are not equal', () {
      final a = Subscriber(id: 'id-1', externalId: 'ext-same');
      final b = Subscriber(id: 'id-2', externalId: 'ext-same');

      expect(a == b, isFalse);
    });

    test('different deviceId but same other fields are not equal', () {
      final a = Subscriber(deviceId: 'dev-1', externalId: 'ext-same');
      final b = Subscriber(deviceId: 'dev-2', externalId: 'ext-same');

      expect(a == b, isFalse);
    });

    test('different email but same other fields are not equal', () {
      final a = Subscriber(externalId: 'ext-same', email: 'a@b.com');
      final b = Subscriber(externalId: 'ext-same', email: 'x@y.com');

      expect(a == b, isFalse);
    });

    test('different phone but same other fields are not equal', () {
      final a = Subscriber(externalId: 'ext-same', phone: '111');
      final b = Subscriber(externalId: 'ext-same', phone: '222');

      expect(a == b, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // hashCode
  // ---------------------------------------------------------------------------

  group('hashCode', () {
    test('equal subscribers have the same hashCode', () {
      final a = Subscriber(
        id: 'sub-001',
        externalId: 'ext-123',
        name: 'Jane',
        metadata: {'plan': 'premium'},
      );
      final b = Subscriber(
        id: 'sub-001',
        externalId: 'ext-123',
        name: 'Jane',
        metadata: {'plan': 'premium'},
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test(
        'metadata with different insertion order produces same hashCode', () {
      final metaA = <String, dynamic>{'x': 1, 'y': 2, 'z': 3};

      final metaB = <String, dynamic>{};
      metaB['z'] = 3;
      metaB['x'] = 1;
      metaB['y'] = 2;

      final a = Subscriber(externalId: 'ext-hash', metadata: metaA);
      final b = Subscriber(externalId: 'ext-hash', metadata: metaB);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test(
        'nested metadata with different insertion order produces same hashCode',
        () {
      final metaA = <String, dynamic>{
        'outer': <String, dynamic>{'a': 1, 'b': 2},
      };
      final innerB = <String, dynamic>{};
      innerB['b'] = 2;
      innerB['a'] = 1;
      final metaB = <String, dynamic>{'outer': innerB};

      final a = Subscriber(externalId: 'ext-deep-hash', metadata: metaA);
      final b = Subscriber(externalId: 'ext-deep-hash', metadata: metaB);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different subscribers likely have different hashCode', () {
      final a = Subscriber(externalId: 'ext-aaa', name: 'Alice');
      final b = Subscriber(externalId: 'ext-bbb', name: 'Bob');

      // Not guaranteed but overwhelmingly likely for distinct data
      expect(a.hashCode, isNot(equals(b.hashCode)));
    });

    test('subscribers differing only in metadata have different hashCode', () {
      final a = Subscriber(
        externalId: 'ext-same',
        metadata: {'key': 'val1'},
      );
      final b = Subscriber(
        externalId: 'ext-same',
        metadata: {'key': 'val2'},
      );

      expect(a.hashCode, isNot(equals(b.hashCode)));
    });

    test('subscriber with null metadata vs non-null metadata differ', () {
      final a = Subscriber(externalId: 'ext-same');
      final b = Subscriber(
        externalId: 'ext-same',
        metadata: {'key': 'value'},
      );

      expect(a.hashCode, isNot(equals(b.hashCode)));
    });
  });

  // ---------------------------------------------------------------------------
  // toString
  // ---------------------------------------------------------------------------

  group('toString', () {
    test('contains key fields in output', () {
      final str = fullSubscriber.toString();

      expect(str, contains('Subscriber'));
      expect(str, contains('sub-001'));
      expect(str, contains('ext-123'));
      expect(str, contains('Jane Doe'));
      expect(str, contains('jane@example.com'));
    });

    test('contains id field label', () {
      final str = fullSubscriber.toString();

      expect(str, contains('id:'));
      expect(str, contains('externalId:'));
      expect(str, contains('name:'));
      expect(str, contains('email:'));
    });

    test('contains metadata in output', () {
      final str = fullSubscriber.toString();

      expect(str, contains('metadata:'));
      expect(str, contains('premium'));
    });

    test('handles null fields gracefully', () {
      final str = minimalSubscriber.toString();

      expect(str, contains('Subscriber'));
      expect(str, contains('ext-minimal'));
      expect(str, contains('null'));
    });

    test('returns a non-empty string', () {
      expect(fullSubscriber.toString(), isNotEmpty);
      expect(minimalSubscriber.toString(), isNotEmpty);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:pushfire_sdk/pushfire_sdk.dart';

void main() {
  group('SubscriberTag', () {
    // Shared test data
    const tagId = 'tag-001';
    const subscriberId = 'sub-abc-123';
    const value = 'premium';

    const tag = SubscriberTag(
      tagId: tagId,
      subscriberId: subscriberId,
      value: value,
    );

    // ------------------------------------------------------------------
    // Construction
    // ------------------------------------------------------------------
    group('constructor', () {
      test('creates instance with all required fields', () {
        expect(tag.tagId, tagId);
        expect(tag.subscriberId, subscriberId);
        expect(tag.value, value);
      });

      test('can be declared as const', () {
        const a = SubscriberTag(
          tagId: 'id',
          subscriberId: 'sub',
          value: 'v',
        );
        const b = SubscriberTag(
          tagId: 'id',
          subscriberId: 'sub',
          value: 'v',
        );
        // Const instances with the same arguments are identical.
        expect(identical(a, b), isTrue);
      });
    });

    // ------------------------------------------------------------------
    // fromJson
    // ------------------------------------------------------------------
    group('fromJson', () {
      test('creates instance from a valid JSON map', () {
        final json = <String, dynamic>{
          'tagId': tagId,
          'subscriberId': subscriberId,
          'value': value,
        };

        final result = SubscriberTag.fromJson(json);

        expect(result.tagId, tagId);
        expect(result.subscriberId, subscriberId);
        expect(result.value, value);
      });

      test('creates correct instance when JSON has extra keys', () {
        final json = <String, dynamic>{
          'tagId': tagId,
          'subscriberId': subscriberId,
          'value': value,
          'extraKey': 'should be ignored',
          'anotherExtra': 42,
        };

        final result = SubscriberTag.fromJson(json);

        expect(result.tagId, tagId);
        expect(result.subscriberId, subscriberId);
        expect(result.value, value);
      });

      test('throws when tagId is missing', () {
        final json = <String, dynamic>{
          'subscriberId': subscriberId,
          'value': value,
        };

        expect(() => SubscriberTag.fromJson(json), throwsA(isA<TypeError>()));
      });

      test('throws when subscriberId is missing', () {
        final json = <String, dynamic>{
          'tagId': tagId,
          'value': value,
        };

        expect(() => SubscriberTag.fromJson(json), throwsA(isA<TypeError>()));
      });

      test('throws when value is missing', () {
        final json = <String, dynamic>{
          'tagId': tagId,
          'subscriberId': subscriberId,
        };

        expect(() => SubscriberTag.fromJson(json), throwsA(isA<TypeError>()));
      });

      test('throws when a field has the wrong type', () {
        final json = <String, dynamic>{
          'tagId': 123,
          'subscriberId': subscriberId,
          'value': value,
        };

        expect(() => SubscriberTag.fromJson(json), throwsA(isA<TypeError>()));
      });
    });

    // ------------------------------------------------------------------
    // toJson
    // ------------------------------------------------------------------
    group('toJson', () {
      test('returns a map containing all fields', () {
        final json = tag.toJson();

        expect(json, isA<Map<String, dynamic>>());
        expect(json['tagId'], tagId);
        expect(json['subscriberId'], subscriberId);
        expect(json['value'], value);
      });

      test('returns a map with exactly three keys', () {
        final json = tag.toJson();

        expect(json.length, 3);
        expect(json.containsKey('tagId'), isTrue);
        expect(json.containsKey('subscriberId'), isTrue);
        expect(json.containsKey('value'), isTrue);
      });

      test('values are all Strings', () {
        final json = tag.toJson();

        expect(json['tagId'], isA<String>());
        expect(json['subscriberId'], isA<String>());
        expect(json['value'], isA<String>());
      });
    });

    // ------------------------------------------------------------------
    // Round-trip: fromJson -> toJson and toJson -> fromJson
    // ------------------------------------------------------------------
    group('round-trip serialization', () {
      test('toJson then fromJson yields an equal object', () {
        final json = tag.toJson();
        final restored = SubscriberTag.fromJson(json);

        expect(restored, tag);
      });

      test('fromJson then toJson yields the original map', () {
        final originalJson = <String, dynamic>{
          'tagId': 'round-trip-tag',
          'subscriberId': 'round-trip-sub',
          'value': 'round-trip-val',
        };

        final result = SubscriberTag.fromJson(originalJson).toJson();

        expect(result, originalJson);
      });

      test('multiple round-trips produce consistent results', () {
        final first = SubscriberTag.fromJson(tag.toJson());
        final second = SubscriberTag.fromJson(first.toJson());
        final third = SubscriberTag.fromJson(second.toJson());

        expect(first, tag);
        expect(second, tag);
        expect(third, tag);
        expect(third.toJson(), tag.toJson());
      });
    });

    // ------------------------------------------------------------------
    // copyWith
    // ------------------------------------------------------------------
    group('copyWith', () {
      test('returns an identical copy when called with no arguments', () {
        final copy = tag.copyWith();

        expect(copy, tag);
        expect(copy.tagId, tag.tagId);
        expect(copy.subscriberId, tag.subscriberId);
        expect(copy.value, tag.value);
      });

      test('updates only tagId', () {
        const newTagId = 'tag-999';
        final copy = tag.copyWith(tagId: newTagId);

        expect(copy.tagId, newTagId);
        expect(copy.subscriberId, tag.subscriberId);
        expect(copy.value, tag.value);
      });

      test('updates only subscriberId', () {
        const newSubscriberId = 'sub-xyz-789';
        final copy = tag.copyWith(subscriberId: newSubscriberId);

        expect(copy.tagId, tag.tagId);
        expect(copy.subscriberId, newSubscriberId);
        expect(copy.value, tag.value);
      });

      test('updates only value', () {
        const newValue = 'free-tier';
        final copy = tag.copyWith(value: newValue);

        expect(copy.tagId, tag.tagId);
        expect(copy.subscriberId, tag.subscriberId);
        expect(copy.value, newValue);
      });

      test('updates all fields at once', () {
        const newTagId = 'tag-new';
        const newSubscriberId = 'sub-new';
        const newValue = 'enterprise';

        final copy = tag.copyWith(
          tagId: newTagId,
          subscriberId: newSubscriberId,
          value: newValue,
        );

        expect(copy.tagId, newTagId);
        expect(copy.subscriberId, newSubscriberId);
        expect(copy.value, newValue);
      });

      test('returns a new instance, not the same reference', () {
        final copy = tag.copyWith();

        // Equal but not identical (since tag is const, the copy is a new object).
        expect(copy, tag);
        expect(identical(copy, tag), isFalse);
      });

      test('updated copy is not equal to the original', () {
        final copy = tag.copyWith(value: 'different');

        expect(copy, isNot(tag));
      });
    });

    // ------------------------------------------------------------------
    // Equality (operator ==)
    // ------------------------------------------------------------------
    group('equality', () {
      test('two instances with the same field values are equal', () {
        final a = SubscriberTag(
          tagId: tagId,
          subscriberId: subscriberId,
          value: value,
        );
        final b = SubscriberTag(
          tagId: tagId,
          subscriberId: subscriberId,
          value: value,
        );

        expect(a, b);
        expect(a == b, isTrue);
      });

      test('instances differing in tagId are not equal', () {
        final other = tag.copyWith(tagId: 'different-tag');
        expect(tag, isNot(other));
      });

      test('instances differing in subscriberId are not equal', () {
        final other = tag.copyWith(subscriberId: 'different-sub');
        expect(tag, isNot(other));
      });

      test('instances differing in value are not equal', () {
        final other = tag.copyWith(value: 'different-value');
        expect(tag, isNot(other));
      });

      test('is not equal to null', () {
        // ignore: unrelated_type_equality_checks
        expect(tag == null, isFalse);
      });

      test('is not equal to an object of a different type', () {
        expect(tag == Object(), isFalse);
      });

      test('identical instance is equal to itself', () {
        expect(tag == tag, isTrue);
      });

      test('equality is symmetric', () {
        final a = SubscriberTag(
          tagId: tagId,
          subscriberId: subscriberId,
          value: value,
        );
        final b = SubscriberTag(
          tagId: tagId,
          subscriberId: subscriberId,
          value: value,
        );

        expect(a == b, isTrue);
        expect(b == a, isTrue);
      });

      test('equality is transitive', () {
        final a = SubscriberTag(
          tagId: tagId,
          subscriberId: subscriberId,
          value: value,
        );
        final b = SubscriberTag(
          tagId: tagId,
          subscriberId: subscriberId,
          value: value,
        );
        final c = SubscriberTag(
          tagId: tagId,
          subscriberId: subscriberId,
          value: value,
        );

        expect(a == b, isTrue);
        expect(b == c, isTrue);
        expect(a == c, isTrue);
      });
    });

    // ------------------------------------------------------------------
    // hashCode
    // ------------------------------------------------------------------
    group('hashCode', () {
      test('equal objects have the same hashCode', () {
        final a = SubscriberTag(
          tagId: tagId,
          subscriberId: subscriberId,
          value: value,
        );
        final b = SubscriberTag(
          tagId: tagId,
          subscriberId: subscriberId,
          value: value,
        );

        expect(a.hashCode, b.hashCode);
      });

      test('hashCode is consistent across multiple calls', () {
        final hash1 = tag.hashCode;
        final hash2 = tag.hashCode;
        final hash3 = tag.hashCode;

        expect(hash1, hash2);
        expect(hash2, hash3);
      });

      test('different objects are likely to have different hashCodes', () {
        final other = SubscriberTag(
          tagId: 'other-tag',
          subscriberId: 'other-sub',
          value: 'other-value',
        );

        // While hash collisions are theoretically possible, they should be
        // extremely unlikely for clearly different input values.
        expect(tag.hashCode, isNot(other.hashCode));
      });

      test('can be used as a Set element', () {
        final a = SubscriberTag(
          tagId: tagId,
          subscriberId: subscriberId,
          value: value,
        );
        final b = SubscriberTag(
          tagId: tagId,
          subscriberId: subscriberId,
          value: value,
        );
        final c = SubscriberTag(
          tagId: 'different',
          subscriberId: subscriberId,
          value: value,
        );

        final set = {a, b, c};
        // a and b are equal, so the set should contain only 2 elements.
        expect(set.length, 2);
      });

      test('can be used as a Map key', () {
        final a = SubscriberTag(
          tagId: tagId,
          subscriberId: subscriberId,
          value: value,
        );
        final b = SubscriberTag(
          tagId: tagId,
          subscriberId: subscriberId,
          value: value,
        );

        final map = <SubscriberTag, String>{a: 'first'};
        // Because a == b and a.hashCode == b.hashCode, b should find the entry.
        expect(map[b], 'first');
      });
    });

    // ------------------------------------------------------------------
    // toString
    // ------------------------------------------------------------------
    group('toString', () {
      test('contains the class name', () {
        expect(tag.toString(), contains('SubscriberTag'));
      });

      test('contains all field values', () {
        final str = tag.toString();

        expect(str, contains(tagId));
        expect(str, contains(subscriberId));
        expect(str, contains(value));
      });

      test('matches the expected format exactly', () {
        expect(
          tag.toString(),
          'SubscriberTag(tagId: $tagId, subscriberId: $subscriberId, value: $value)',
        );
      });

      test('reflects updated values via copyWith', () {
        final updated = tag.copyWith(value: 'enterprise');
        expect(
          updated.toString(),
          'SubscriberTag(tagId: $tagId, subscriberId: $subscriberId, value: enterprise)',
        );
      });

      test('handles values with special characters', () {
        final special = SubscriberTag(
          tagId: 'tag with spaces',
          subscriberId: 'sub/with/slashes',
          value: 'value=with&symbols',
        );
        final str = special.toString();

        expect(str, contains('tag with spaces'));
        expect(str, contains('sub/with/slashes'));
        expect(str, contains('value=with&symbols'));
      });

      test('handles empty string field values', () {
        const emptyTag = SubscriberTag(
          tagId: '',
          subscriberId: '',
          value: '',
        );

        expect(
          emptyTag.toString(),
          'SubscriberTag(tagId: , subscriberId: , value: )',
        );
      });
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:pushfire_sdk/pushfire_sdk.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Shared constants
  // ---------------------------------------------------------------------------

  const validUuid1 = '550e8400-e29b-41d4-a716-446655440000';
  const validUuid2 = 'f47ac10b-58cc-4372-a567-0e02b2c3d479';
  const validUuid3 = '6ba7b810-9dad-11d1-80b4-00c04fd430c8';

  // =========================================================================
  // WorkflowExecutionType
  // =========================================================================
  group('WorkflowExecutionType', () {
    test('immediate has correct string value', () {
      expect(WorkflowExecutionType.immediate.value, 'Immediate');
    });

    test('scheduled has correct string value', () {
      expect(WorkflowExecutionType.scheduled.value, 'Scheduled');
    });

    group('fromString', () {
      test('returns immediate for "Immediate"', () {
        expect(
          WorkflowExecutionType.fromString('Immediate'),
          WorkflowExecutionType.immediate,
        );
      });

      test('returns scheduled for "Scheduled"', () {
        expect(
          WorkflowExecutionType.fromString('Scheduled'),
          WorkflowExecutionType.scheduled,
        );
      });

      test('throws ArgumentError for empty string', () {
        expect(
          () => WorkflowExecutionType.fromString(''),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws ArgumentError for lowercase "immediate"', () {
        expect(
          () => WorkflowExecutionType.fromString('immediate'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws ArgumentError for lowercase "scheduled"', () {
        expect(
          () => WorkflowExecutionType.fromString('scheduled'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws ArgumentError for unrecognized value', () {
        expect(
          () => WorkflowExecutionType.fromString('unknown'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('error message contains the invalid value', () {
        expect(
          () => WorkflowExecutionType.fromString('bad_value'),
          throwsA(
            predicate<ArgumentError>(
              (e) => e.message == 'Invalid WorkflowExecutionType: bad_value',
            ),
          ),
        );
      });
    });
  });

  // =========================================================================
  // WorkflowTargetType
  // =========================================================================
  group('WorkflowTargetType', () {
    test('subscribers has correct string value', () {
      expect(WorkflowTargetType.subscribers.value, 'Subscribers');
    });

    test('segments has correct string value', () {
      expect(WorkflowTargetType.segments.value, 'Segments');
    });

    group('fromString', () {
      test('returns subscribers for "Subscribers"', () {
        expect(
          WorkflowTargetType.fromString('Subscribers'),
          WorkflowTargetType.subscribers,
        );
      });

      test('returns segments for "Segments"', () {
        expect(
          WorkflowTargetType.fromString('Segments'),
          WorkflowTargetType.segments,
        );
      });

      test('throws ArgumentError for empty string', () {
        expect(
          () => WorkflowTargetType.fromString(''),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws ArgumentError for lowercase "subscribers"', () {
        expect(
          () => WorkflowTargetType.fromString('subscribers'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws ArgumentError for lowercase "segments"', () {
        expect(
          () => WorkflowTargetType.fromString('segments'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws ArgumentError for unrecognized value', () {
        expect(
          () => WorkflowTargetType.fromString('topics'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('error message contains the invalid value', () {
        expect(
          () => WorkflowTargetType.fromString('wrong'),
          throwsA(
            predicate<ArgumentError>(
              (e) => e.message == 'Invalid WorkflowTargetType: wrong',
            ),
          ),
        );
      });
    });
  });

  // =========================================================================
  // WorkflowTarget
  // =========================================================================
  group('WorkflowTarget', () {
    group('construction', () {
      test('creates instance with subscribers type', () {
        final target = WorkflowTarget(
          type: WorkflowTargetType.subscribers,
          values: [validUuid1],
        );

        expect(target.type, WorkflowTargetType.subscribers);
        expect(target.values, [validUuid1]);
      });

      test('creates instance with segments type', () {
        final target = WorkflowTarget(
          type: WorkflowTargetType.segments,
          values: [validUuid1, validUuid2],
        );

        expect(target.type, WorkflowTargetType.segments);
        expect(target.values, hasLength(2));
      });

      test('creates instance with empty values list', () {
        final target = WorkflowTarget(
          type: WorkflowTargetType.subscribers,
          values: [],
        );

        expect(target.values, isEmpty);
      });
    });

    group('fromJson', () {
      test('parses subscribers target from JSON', () {
        final json = {
          'type': 'Subscribers',
          'values': [validUuid1, validUuid2],
        };

        final target = WorkflowTarget.fromJson(json);

        expect(target.type, WorkflowTargetType.subscribers);
        expect(target.values, [validUuid1, validUuid2]);
      });

      test('parses segments target from JSON', () {
        final json = {
          'type': 'Segments',
          'values': [validUuid3],
        };

        final target = WorkflowTarget.fromJson(json);

        expect(target.type, WorkflowTargetType.segments);
        expect(target.values, [validUuid3]);
      });

      test('parses empty values list from JSON', () {
        final json = {
          'type': 'Subscribers',
          'values': <dynamic>[],
        };

        final target = WorkflowTarget.fromJson(json);

        expect(target.values, isEmpty);
      });

      test('throws when type is invalid', () {
        final json = {
          'type': 'InvalidType',
          'values': [validUuid1],
        };

        expect(
          () => WorkflowTarget.fromJson(json),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('toJson', () {
      test('serializes subscribers target correctly', () {
        final target = WorkflowTarget(
          type: WorkflowTargetType.subscribers,
          values: [validUuid1],
        );

        final json = target.toJson();

        expect(json['type'], 'Subscribers');
        expect(json['values'], [validUuid1]);
      });

      test('serializes segments target correctly', () {
        final target = WorkflowTarget(
          type: WorkflowTargetType.segments,
          values: [validUuid1, validUuid2],
        );

        final json = target.toJson();

        expect(json['type'], 'Segments');
        expect(json['values'], [validUuid1, validUuid2]);
      });

      test('round-trip fromJson/toJson preserves data', () {
        final originalJson = {
          'type': 'Subscribers',
          'values': [validUuid1, validUuid2, validUuid3],
        };

        final target = WorkflowTarget.fromJson(originalJson);
        final outputJson = target.toJson();

        expect(outputJson['type'], originalJson['type']);
        expect(outputJson['values'], originalJson['values']);
      });
    });

    group('toString', () {
      test('returns formatted string representation', () {
        final target = WorkflowTarget(
          type: WorkflowTargetType.subscribers,
          values: [validUuid1],
        );

        final result = target.toString();

        expect(result, contains('WorkflowTarget'));
        expect(result, contains('Subscribers'));
        expect(result, contains(validUuid1));
      });
    });

    group('equality', () {
      test('two targets with same type and values are equal', () {
        final target1 = WorkflowTarget(
          type: WorkflowTargetType.subscribers,
          values: [validUuid1, validUuid2],
        );
        final target2 = WorkflowTarget(
          type: WorkflowTargetType.subscribers,
          values: [validUuid1, validUuid2],
        );

        expect(target1, equals(target2));
      });

      test('targets with different types are not equal', () {
        final target1 = WorkflowTarget(
          type: WorkflowTargetType.subscribers,
          values: [validUuid1],
        );
        final target2 = WorkflowTarget(
          type: WorkflowTargetType.segments,
          values: [validUuid1],
        );

        expect(target1, isNot(equals(target2)));
      });

      test('targets with different values are not equal', () {
        final target1 = WorkflowTarget(
          type: WorkflowTargetType.subscribers,
          values: [validUuid1],
        );
        final target2 = WorkflowTarget(
          type: WorkflowTargetType.subscribers,
          values: [validUuid2],
        );

        expect(target1, isNot(equals(target2)));
      });

      test('targets with different value ordering are not equal', () {
        final target1 = WorkflowTarget(
          type: WorkflowTargetType.subscribers,
          values: [validUuid1, validUuid2],
        );
        final target2 = WorkflowTarget(
          type: WorkflowTargetType.subscribers,
          values: [validUuid2, validUuid1],
        );

        expect(target1, isNot(equals(target2)));
      });

      test('target is not equal to a non-WorkflowTarget object', () {
        final target = WorkflowTarget(
          type: WorkflowTargetType.subscribers,
          values: [validUuid1],
        );

        expect(target, isNot(equals('not a target')));
        expect(target, isNot(equals(42)));
      });

      test('identical instances are equal', () {
        final target = WorkflowTarget(
          type: WorkflowTargetType.subscribers,
          values: [validUuid1],
        );

        expect(target, equals(target));
      });
    });

    group('hashCode', () {
      test('equal targets have the same hashCode', () {
        final target1 = WorkflowTarget(
          type: WorkflowTargetType.subscribers,
          values: [validUuid1, validUuid2],
        );
        final target2 = WorkflowTarget(
          type: WorkflowTargetType.subscribers,
          values: [validUuid1, validUuid2],
        );

        expect(target1.hashCode, equals(target2.hashCode));
      });

      test('different targets likely have different hashCodes', () {
        final target1 = WorkflowTarget(
          type: WorkflowTargetType.subscribers,
          values: [validUuid1],
        );
        final target2 = WorkflowTarget(
          type: WorkflowTargetType.segments,
          values: [validUuid2],
        );

        // Hash collisions are possible but very unlikely for different inputs
        expect(target1.hashCode, isNot(equals(target2.hashCode)));
      });
    });
  });

  // =========================================================================
  // WorkflowExecutionRequest
  // =========================================================================
  group('WorkflowExecutionRequest', () {
    // Shared helpers
    WorkflowTarget makeTarget({
      WorkflowTargetType type = WorkflowTargetType.subscribers,
      List<String>? values,
    }) {
      return WorkflowTarget(
        type: type,
        values: values ?? [validUuid1],
      );
    }

    group('construction', () {
      test('creates immediate execution request', () {
        final target = makeTarget();
        final request = WorkflowExecutionRequest(
          workflowId: validUuid1,
          type: WorkflowExecutionType.immediate,
          target: target,
        );

        expect(request.workflowId, validUuid1);
        expect(request.type, WorkflowExecutionType.immediate);
        expect(request.scheduledFor, isNull);
        expect(request.target, target);
      });

      test('creates scheduled execution request', () {
        final scheduledDate = DateTime.utc(2026, 6, 15, 10, 30);
        final target = makeTarget();
        final request = WorkflowExecutionRequest(
          workflowId: validUuid1,
          type: WorkflowExecutionType.scheduled,
          scheduledFor: scheduledDate,
          target: target,
        );

        expect(request.workflowId, validUuid1);
        expect(request.type, WorkflowExecutionType.scheduled);
        expect(request.scheduledFor, scheduledDate);
        expect(request.target, target);
      });

      test('scheduledFor is optional even for scheduled type at construction', () {
        // Construction does not validate; validate() does.
        final request = WorkflowExecutionRequest(
          workflowId: validUuid1,
          type: WorkflowExecutionType.scheduled,
          target: makeTarget(),
        );

        expect(request.scheduledFor, isNull);
      });
    });

    group('fromJson', () {
      test('parses immediate request from nested data JSON', () {
        final json = {
          'data': {
            'workflowId': validUuid1,
            'type': 'Immediate',
            'target': {
              'type': 'Subscribers',
              'values': [validUuid2],
            },
          },
        };

        final request = WorkflowExecutionRequest.fromJson(json);

        expect(request.workflowId, validUuid1);
        expect(request.type, WorkflowExecutionType.immediate);
        expect(request.scheduledFor, isNull);
        expect(request.target.type, WorkflowTargetType.subscribers);
        expect(request.target.values, [validUuid2]);
      });

      test('parses scheduled request with scheduledFor', () {
        final json = {
          'data': {
            'workflowId': validUuid1,
            'type': 'Scheduled',
            'scheduledFor': '2026-06-15T10:30:00.000Z',
            'target': {
              'type': 'Segments',
              'values': [validUuid2, validUuid3],
            },
          },
        };

        final request = WorkflowExecutionRequest.fromJson(json);

        expect(request.type, WorkflowExecutionType.scheduled);
        expect(request.scheduledFor, DateTime.utc(2026, 6, 15, 10, 30));
        expect(request.target.type, WorkflowTargetType.segments);
        expect(request.target.values, hasLength(2));
      });

      test('parses request where scheduledFor is null', () {
        final json = {
          'data': {
            'workflowId': validUuid1,
            'type': 'Immediate',
            'scheduledFor': null,
            'target': {
              'type': 'Subscribers',
              'values': [validUuid1],
            },
          },
        };

        final request = WorkflowExecutionRequest.fromJson(json);

        expect(request.scheduledFor, isNull);
      });

      test('parses request where scheduledFor key is absent', () {
        final json = {
          'data': {
            'workflowId': validUuid1,
            'type': 'Immediate',
            'target': {
              'type': 'Subscribers',
              'values': [validUuid1],
            },
          },
        };

        final request = WorkflowExecutionRequest.fromJson(json);

        expect(request.scheduledFor, isNull);
      });
    });

    group('toJson', () {
      test('wraps output in a data field', () {
        final request = WorkflowExecutionRequest(
          workflowId: validUuid1,
          type: WorkflowExecutionType.immediate,
          target: makeTarget(),
        );

        final json = request.toJson();

        expect(json.containsKey('data'), isTrue);
        expect(json['data'], isA<Map<String, dynamic>>());
      });

      test('serializes immediate request without scheduledFor', () {
        final request = WorkflowExecutionRequest(
          workflowId: validUuid1,
          type: WorkflowExecutionType.immediate,
          target: makeTarget(values: [validUuid2]),
        );

        final json = request.toJson();
        final data = json['data'] as Map<String, dynamic>;

        expect(data['workflowId'], validUuid1);
        expect(data['type'], 'Immediate');
        expect(data.containsKey('scheduledFor'), isFalse);
        expect(data['target'], isA<Map<String, dynamic>>());
      });

      test('serializes scheduled request with ISO8601 scheduledFor', () {
        final scheduledDate = DateTime.utc(2026, 6, 15, 10, 30);
        final request = WorkflowExecutionRequest(
          workflowId: validUuid1,
          type: WorkflowExecutionType.scheduled,
          scheduledFor: scheduledDate,
          target: makeTarget(),
        );

        final json = request.toJson();
        final data = json['data'] as Map<String, dynamic>;

        expect(data['type'], 'Scheduled');
        expect(data['scheduledFor'], scheduledDate.toIso8601String());
        expect(data['scheduledFor'], '2026-06-15T10:30:00.000Z');
      });

      test('serializes target with correct structure', () {
        final request = WorkflowExecutionRequest(
          workflowId: validUuid1,
          type: WorkflowExecutionType.immediate,
          target: WorkflowTarget(
            type: WorkflowTargetType.segments,
            values: [validUuid2, validUuid3],
          ),
        );

        final json = request.toJson();
        final targetJson =
            (json['data'] as Map<String, dynamic>)['target'] as Map<String, dynamic>;

        expect(targetJson['type'], 'Segments');
        expect(targetJson['values'], [validUuid2, validUuid3]);
      });

      test('round-trip fromJson/toJson preserves immediate request', () {
        final original = WorkflowExecutionRequest(
          workflowId: validUuid1,
          type: WorkflowExecutionType.immediate,
          target: WorkflowTarget(
            type: WorkflowTargetType.subscribers,
            values: [validUuid2],
          ),
        );

        final json = original.toJson();
        final restored = WorkflowExecutionRequest.fromJson(json);

        expect(restored.workflowId, original.workflowId);
        expect(restored.type, original.type);
        expect(restored.scheduledFor, original.scheduledFor);
        expect(restored.target, original.target);
        expect(restored, equals(original));
      });

      test('round-trip fromJson/toJson preserves scheduled request', () {
        final scheduledDate = DateTime.utc(2026, 12, 25, 8, 0);
        final original = WorkflowExecutionRequest(
          workflowId: validUuid1,
          type: WorkflowExecutionType.scheduled,
          scheduledFor: scheduledDate,
          target: WorkflowTarget(
            type: WorkflowTargetType.segments,
            values: [validUuid2, validUuid3],
          ),
        );

        final json = original.toJson();
        final restored = WorkflowExecutionRequest.fromJson(json);

        expect(restored, equals(original));
      });
    });

    group('validate', () {
      group('passes for valid data', () {
        test('valid immediate request', () {
          final request = WorkflowExecutionRequest(
            workflowId: validUuid1,
            type: WorkflowExecutionType.immediate,
            target: makeTarget(values: [validUuid2]),
          );

          // Should not throw
          expect(() => request.validate(), returnsNormally);
        });

        test('valid scheduled request with scheduledFor', () {
          final request = WorkflowExecutionRequest(
            workflowId: validUuid1,
            type: WorkflowExecutionType.scheduled,
            scheduledFor: DateTime.utc(2026, 6, 15),
            target: makeTarget(values: [validUuid2]),
          );

          expect(() => request.validate(), returnsNormally);
        });

        test('valid request with multiple target values', () {
          final request = WorkflowExecutionRequest(
            workflowId: validUuid1,
            type: WorkflowExecutionType.immediate,
            target: makeTarget(values: [validUuid1, validUuid2, validUuid3]),
          );

          expect(() => request.validate(), returnsNormally);
        });

        test('valid request with segments target type', () {
          final request = WorkflowExecutionRequest(
            workflowId: validUuid1,
            type: WorkflowExecutionType.immediate,
            target: makeTarget(
              type: WorkflowTargetType.segments,
              values: [validUuid2],
            ),
          );

          expect(() => request.validate(), returnsNormally);
        });

        test('immediate request with scheduledFor set is valid', () {
          // Having scheduledFor on an immediate request is not an error
          final request = WorkflowExecutionRequest(
            workflowId: validUuid1,
            type: WorkflowExecutionType.immediate,
            scheduledFor: DateTime.utc(2026, 6, 15),
            target: makeTarget(values: [validUuid2]),
          );

          expect(() => request.validate(), returnsNormally);
        });
      });

      group('throws for empty workflowId', () {
        test('empty string workflowId', () {
          final request = WorkflowExecutionRequest(
            workflowId: '',
            type: WorkflowExecutionType.immediate,
            target: makeTarget(values: [validUuid1]),
          );

          expect(
            () => request.validate(),
            throwsA(
              predicate<ArgumentError>(
                (e) => e.message == 'workflowId cannot be empty',
              ),
            ),
          );
        });
      });

      group('throws for non-UUID workflowId', () {
        test('plain string is rejected', () {
          final request = WorkflowExecutionRequest(
            workflowId: 'not-a-uuid',
            type: WorkflowExecutionType.immediate,
            target: makeTarget(values: [validUuid1]),
          );

          expect(
            () => request.validate(),
            throwsA(
              predicate<ArgumentError>(
                (e) => e.message == 'workflowId must be a valid UUID',
              ),
            ),
          );
        });

        test('UUID missing dashes is rejected', () {
          final request = WorkflowExecutionRequest(
            workflowId: '550e8400e29b41d4a716446655440000',
            type: WorkflowExecutionType.immediate,
            target: makeTarget(values: [validUuid1]),
          );

          expect(
            () => request.validate(),
            throwsA(isA<ArgumentError>()),
          );
        });

        test('UUID with wrong segment lengths is rejected', () {
          final request = WorkflowExecutionRequest(
            workflowId: '550e8400-e29b-41d4-a716-44665544000',
            type: WorkflowExecutionType.immediate,
            target: makeTarget(values: [validUuid1]),
          );

          expect(
            () => request.validate(),
            throwsA(isA<ArgumentError>()),
          );
        });

        test('UUID with invalid characters is rejected', () {
          final request = WorkflowExecutionRequest(
            workflowId: '550e8400-e29b-41d4-a716-44665544ZZZZ',
            type: WorkflowExecutionType.immediate,
            target: makeTarget(values: [validUuid1]),
          );

          expect(
            () => request.validate(),
            throwsA(isA<ArgumentError>()),
          );
        });
      });

      group('throws for scheduled type without scheduledFor', () {
        test('scheduled type with null scheduledFor', () {
          final request = WorkflowExecutionRequest(
            workflowId: validUuid1,
            type: WorkflowExecutionType.scheduled,
            scheduledFor: null,
            target: makeTarget(values: [validUuid2]),
          );

          expect(
            () => request.validate(),
            throwsA(
              predicate<ArgumentError>(
                (e) =>
                    e.message ==
                    'scheduledFor is required when type is Scheduled',
              ),
            ),
          );
        });
      });

      group('throws for empty target values', () {
        test('empty target values list', () {
          final request = WorkflowExecutionRequest(
            workflowId: validUuid1,
            type: WorkflowExecutionType.immediate,
            target: makeTarget(values: []),
          );

          expect(
            () => request.validate(),
            throwsA(
              predicate<ArgumentError>(
                (e) => e.message == 'target values cannot be empty',
              ),
            ),
          );
        });
      });

      group('throws for non-UUID target values', () {
        test('non-UUID string in target values', () {
          final request = WorkflowExecutionRequest(
            workflowId: validUuid1,
            type: WorkflowExecutionType.immediate,
            target: makeTarget(values: ['not-a-valid-uuid']),
          );

          expect(
            () => request.validate(),
            throwsA(
              predicate<ArgumentError>(
                (e) => (e.message as String)
                    .startsWith('All target values must be valid UUIDs:'),
              ),
            ),
          );
        });

        test('mix of valid and invalid UUIDs in target values', () {
          final request = WorkflowExecutionRequest(
            workflowId: validUuid1,
            type: WorkflowExecutionType.immediate,
            target: makeTarget(values: [validUuid2, 'bad-uuid']),
          );

          expect(
            () => request.validate(),
            throwsA(isA<ArgumentError>()),
          );
        });

        test('error message includes the invalid target value', () {
          const badValue = 'xyz-not-uuid';
          final request = WorkflowExecutionRequest(
            workflowId: validUuid1,
            type: WorkflowExecutionType.immediate,
            target: makeTarget(values: [badValue]),
          );

          expect(
            () => request.validate(),
            throwsA(
              predicate<ArgumentError>(
                (e) => e.message ==
                    'All target values must be valid UUIDs: $badValue',
              ),
            ),
          );
        });
      });

      group('validation priority order', () {
        test('empty workflowId checked before scheduled without scheduledFor', () {
          final request = WorkflowExecutionRequest(
            workflowId: '',
            type: WorkflowExecutionType.scheduled,
            target: makeTarget(values: [validUuid1]),
          );

          expect(
            () => request.validate(),
            throwsA(
              predicate<ArgumentError>(
                (e) => e.message == 'workflowId cannot be empty',
              ),
            ),
          );
        });

        test('scheduled without scheduledFor checked before empty target values', () {
          final request = WorkflowExecutionRequest(
            workflowId: validUuid1,
            type: WorkflowExecutionType.scheduled,
            scheduledFor: null,
            target: makeTarget(values: []),
          );

          expect(
            () => request.validate(),
            throwsA(
              predicate<ArgumentError>(
                (e) =>
                    e.message ==
                    'scheduledFor is required when type is Scheduled',
              ),
            ),
          );
        });

        test('empty target values checked before invalid UUID workflowId', () {
          // workflowId is non-empty but not a UUID, and target values are empty.
          // Empty target values is checked first (before UUID format checks).
          final request = WorkflowExecutionRequest(
            workflowId: 'not-a-uuid',
            type: WorkflowExecutionType.immediate,
            target: makeTarget(values: []),
          );

          expect(
            () => request.validate(),
            throwsA(
              predicate<ArgumentError>(
                (e) => e.message == 'target values cannot be empty',
              ),
            ),
          );
        });

        test('invalid workflowId UUID checked before invalid target value UUIDs', () {
          final request = WorkflowExecutionRequest(
            workflowId: 'not-uuid-format',
            type: WorkflowExecutionType.immediate,
            target: makeTarget(values: ['also-not-uuid']),
          );

          expect(
            () => request.validate(),
            throwsA(
              predicate<ArgumentError>(
                (e) => e.message == 'workflowId must be a valid UUID',
              ),
            ),
          );
        });
      });
    });

    group('toString', () {
      test('returns formatted string with all fields', () {
        final request = WorkflowExecutionRequest(
          workflowId: validUuid1,
          type: WorkflowExecutionType.immediate,
          target: makeTarget(),
        );

        final result = request.toString();

        expect(result, contains('WorkflowExecutionRequest'));
        expect(result, contains(validUuid1));
        expect(result, contains('Immediate'));
      });
    });

    group('equality', () {
      test('two identical immediate requests are equal', () {
        final target = makeTarget(values: [validUuid2]);
        final request1 = WorkflowExecutionRequest(
          workflowId: validUuid1,
          type: WorkflowExecutionType.immediate,
          target: target,
        );
        final request2 = WorkflowExecutionRequest(
          workflowId: validUuid1,
          type: WorkflowExecutionType.immediate,
          target: WorkflowTarget(
            type: WorkflowTargetType.subscribers,
            values: [validUuid2],
          ),
        );

        expect(request1, equals(request2));
      });

      test('two identical scheduled requests are equal', () {
        final scheduledDate = DateTime.utc(2026, 6, 15);
        final request1 = WorkflowExecutionRequest(
          workflowId: validUuid1,
          type: WorkflowExecutionType.scheduled,
          scheduledFor: scheduledDate,
          target: makeTarget(values: [validUuid2]),
        );
        final request2 = WorkflowExecutionRequest(
          workflowId: validUuid1,
          type: WorkflowExecutionType.scheduled,
          scheduledFor: DateTime.utc(2026, 6, 15),
          target: makeTarget(values: [validUuid2]),
        );

        expect(request1, equals(request2));
      });

      test('requests with different workflowId are not equal', () {
        final request1 = WorkflowExecutionRequest(
          workflowId: validUuid1,
          type: WorkflowExecutionType.immediate,
          target: makeTarget(),
        );
        final request2 = WorkflowExecutionRequest(
          workflowId: validUuid2,
          type: WorkflowExecutionType.immediate,
          target: makeTarget(),
        );

        expect(request1, isNot(equals(request2)));
      });

      test('requests with different types are not equal', () {
        final request1 = WorkflowExecutionRequest(
          workflowId: validUuid1,
          type: WorkflowExecutionType.immediate,
          target: makeTarget(),
        );
        final request2 = WorkflowExecutionRequest(
          workflowId: validUuid1,
          type: WorkflowExecutionType.scheduled,
          scheduledFor: DateTime.utc(2026, 6, 15),
          target: makeTarget(),
        );

        expect(request1, isNot(equals(request2)));
      });

      test('requests with different scheduledFor are not equal', () {
        final request1 = WorkflowExecutionRequest(
          workflowId: validUuid1,
          type: WorkflowExecutionType.scheduled,
          scheduledFor: DateTime.utc(2026, 6, 15),
          target: makeTarget(),
        );
        final request2 = WorkflowExecutionRequest(
          workflowId: validUuid1,
          type: WorkflowExecutionType.scheduled,
          scheduledFor: DateTime.utc(2026, 7, 20),
          target: makeTarget(),
        );

        expect(request1, isNot(equals(request2)));
      });

      test('requests with different targets are not equal', () {
        final request1 = WorkflowExecutionRequest(
          workflowId: validUuid1,
          type: WorkflowExecutionType.immediate,
          target: makeTarget(values: [validUuid2]),
        );
        final request2 = WorkflowExecutionRequest(
          workflowId: validUuid1,
          type: WorkflowExecutionType.immediate,
          target: makeTarget(values: [validUuid3]),
        );

        expect(request1, isNot(equals(request2)));
      });

      test('request is not equal to a non-WorkflowExecutionRequest object', () {
        final request = WorkflowExecutionRequest(
          workflowId: validUuid1,
          type: WorkflowExecutionType.immediate,
          target: makeTarget(),
        );

        expect(request, isNot(equals('a string')));
        expect(request, isNot(equals(123)));
      });

      test('identical instance is equal to itself', () {
        final request = WorkflowExecutionRequest(
          workflowId: validUuid1,
          type: WorkflowExecutionType.immediate,
          target: makeTarget(),
        );

        expect(request, equals(request));
      });
    });

    group('hashCode', () {
      test('equal requests have the same hashCode', () {
        final request1 = WorkflowExecutionRequest(
          workflowId: validUuid1,
          type: WorkflowExecutionType.immediate,
          target: makeTarget(values: [validUuid2]),
        );
        final request2 = WorkflowExecutionRequest(
          workflowId: validUuid1,
          type: WorkflowExecutionType.immediate,
          target: WorkflowTarget(
            type: WorkflowTargetType.subscribers,
            values: [validUuid2],
          ),
        );

        expect(request1.hashCode, equals(request2.hashCode));
      });

      test('equal scheduled requests have the same hashCode', () {
        final date = DateTime.utc(2026, 6, 15);
        final request1 = WorkflowExecutionRequest(
          workflowId: validUuid1,
          type: WorkflowExecutionType.scheduled,
          scheduledFor: date,
          target: makeTarget(values: [validUuid2]),
        );
        final request2 = WorkflowExecutionRequest(
          workflowId: validUuid1,
          type: WorkflowExecutionType.scheduled,
          scheduledFor: DateTime.utc(2026, 6, 15),
          target: makeTarget(values: [validUuid2]),
        );

        expect(request1.hashCode, equals(request2.hashCode));
      });

      test('different requests likely have different hashCodes', () {
        final request1 = WorkflowExecutionRequest(
          workflowId: validUuid1,
          type: WorkflowExecutionType.immediate,
          target: makeTarget(values: [validUuid2]),
        );
        final request2 = WorkflowExecutionRequest(
          workflowId: validUuid2,
          type: WorkflowExecutionType.scheduled,
          scheduledFor: DateTime.utc(2026, 6, 15),
          target: makeTarget(
            type: WorkflowTargetType.segments,
            values: [validUuid3],
          ),
        );

        expect(request1.hashCode, isNot(equals(request2.hashCode)));
      });

      test('hashCode is consistent across multiple calls', () {
        final request = WorkflowExecutionRequest(
          workflowId: validUuid1,
          type: WorkflowExecutionType.immediate,
          target: makeTarget(),
        );

        final hash1 = request.hashCode;
        final hash2 = request.hashCode;
        final hash3 = request.hashCode;

        expect(hash1, equals(hash2));
        expect(hash2, equals(hash3));
      });
    });
  });
}

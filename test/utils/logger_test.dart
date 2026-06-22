import 'package:flutter_test/flutter_test.dart';
import 'package:pushfire_sdk/src/utils/logger.dart';

void main() {
  group('PushFireLogger.formatApiError', () {
    test('includes code when present', () {
      expect(
        PushFireLogger.formatApiError('PATCH', 'update-subscriber', 401,
            'missing_auth', 'Missing authorization header'),
        'API error: PATCH update-subscriber -> HTTP 401 '
        'code=missing_auth msg="Missing authorization header"',
      );
    });

    test('omits code when null', () {
      expect(
        PushFireLogger.formatApiError('POST', 'x', 500, null, 'boom'),
        'API error: POST x -> HTTP 500 msg="boom"',
      );
    });
  });
}

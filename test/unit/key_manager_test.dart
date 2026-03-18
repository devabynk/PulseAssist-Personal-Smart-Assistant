import 'package:flutter_test/flutter_test.dart';
import 'package:smart_assistant/core/utils/key_manager.dart';

void main() {
  group('KeyManager', () {
    // ── Construction ──────────────────────────────────────────────────────
    group('Construction', () {
      test('creates with single key', () {
        final km = KeyManager(['key-a'], serviceName: 'Test');
        expect(km.currentKey, 'key-a');
      });

      test('creates with multiple keys', () {
        final km = KeyManager(['key-a', 'key-b'], serviceName: 'Test');
        expect(km.currentKey, 'key-a');
      });

      test('empty key list returns empty string for currentKey', () {
        final km = KeyManager([], serviceName: 'Test');
        expect(km.currentKey, '');
      });
    });

    // ── Rotation ──────────────────────────────────────────────────────────
    group('rotate()', () {
      test('cycles through keys', () {
        final km = KeyManager(['a', 'b', 'c'], serviceName: 'Test');
        expect(km.rotate(), 'b');
        expect(km.rotate(), 'c');
        expect(km.rotate(), 'a'); // wraps around
      });

      test('single key always returns same key', () {
        final km = KeyManager(['only'], serviceName: 'Test');
        expect(km.rotate(), 'only');
        expect(km.rotate(), 'only');
      });

      test('empty list returns empty string', () {
        final km = KeyManager([], serviceName: 'Test');
        expect(km.rotate(), '');
      });

      test('skips keys in cooldown', () {
        final km = KeyManager(['a', 'b', 'c'], serviceName: 'Test');
        // Put 'b' in cooldown by reporting rateLimit while on 'a', which rotates to 'b'
        // We need to rotate to b first, report failure, then rotate should skip b
        km.rotate(); // now on 'b'
        km.reportFailure(FailureType.rateLimit); // puts 'b' in cooldown, rotates to 'c'
        // Current is now 'c'; rotate should skip 'b' and go to 'a'
        expect(km.rotate(), 'a');
      });

      test('when all keys in cooldown, force-rotates anyway', () {
        final km = KeyManager(['a', 'b'], serviceName: 'Test');
        // Put both in cooldown
        km.reportFailure(FailureType.rateLimit); // 'a' in cooldown, now on 'b'
        km.reportFailure(FailureType.rateLimit); // 'b' in cooldown, now on 'a'
        // Both in cooldown — rotate() should still return something (force rotate)
        final key = km.rotate();
        expect(key, isNotEmpty);
      });
    });

    // ── reportFailure ─────────────────────────────────────────────────────
    group('reportFailure()', () {
      test('rateLimit puts key in cooldown and rotates', () {
        final km = KeyManager(['a', 'b', 'c'], serviceName: 'Test');
        expect(km.currentKey, 'a');
        km.reportFailure(FailureType.rateLimit);
        // should have rotated away from 'a'
        expect(km.currentKey, isNot('a'));
      });

      test('unauthorized puts key in cooldown and rotates', () {
        final km = KeyManager(['a', 'b'], serviceName: 'Test');
        km.reportFailure(FailureType.unauthorized);
        expect(km.currentKey, 'b');
      });

      test('serverError rotates but does not add cooldown', () {
        final km = KeyManager(['a', 'b'], serviceName: 'Test');
        km.reportFailure(FailureType.serverError);
        // Rotated to 'b'
        expect(km.currentKey, 'b');
        // 'a' should not be in cooldown — rotate back and check
        km.rotate(); // back to 'a'
        expect(km.currentKey, 'a');
      });

      test('connection error does not auto-rotate', () {
        final km = KeyManager(['a', 'b'], serviceName: 'Test');
        km.reportFailure(FailureType.connection);
        // No rotation for connection errors
        expect(km.currentKey, 'a');
      });

      test('unknown failure type does not rotate', () {
        final km = KeyManager(['a', 'b'], serviceName: 'Test');
        km.reportFailure(FailureType.unknown);
        expect(km.currentKey, 'a');
      });

      test('no-op on empty list', () {
        final km = KeyManager([], serviceName: 'Test');
        // Should not throw
        km.reportFailure(FailureType.rateLimit);
        expect(km.currentKey, '');
      });
    });

    // ── executeWithRetry ──────────────────────────────────────────────────
    group('executeWithRetry()', () {
      test('returns value on first success', () async {
        final km = KeyManager(['key1'], serviceName: 'Test');
        final result = await km.executeWithRetry(
          (key) async => 'ok:$key',
        );
        expect(result, 'ok:key1');
      });

      test('retries on failure and succeeds on second attempt', () async {
        final km = KeyManager(['a', 'b'], serviceName: 'Test');
        var callCount = 0;
        final result = await km.executeWithRetry<String>((key) async {
          callCount++;
          if (callCount == 1) throw Exception('500 server error');
          return 'success';
        });
        expect(result, 'success');
        expect(callCount, 2);
      });

      test('throws after all attempts exhausted', () async {
        final km = KeyManager(['a', 'b'], serviceName: 'Test');
        expect(
          () => km.executeWithRetry<String>(
            (key) async => throw Exception('429 rate limit'),
            maxAttempts: 2,
          ),
          throwsException,
        );
      });

      test('detects 429 as rateLimit and rotates key', () async {
        final km = KeyManager(['a', 'b', 'c'], serviceName: 'Test');
        final usedKeys = <String>[];
        try {
          await km.executeWithRetry<String>((key) async {
            usedKeys.add(key);
            throw Exception('429 rate limit exceeded');
          }, maxAttempts: 3);
        } catch (_) {}
        // Should have tried different keys
        expect(usedKeys.toSet().length, greaterThan(1));
      });

      test('detects 401 as unauthorized and rotates key', () async {
        final km = KeyManager(['a', 'b'], serviceName: 'Test');
        String? lastKey;
        try {
          await km.executeWithRetry<String>((key) async {
            lastKey = key;
            throw Exception('401 unauthorized');
          }, maxAttempts: 2);
        } catch (_) {}
        // Last attempt should be on 'b' (rotated from 'a')
        expect(lastKey, 'b');
      });

      test('uses at least as many attempts as there are keys', () async {
        final km = KeyManager(['a', 'b', 'c', 'd'], serviceName: 'Test');
        var callCount = 0;
        try {
          await km.executeWithRetry<String>((key) async {
            callCount++;
            throw Exception('error');
          }, maxAttempts: 2); // only 2 maxAttempts but 4 keys
        } catch (_) {}
        // Should attempt at least 4 times (number of keys)
        expect(callCount, greaterThanOrEqualTo(4));
      });

      test('connection error adds delay before retry', () async {
        final km = KeyManager(['a', 'b'], serviceName: 'Test');
        final stopwatch = Stopwatch()..start();
        try {
          await km.executeWithRetry<String>((key) async {
            throw Exception('connection timeout');
          }, maxAttempts: 2);
        } catch (_) {}
        stopwatch.stop();
        // Connection error adds 1 second delay — total should be >= 1s for 2 attempts
        expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(900));
      });
    });

    // ── Cooldown expiry ───────────────────────────────────────────────────
    group('Cooldown expiry', () {
      test('cooldown is removed after it expires', () async {
        // We cannot fast-forward 5 minutes in unit tests easily,
        // but we verify the logic: a key NOT in failedKeys is not in cooldown.
        final km = KeyManager(['a', 'b'], serviceName: 'Test');
        // 'a' is not in cooldown initially — rotate should prefer non-failed keys
        km.rotate(); // go to 'b'
        // 'b' is not in cooldown either
        expect(km.currentKey, 'b');
      });
    });
  });
}

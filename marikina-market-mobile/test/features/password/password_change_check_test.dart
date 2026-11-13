import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/core/utils/password_change_check.dart';

const rule = 'Use at least 8 characters, with a number and a capital letter.';

void main() {
  test('empty current password asks for it', () {
    final check = PasswordChangeCheck('', 'Abcdefg1', 'Abcdefg1');
    expect(check.currentError, 'Enter your current password.');
    expect(check.newPasswordError, isNull);
    expect(check.confirmError, isNull);
    expect(check.isValid, isFalse);
  });

  test('new password without a capital letter is rejected', () {
    final check = PasswordChangeCheck('Old1', 'abcdefg1', 'abcdefg1');
    expect(check.newPasswordError, rule);
    expect(check.isValid, isFalse);
  });

  test('new password without a number is rejected', () {
    final check = PasswordChangeCheck('Old1', 'Abcdefgh', 'Abcdefgh');
    expect(check.newPasswordError, rule);
    expect(check.isValid, isFalse);
  });

  test('new password shorter than 8 characters is rejected', () {
    final check = PasswordChangeCheck('Old1', 'Abc1', 'Abc1');
    expect(check.newPasswordError, rule);
    expect(check.isValid, isFalse);
  });

  test('mismatched confirmation is reported', () {
    final check = PasswordChangeCheck('Old1', 'Abcdefg1', 'Abcdefg2');
    expect(check.confirmError, 'Passwords do not match.');
    expect(check.newPasswordError, isNull);
    expect(check.isValid, isFalse);
  });

  test('empty confirmation asks for it', () {
    final check = PasswordChangeCheck('Old1', 'Abcdefg1', '');
    expect(check.confirmError, 'Confirm your new password.');
    expect(check.isValid, isFalse);
  });

  test('newPasswordProblem gives the rule text, or null when it is met', () {
    expect(PasswordChangeCheck.newPasswordProblem('abcdefg1'), rule);
    expect(PasswordChangeCheck.newPasswordProblem('Abcdefg1'), isNull);
  });

  test('a valid new password with matching confirmation has no messages', () {
    final check = PasswordChangeCheck('Old1', 'Abcdefg1', 'Abcdefg1');
    expect(check.currentError, isNull);
    expect(check.newPasswordError, isNull);
    expect(check.confirmError, isNull);
    expect(check.isValid, isTrue);
  });
}

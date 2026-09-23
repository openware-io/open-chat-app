import 'package:flutter_test/flutter_test.dart';
import 'package:open_chat_app/models/points_account_binding.dart';

void main() {
  group('points account validation', () {
    test('validates supported account types', () {
      expect(
        isValidPointsAccount(PointsAccountType.phone, '13800125689'),
        isTrue,
      );
      expect(
        isValidPointsAccount(PointsAccountType.phone, '1234'),
        isFalse,
      );
      expect(
        isValidPointsAccount(PointsAccountType.email, 'xiaimu@example.com'),
        isTrue,
      );
      expect(
        isValidPointsAccount(PointsAccountType.email, 'xiaimu@'),
        isFalse,
      );
      expect(
        isValidPointsAccount(PointsAccountType.account, '12456789'),
        isTrue,
      );
      expect(
        isValidPointsAccount(PointsAccountType.account, 'abc'),
        isFalse,
      );
    });

    test('masks bound account values', () {
      expect(
        maskPointsAccount(PointsAccountType.phone, '13800125689'),
        '138****5689',
      );
      expect(
        maskPointsAccount(PointsAccountType.email, 'xiaimu@example.com'),
        'xi***@example.com',
      );
      expect(
        maskPointsAccount(PointsAccountType.account, '12456789'),
        '12******89',
      );
    });

    test('validates phone lengths for the selected country', () {
      final china =
          kPhoneCountries.firstWhere((country) => country.code == 'CN');
      final unitedStates =
          kPhoneCountries.firstWhere((country) => country.code == 'US');
      final hongKong =
          kPhoneCountries.firstWhere((country) => country.code == 'HK');

      expect(isValidPhoneForCountry(china, '13800125689'), isTrue);
      expect(isValidPhoneForCountry(china, '1380012568'), isFalse);
      expect(isValidPhoneForCountry(unitedStates, '4155552671'), isTrue);
      expect(isValidPhoneForCountry(unitedStates, '41555526710'), isFalse);
      expect(isValidPhoneForCountry(hongKong, '91234567'), isTrue);
      expect(isValidPhoneForCountry(hongKong, '9123456'), isFalse);
    });

    test('defines a country-specific length rule for every country option', () {
      for (final country in kPhoneCountries) {
        final length = phoneNumberLengthForCountry(country);
        expect(length.min, greaterThanOrEqualTo(7), reason: country.code);
        expect(length.max, lessThanOrEqualTo(12), reason: country.code);
      }
    });
  });
}

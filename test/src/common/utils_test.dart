import 'package:flutter/services.dart';
import 'package:flutter_paystack/src/common/my_strings.dart';
import 'package:flutter_paystack/src/common/utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("$Utils", () {
    group("#getKeyErrorMsg", () {
      test("returns a string with keyType", () {
        final keyType = "public";
        expect(Utils.getKeyErrorMsg(keyType), contains(keyType));
      });
    });

    group("#formatAmount", () {
      test("throws Error when currency formatter is not set", () {
        expect(() => Utils.formatAmount(100), throwsA(TypeMatcher<String>()));
      });

      test("returns normally when currency formatter has been set", () {
        Utils.setCurrencyFormatter(Strings.ngn, Strings.nigerianLocale);
        expect(() => Utils.formatAmount(100), returnsNormally);
      });
    });
  });
}

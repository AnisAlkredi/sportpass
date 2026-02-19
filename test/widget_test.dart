import 'package:flutter_test/flutter_test.dart';

import 'package:sportpass/core/widgets/utils.dart';

void main() {
  test('formatSYP formats Syrian pounds with separators', () {
    expect(formatSYP(12500), '12,500 ل.س');
    expect(formatSYP(500000), '500,000 ل.س');
  });
}

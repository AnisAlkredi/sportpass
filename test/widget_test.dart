import 'package:flutter_test/flutter_test.dart';

import 'package:sportpass/core/widgets/utils.dart';

void main() {
  test('formatSYP formats new Syrian pound values with separators', () {
    expect(formatSYP(125), '125 ل.س جديدة');
    expect(formatSYP(5000), '5,000 ل.س جديدة');
  });
}

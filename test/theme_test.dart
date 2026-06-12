import 'package:flutter_test/flutter_test.dart';
import 'package:yt_downloader/core/theme/theme.dart';

void main() {
  test('MskTheme lightTheme uses expected primary and secondary colors', () {
    final theme = MskTheme.lightTheme;

    expect(theme.colorScheme.primary, MskColors.primary);
    expect(theme.colorScheme.secondary, MskColors.secondary);
    expect(theme.scaffoldBackgroundColor, MskColors.surface);
    expect(theme.appBarTheme.backgroundColor, MskColors.primary);
  });
}

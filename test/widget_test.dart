import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:emc_helpline/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const EMCHelplineApp());
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('EMC Helpline'), findsWidgets);
  });
}

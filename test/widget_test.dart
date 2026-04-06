import 'package:flutter_test/flutter_test.dart';
import 'package:glaucoma_detect/main.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const EyeDetectApp());

    // Verify that our app starts and has the title.
    expect(find.text('EyeDetect'), findsWidgets);
  });
}

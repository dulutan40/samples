import 'package:flutter_test/flutter_test.dart';
import 'package:last_to_tap/src/app/app.dart';

void main() {
  testWidgets('home shows brand and modes', (tester) async {
    await tester.pumpWidget(const LastToTapApp());
    await tester.pump();
    expect(find.textContaining('LAST TO TAP'), findsOneWidget);
    expect(find.textContaining('Online room'), findsOneWidget);
    expect(find.textContaining('Local party'), findsOneWidget);
  });
}

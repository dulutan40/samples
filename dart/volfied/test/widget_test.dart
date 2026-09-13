import 'package:flutter_test/flutter_test.dart';
import 'package:volfied/src/app.dart';

void main() {
  testWidgets('shows the title screen', (tester) async {
    await tester.pumpWidget(const VolfiedApp());
    expect(find.text('VOLFIED'), findsOneWidget);
    expect(find.text('ENTER THE FIELD'), findsOneWidget);
  });
}

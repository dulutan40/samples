import 'package:flutter_test/flutter_test.dart';
import 'package:monster_hunt/src/app.dart';

void main() {
  testWidgets('shows the title screen', (tester) async {
    await tester.pumpWidget(const MonsterHuntApp());
    expect(find.text('MONSTER HUNT'), findsOneWidget);
    expect(find.text('ENTER THE FIELD'), findsOneWidget);
  });
}

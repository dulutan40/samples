import 'package:flutter_test/flutter_test.dart';
import 'package:last_to_tap/src/game/player_names.dart';

void main() {
  test('randomPlayerName is Player_ plus 6 digits', () {
    final name = randomPlayerName();
    expect(name, matches(RegExp(r'^Player_\d{6}$')));
  });

  test('uniqueRandomPlayerNames are unique', () {
    final names = uniqueRandomPlayerNames(8);
    expect(names.toSet().length, 8);
  });

  test('isPlayerNameTaken is case-insensitive and skips exceptIndex', () {
    final names = ['Player_111111', 'Ada', 'Bob'];
    expect(isPlayerNameTaken('ada', names), isTrue);
    expect(isPlayerNameTaken('Ada', names, exceptIndex: 1), isFalse);
    expect(isPlayerNameTaken('Carol', names), isFalse);
  });
}

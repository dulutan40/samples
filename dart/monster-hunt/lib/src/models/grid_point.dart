class GridPoint {
  const GridPoint(this.x, this.y);

  final int x;
  final int y;

  GridPoint operator +(GridPoint other) => GridPoint(x + other.x, y + other.y);

  @override
  bool operator ==(Object other) =>
      other is GridPoint && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => '($x,$y)';
}

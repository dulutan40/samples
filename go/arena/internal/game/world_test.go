package game

import "testing"

func TestAddAndRemovePlayer(t *testing.T) {
	w := NewWorld()
	p, ok := w.AddPlayer("a", "Ace")
	if !ok || p.Name != "Ace" {
		t.Fatalf("failed to add player")
	}
	if w.PlayerCount() != 1 {
		t.Fatalf("count=%d", w.PlayerCount())
	}
	w.RemovePlayer("a")
	if w.PlayerCount() != 0 {
		t.Fatalf("expected empty arena")
	}
}

func TestBulletHitsAndScores(t *testing.T) {
	w := NewWorld()
	attacker, _ := w.AddPlayer("a", "A")
	target, _ := w.AddPlayer("b", "B")

	w.mu.Lock()
	w.players["a"].X = 100
	w.players["a"].Y = 100
	w.players["b"].X = 140
	w.players["b"].Y = 100
	w.bullets = append(w.bullets, Bullet{
		ID: 1, Owner: "a", X: 120, Y: 100, VX: 200, VY: 0, TTL: 1,
	})
	w.mu.Unlock()

	for i := 0; i < 10; i++ {
		w.Step(0.05)
	}

	snap := w.Snapshot()
	var a, b *Player
	for i := range snap.Players {
		if snap.Players[i].ID == attacker.ID {
			a = &snap.Players[i]
		}
		if snap.Players[i].ID == target.ID {
			b = &snap.Players[i]
		}
	}
	if a == nil || b == nil {
		t.Fatal("missing players")
	}
	if b.HP >= MaxHP {
		t.Fatalf("target should take damage, hp=%d", b.HP)
	}
}

func TestMovementStaysInBounds(t *testing.T) {
	w := NewWorld()
	w.AddPlayer("a", "A")
	w.SetInput("a", Input{Left: true, Up: true})
	for i := 0; i < 200; i++ {
		w.Step(0.05)
	}
	snap := w.Snapshot()
	p := snap.Players[0]
	if p.X < PlayerR || p.Y < PlayerR || p.X > Width-PlayerR || p.Y > Height-PlayerR {
		t.Fatalf("out of bounds: (%v,%v)", p.X, p.Y)
	}
}

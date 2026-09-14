package game

import (
	"math"
	"sync"
	"time"
)

const (
	Width      = 900.0
	Height     = 640.0
	PlayerR    = 14.0
	BulletR    = 3.5
	MaxHP      = 100
	MoveSpeed  = 220.0
	BulletSpd  = 480.0
	FireCooldown = 220 * time.Millisecond
	BulletLife = 1.4
	TickRate   = 20
	MaxPlayers = 8
)

type Input struct {
	Up    bool    `json:"up"`
	Down  bool    `json:"down"`
	Left  bool    `json:"left"`
	Right bool    `json:"right"`
	AimX  float64 `json:"aimX"`
	AimY  float64 `json:"aimY"`
	Fire  bool    `json:"fire"`
}

type Player struct {
	ID     string  `json:"id"`
	Name   string  `json:"name"`
	X      float64 `json:"x"`
	Y      float64 `json:"y"`
	AimX   float64 `json:"aimX"`
	AimY   float64 `json:"aimY"`
	HP     int     `json:"hp"`
	Score  int     `json:"score"`
	Color  string  `json:"color"`
	Alive  bool    `json:"alive"`
	input  Input
	cooldown  time.Time
	respawnAt time.Time
}

type Bullet struct {
	ID     int     `json:"id"`
	Owner  string  `json:"owner"`
	X      float64 `json:"x"`
	Y      float64 `json:"y"`
	VX     float64 `json:"vx"`
	VY     float64 `json:"vy"`
	TTL    float64 `json:"-"`
}

type Snapshot struct {
	Players []Player `json:"players"`
	Bullets []Bullet `json:"bullets"`
	Width   float64  `json:"width"`
	Height  float64  `json:"height"`
	Tick    uint64   `json:"tick"`
}

type World struct {
	mu      sync.RWMutex
	players map[string]*Player
	bullets []Bullet
	tick    uint64
	nextID  int
	colors  []string
	colorI  int
}

func NewWorld() *World {
	return &World{
		players: make(map[string]*Player),
		colors: []string{
			"#3CE0C8", "#F4D35E", "#FF6B7A", "#5B93FF",
			"#E8B8FF", "#3DDC97", "#FF9F43", "#A0AEC0",
		},
	}
}

func (w *World) AddPlayer(id, name string) (*Player, bool) {
	w.mu.Lock()
	defer w.mu.Unlock()
	if len(w.players) >= MaxPlayers {
		return nil, false
	}
	if name == "" {
		name = "Pilot"
	}
	if len(name) > 16 {
		name = name[:16]
	}
	color := w.colors[w.colorI%len(w.colors)]
	w.colorI++
	p := &Player{
		ID:    id,
		Name:  name,
		X:     80 + float64(len(w.players)%4)*180,
		Y:     80 + float64(len(w.players)/4)*200,
		HP:    MaxHP,
		Color: color,
		Alive: true,
		AimX:  Width / 2,
		AimY:  Height / 2,
	}
	w.players[id] = p
	cp := *p
	return &cp, true
}

func (w *World) RemovePlayer(id string) {
	w.mu.Lock()
	defer w.mu.Unlock()
	delete(w.players, id)
	kept := w.bullets[:0]
	for _, b := range w.bullets {
		if b.Owner != id {
			kept = append(kept, b)
		}
	}
	w.bullets = kept
}

func (w *World) SetInput(id string, in Input) {
	w.mu.Lock()
	defer w.mu.Unlock()
	p, ok := w.players[id]
	if !ok {
		return
	}
	p.input = in
	p.AimX = in.AimX
	p.AimY = in.AimY
}

func (w *World) Step(dt float64) {
	w.mu.Lock()
	defer w.mu.Unlock()
	w.tick++
	now := time.Now()

	for _, p := range w.players {
		if !p.Alive {
			if now.After(p.respawnAt) {
				p.Alive = true
				p.HP = MaxHP
				p.X = 60 + float64(w.tick%7)*110
				p.Y = 60 + float64((w.tick/3)%5)*100
			}
			continue
		}

		dx, dy := 0.0, 0.0
		if p.input.Left {
			dx -= 1
		}
		if p.input.Right {
			dx += 1
		}
		if p.input.Up {
			dy -= 1
		}
		if p.input.Down {
			dy += 1
		}
		if dx != 0 || dy != 0 {
			len := math.Hypot(dx, dy)
			dx, dy = dx/len, dy/len
			p.X += dx * MoveSpeed * dt
			p.Y += dy * MoveSpeed * dt
		}
		p.X = clamp(p.X, PlayerR, Width-PlayerR)
		p.Y = clamp(p.Y, PlayerR, Height-PlayerR)

		if p.input.Fire && now.After(p.cooldown) {
			ax := p.AimX - p.X
			ay := p.AimY - p.Y
			dist := math.Hypot(ax, ay)
			if dist < 1 {
				ax, ay, dist = 1, 0, 1
			}
			ax, ay = ax/dist, ay/dist
			w.nextID++
			w.bullets = append(w.bullets, Bullet{
				ID:    w.nextID,
				Owner: p.ID,
				X:     p.X + ax*(PlayerR+6),
				Y:     p.Y + ay*(PlayerR+6),
				VX:    ax * BulletSpd,
				VY:    ay * BulletSpd,
				TTL:   BulletLife,
			})
			p.cooldown = now.Add(FireCooldown)
		}
	}

	aliveBullets := w.bullets[:0]
	for _, b := range w.bullets {
		b.X += b.VX * dt
		b.Y += b.VY * dt
		b.TTL -= dt
		if b.TTL <= 0 || b.X < 0 || b.Y < 0 || b.X > Width || b.Y > Height {
			continue
		}
		hit := false
		for _, p := range w.players {
			if !p.Alive || p.ID == b.Owner {
				continue
			}
			if math.Hypot(p.X-b.X, p.Y-b.Y) <= PlayerR+BulletR {
				p.HP -= 20
				hit = true
				if p.HP <= 0 {
					p.Alive = false
					p.HP = 0
					p.respawnAt = now.Add(2 * time.Second)
					if owner, ok := w.players[b.Owner]; ok {
						owner.Score++
					}
				}
				break
			}
		}
		if !hit {
			aliveBullets = append(aliveBullets, b)
		}
	}
	w.bullets = aliveBullets
}

func (w *World) Snapshot() Snapshot {
	w.mu.RLock()
	defer w.mu.RUnlock()
	players := make([]Player, 0, len(w.players))
	for _, p := range w.players {
		cp := *p
		players = append(players, cp)
	}
	bullets := append([]Bullet(nil), w.bullets...)
	if bullets == nil {
		bullets = []Bullet{}
	}
	return Snapshot{
		Players: players,
		Bullets: bullets,
		Width:   Width,
		Height:  Height,
		Tick:    w.tick,
	}
}

func (w *World) PlayerCount() int {
	w.mu.RLock()
	defer w.mu.RUnlock()
	return len(w.players)
}

func clamp(v, lo, hi float64) float64 {
	if v < lo {
		return lo
	}
	if v > hi {
		return hi
	}
	return v
}

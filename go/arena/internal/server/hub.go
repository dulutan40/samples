package server

import (
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"log"
	"net/http"
	"sync"
	"time"

	"github.com/dulutan40/samples/go/arena/internal/game"
	"github.com/gorilla/websocket"
)

var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool { return true },
}

type inbound struct {
	Type  string     `json:"type"`
	Name  string     `json:"name,omitempty"`
	Input game.Input `json:"input,omitempty"`
}

type outbound struct {
	Type    string         `json:"type"`
	You     string         `json:"you,omitempty"`
	Message string         `json:"message,omitempty"`
	State   *game.Snapshot `json:"state,omitempty"`
}

type client struct {
	id     string
	conn   *websocket.Conn
	send   chan []byte
	joined bool
}

type Hub struct {
	world   *game.World
	mu      sync.Mutex
	clients map[string]*client
}

func NewHub(world *game.World) *Hub {
	return &Hub{
		world:   world,
		clients: make(map[string]*client),
	}
}

func (h *Hub) Run() {
	ticker := time.NewTicker(time.Second / game.TickRate)
	defer ticker.Stop()
	for range ticker.C {
		h.world.Step(1.0 / game.TickRate)
		h.broadcastState()
	}
}

func (h *Hub) ServeWS(w http.ResponseWriter, r *http.Request) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Printf("upgrade: %v", err)
		return
	}
	id := newID()
	c := &client{
		id:   id,
		conn: conn,
		send: make(chan []byte, 64),
	}

	h.mu.Lock()
	h.clients[id] = c
	h.mu.Unlock()

	go c.writePump()
	h.readPump(c)
}

func (h *Hub) readPump(c *client) {
	defer func() {
		h.world.RemovePlayer(c.id)
		h.mu.Lock()
		delete(h.clients, c.id)
		h.mu.Unlock()
		close(c.send)
		_ = c.conn.Close()
	}()

	c.conn.SetReadLimit(4096)
	_ = c.conn.SetReadDeadline(time.Now().Add(90 * time.Second))
	c.conn.SetPongHandler(func(string) error {
		_ = c.conn.SetReadDeadline(time.Now().Add(90 * time.Second))
		return nil
	})

	for {
		_, data, err := c.conn.ReadMessage()
		if err != nil {
			return
		}
		_ = c.conn.SetReadDeadline(time.Now().Add(90 * time.Second))

		var msg inbound
		if err := json.Unmarshal(data, &msg); err != nil {
			continue
		}
		switch msg.Type {
		case "join":
			if c.joined {
				continue
			}
			if _, ok := h.world.AddPlayer(c.id, msg.Name); !ok {
				h.send(c, outbound{Type: "error", Message: "arena full"})
				return
			}
			c.joined = true
			h.send(c, outbound{Type: "welcome", You: c.id})
			log.Printf("player joined id=%s name=%q players=%d", c.id, msg.Name, h.world.PlayerCount())
		case "input":
			if c.joined {
				h.world.SetInput(c.id, msg.Input)
			}
		}
	}
}

func (c *client) writePump() {
	ticker := time.NewTicker(20 * time.Second)
	defer func() {
		ticker.Stop()
		_ = c.conn.Close()
	}()
	for {
		select {
		case msg, ok := <-c.send:
			_ = c.conn.SetWriteDeadline(time.Now().Add(10 * time.Second))
			if !ok {
				_ = c.conn.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}
			if err := c.conn.WriteMessage(websocket.TextMessage, msg); err != nil {
				return
			}
		case <-ticker.C:
			_ = c.conn.SetWriteDeadline(time.Now().Add(10 * time.Second))
			if err := c.conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}
		}
	}
}

func (h *Hub) broadcastState() {
	snap := h.world.Snapshot()
	payload, err := json.Marshal(outbound{
		Type:  "state",
		State: &snap,
	})
	if err != nil {
		return
	}
	h.mu.Lock()
	defer h.mu.Unlock()
	for _, c := range h.clients {
		if !c.joined {
			continue
		}
		select {
		case c.send <- payload:
		default:
			// Prefer dropping a frame over killing the socket.
			log.Printf("slow client frame drop id=%s", c.id)
		}
	}
}

func (h *Hub) send(c *client, msg outbound) {
	data, err := json.Marshal(msg)
	if err != nil {
		return
	}
	select {
	case c.send <- data:
	case <-time.After(2 * time.Second):
		log.Printf("failed to queue message type=%s id=%s", msg.Type, c.id)
	}
}

func newID() string {
	var b [8]byte
	if _, err := rand.Read(b[:]); err != nil {
		return hex.EncodeToString([]byte(time.Now().Format("150405.000000000")))
	}
	return hex.EncodeToString(b[:])
}

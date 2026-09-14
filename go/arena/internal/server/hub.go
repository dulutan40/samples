package server

import (
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
	Type    string        `json:"type"`
	You     string        `json:"you,omitempty"`
	Message string        `json:"message,omitempty"`
	State   game.Snapshot `json:"state,omitempty"`
}

type client struct {
	id   string
	conn *websocket.Conn
	send chan []byte
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
		return
	}
	id := r.URL.Query().Get("id")
	if id == "" {
		id = randomID()
	}
	c := &client{
		id:   id,
		conn: conn,
		send: make(chan []byte, 16),
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

	_ = c.conn.SetReadDeadline(time.Now().Add(60 * time.Second))
	c.conn.SetPongHandler(func(string) error {
		_ = c.conn.SetReadDeadline(time.Now().Add(60 * time.Second))
		return nil
	})

	for {
		_, data, err := c.conn.ReadMessage()
		if err != nil {
			return
		}
		var msg inbound
		if err := json.Unmarshal(data, &msg); err != nil {
			continue
		}
		switch msg.Type {
		case "join":
			if _, ok := h.world.AddPlayer(c.id, msg.Name); !ok {
				h.send(c, outbound{Type: "error", Message: "arena full"})
				return
			}
			h.send(c, outbound{Type: "welcome", You: c.id})
		case "input":
			h.world.SetInput(c.id, msg.Input)
		}
	}
}

func (c *client) writePump() {
	ticker := time.NewTicker(30 * time.Second)
	defer func() {
		ticker.Stop()
		_ = c.conn.Close()
	}()
	for {
		select {
		case msg, ok := <-c.send:
			_ = c.conn.SetWriteDeadline(time.Now().Add(5 * time.Second))
			if !ok {
				_ = c.conn.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}
			if err := c.conn.WriteMessage(websocket.TextMessage, msg); err != nil {
				return
			}
		case <-ticker.C:
			_ = c.conn.SetWriteDeadline(time.Now().Add(5 * time.Second))
			if err := c.conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}
		}
	}
}

func (h *Hub) broadcastState() {
	payload, err := json.Marshal(outbound{
		Type:  "state",
		State: h.world.Snapshot(),
	})
	if err != nil {
		return
	}
	h.mu.Lock()
	defer h.mu.Unlock()
	for _, c := range h.clients {
		select {
		case c.send <- payload:
		default:
			log.Printf("dropping slow client %s", c.id)
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
	default:
	}
}

func randomID() string {
	return time.Now().Format("150405.000") + "-" + confusables(4)
}

func confusables(n int) string {
	const alphabet = "abcdefghjkmnpqrstuvwxyz23456789"
	b := make([]byte, n)
	now := time.Now().UnixNano()
	for i := 0; i < n; i++ {
		b[i] = alphabet[(now+int64(i*17))%int64(len(alphabet))]
		now = now*1103515245 + 12345
	}
	return string(b)
}

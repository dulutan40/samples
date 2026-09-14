package main

import (
	"embed"
	"flag"
	"io/fs"
	"log"
	"net/http"

	"github.com/dulutan40/samples/go/arena/internal/game"
	"github.com/dulutan40/samples/go/arena/internal/server"
)

//go:embed all:web
var webFS embed.FS

func main() {
	addr := flag.String("addr", ":3470", "http listen address")
	flag.Parse()

	world := game.NewWorld()
	hub := server.NewHub(world)
	go hub.Run()

	static, err := fs.Sub(webFS, "web")
	if err != nil {
		log.Fatal(err)
	}

	mux := http.NewServeMux()
	mux.Handle("/", http.FileServer(http.FS(static)))
	mux.HandleFunc("/ws", hub.ServeWS)

	log.Printf("arena listening on http://localhost%s", *addr)
	log.Printf("open that URL in two browser tabs to duel")
	if err := http.ListenAndServe(*addr, mux); err != nil {
		log.Fatal(err)
	}
}

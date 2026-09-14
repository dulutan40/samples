(() => {
  const canvas = document.getElementById("c");
  const ctx = canvas.getContext("2d");
  const lobby = document.getElementById("lobby");
  const hud = document.getElementById("hud");
  const statusEl = document.getElementById("status");
  const boardEl = document.getElementById("scoreboard");
  const nameInput = document.getElementById("name");
  const joinBtn = document.getElementById("join");

  let ws = null;
  let you = null;
  let joined = false;
  let state = { players: [], bullets: [], width: 900, height: 640 };
  const keys = new Set();
  let aim = { x: 450, y: 320 };
  let fire = false;

  function wsURL() {
    const proto = location.protocol === "https:" ? "wss" : "ws";
    return `${proto}://${location.host}/ws`;
  }

  function setPlayingUI() {
    lobby.hidden = true;
    hud.hidden = false;
    canvas.hidden = false;
  }

  function setLobbyUI(message) {
    statusEl.textContent = message;
    lobby.hidden = false;
    canvas.hidden = true;
    joined = false;
    you = null;
  }

  function join() {
    if (ws) {
      ws.onclose = null;
      try { ws.close(); } catch (_) {}
      ws = null;
    }

    statusEl.textContent = "connecting…";
    const socket = new WebSocket(wsURL());
    ws = socket;

    socket.onopen = () => {
      socket.send(JSON.stringify({
        type: "join",
        name: nameInput.value.trim() || "Pilot",
      }));
      setPlayingUI();
      statusEl.textContent = "joining…";
    };

    socket.onmessage = (ev) => {
      let msg;
      try {
        msg = JSON.parse(ev.data);
      } catch (_) {
        return;
      }
      if (msg.type === "welcome") {
        you = msg.you;
        joined = true;
        statusEl.textContent = "in arena — WASD move, mouse aim, click/space fire";
      }
      if (msg.type === "state" && msg.state) {
        state = msg.state;
        if (!joined) {
          joined = true;
          statusEl.textContent = "in arena";
        }
      }
      if (msg.type === "error") {
        statusEl.textContent = msg.message || "error";
      }
    };

    socket.onerror = () => {
      statusEl.textContent = "connection error";
    };

    socket.onclose = () => {
      if (ws === socket) {
        setLobbyUI("disconnected — enter again");
      }
    };
  }

  joinBtn.addEventListener("click", join);
  nameInput.addEventListener("keydown", (e) => {
    if (e.key === "Enter") join();
  });

  window.addEventListener("keydown", (e) => {
    keys.add(e.key.toLowerCase());
    if (e.code === "Space") {
      e.preventDefault();
      fire = true;
    }
  });
  window.addEventListener("keyup", (e) => {
    keys.delete(e.key.toLowerCase());
    if (e.code === "Space") fire = false;
  });
  canvas.addEventListener("mousemove", (e) => {
    const rect = canvas.getBoundingClientRect();
    const sx = canvas.width / rect.width;
    const sy = canvas.height / rect.height;
    aim.x = (e.clientX - rect.left) * sx;
    aim.y = (e.clientY - rect.top) * sy;
  });
  canvas.addEventListener("mousedown", () => { fire = true; });
  window.addEventListener("mouseup", () => { fire = false; });

  setInterval(() => {
    if (!ws || ws.readyState !== WebSocket.OPEN || !joined) return;
    ws.send(JSON.stringify({
      type: "input",
      input: {
        up: keys.has("w") || keys.has("arrowup"),
        down: keys.has("s") || keys.has("arrowdown"),
        left: keys.has("a") || keys.has("arrowleft"),
        right: keys.has("d") || keys.has("arrowright"),
        aimX: aim.x,
        aimY: aim.y,
        fire,
      },
    }));
  }, 50);

  function draw() {
    ctx.fillStyle = "#050608";
    ctx.fillRect(0, 0, canvas.width, canvas.height);

    ctx.strokeStyle = "#1a2030";
    ctx.lineWidth = 1;
    for (let x = 0; x < canvas.width; x += 50) {
      ctx.beginPath();
      ctx.moveTo(x, 0);
      ctx.lineTo(x, canvas.height);
      ctx.stroke();
    }
    for (let y = 0; y < canvas.height; y += 50) {
      ctx.beginPath();
      ctx.moveTo(0, y);
      ctx.lineTo(canvas.width, y);
      ctx.stroke();
    }

    for (const b of state.bullets || []) {
      ctx.fillStyle = "#f4d35e";
      ctx.beginPath();
      ctx.arc(b.x, b.y, 3.5, 0, Math.PI * 2);
      ctx.fill();
    }

    const rows = [];
    for (const p of state.players || []) {
      rows.push(`${p.name} ${p.score}`);
      if (!p.alive) continue;
      ctx.fillStyle = p.color;
      ctx.beginPath();
      ctx.arc(p.x, p.y, 14, 0, Math.PI * 2);
      ctx.fill();

      const ang = Math.atan2(p.aimY - p.y, p.aimX - p.x);
      ctx.strokeStyle = p.color;
      ctx.lineWidth = 3;
      ctx.beginPath();
      ctx.moveTo(p.x, p.y);
      ctx.lineTo(p.x + Math.cos(ang) * 22, p.y + Math.sin(ang) * 22);
      ctx.stroke();

      ctx.fillStyle = "#e8edf7";
      ctx.font = "12px monospace";
      ctx.fillText(p.name, p.x - 16, p.y - 20);

      ctx.fillStyle = "#2a3144";
      ctx.fillRect(p.x - 16, p.y + 18, 32, 4);
      ctx.fillStyle = "#3ce0c8";
      ctx.fillRect(p.x - 16, p.y + 18, 32 * (p.hp / 100), 4);

      if (you && p.id === you) {
        ctx.strokeStyle = "#ffffff";
        ctx.lineWidth = 1.5;
        ctx.beginPath();
        ctx.arc(p.x, p.y, 18, 0, Math.PI * 2);
        ctx.stroke();
      }
    }
    boardEl.textContent = rows.sort().join(" · ") || "waiting for pilots…";
    requestAnimationFrame(draw);
  }
  draw();
})();

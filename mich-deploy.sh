#!/bin/bash
if [ -z "$BASH_VERSION" ]; then exec bash "$0" "$@"; fi
set -euo pipefail
IFS=$'\n\t'
clear

# ─────────────────────────────────────────────
# 🛡️ mich Discord Bot Hosting Environment + Web UI
# Supports: discord.js (JavaScript) & discord.py (Python)
# Features: Auto Restart, System Monitoring Web UI
# By: mich | github.com/m1chtv
# ─────────────────────────────────────────────

### 📁 Directory Setup ###
PROJECT_DIR="$HOME/discord-bots"
BOTS_DIR="$PROJECT_DIR/bots"
LOGS_DIR="$PROJECT_DIR/logs"
UI_DIR="$PROJECT_DIR/ui"

mkdir -p "$BOTS_DIR" "$LOGS_DIR" "$UI_DIR"

### 🌐 Banner ###
echo -e "\n\e[35m🔧 mich Discord Bot Hosting Setup\e[0m"
echo "-----------------------------------------"
echo "Location: $PROJECT_DIR"
echo "Bots Folder: $BOTS_DIR"
echo "Logs Folder: $LOGS_DIR"
echo "UI: http://localhost:3000"
echo "-----------------------------------------"

### 🧠 Detect Existing Bots ###
BOT_COUNT=$(pm2 jlist | grep -c "$BOTS_DIR" || true)
if [[ $BOT_COUNT -gt 0 ]]; then
  echo "⚠️  Bot environment already set up."
  echo "1) Add a new bot"
  echo "2) Edit existing bot"
  echo "3) Remove/Stop a bot"
  echo "4) Exit"
  read -rp "Select option [1/2/3/4]: " OPTION
else
  OPTION=1
fi

### 📦 Dependencies ###
echo -e "\n📦 Installing dependencies..."
sudo apt update -y

DEPS=(curl git ufw unzip python3 python3-pip net-tools build-essential)
for pkg in "${DEPS[@]}"; do
  dpkg -s "$pkg" &>/dev/null || sudo apt install -y "$pkg"
done

if ! command -v node &>/dev/null; then
  echo "⬇️ Installing Node.js..."
  curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
  sudo apt install -y nodejs
fi

if ! command -v pm2 &>/dev/null; then
  echo "⬇️ Installing PM2..."
  sudo npm install -g pm2
fi

sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow 80
sudo ufw allow https
sudo ufw allow 443
sudo ufw allow OpenSSH
sudo ufw allow 3000/tcp
sudo ufw --force enable

### 🚧 Bot Setup ###
if [[ "$OPTION" == "1" ]]; then
  while true; do
    echo -e "\n🧠 Select bot type:"
    echo "1) discord.js (JavaScript)"
    echo "2) discord.py (Python)"
    read -rp "Enter option [1/2]: " BOT_TYPE
    [[ "$BOT_TYPE" =~ ^[12]$ ]] && break || echo "❌ Invalid input."
  done

  read -rp "Bot name: " BOT_NAME
  BOT_NAME=$(echo "$BOT_NAME" | tr -cd '[:alnum:]_-')

  if [[ -z "$BOT_NAME" || -d "$BOTS_DIR/$BOT_NAME" ]]; then
    echo "❌ Invalid or duplicate bot name."
    exit 1
  fi

  BOT_FOLDER="$BOTS_DIR/$BOT_NAME"
  mkdir -p "$BOT_FOLDER"
  echo "📂 Upload your bot code to: $BOT_FOLDER"
  read -n 1 -s -rp "Press any key after upload to continue..."

  cd "$BOT_FOLDER"
  clear

  if [[ "$BOT_TYPE" == "1" ]]; then
    [[ ! -f index.js ]] && echo "❌ index.js not found." && exit 1
    [[ -f package.json ]] && npm install || echo "⚠️ No package.json found."
    pm2 start index.js --name "$BOT_NAME" --log "$LOGS_DIR/$BOT_NAME.log"
  else
    [[ ! -f main.py ]] && echo "❌ main.py not found." && exit 1
    [[ -f requirements.txt ]] && pip3 install -r requirements.txt || echo "⚠️ No requirements.txt found."
    pm2 start "python3 main.py" --name "$BOT_NAME" --log "$LOGS_DIR/$BOT_NAME.log"
  fi

  pm2 startup
  pm2 save
  clear

  echo "✅ Bot '$BOT_NAME' added and running."

elif [[ "$OPTION" == "2" ]]; then
  echo "🛠 Available Bots:"
  ls -1 "$BOTS_DIR"
  read -rp "Bot name to edit: " BOT_NAME
  BOT_FOLDER="$BOTS_DIR/$BOT_NAME"
  [[ ! -d "$BOT_FOLDER" ]] && echo "❌ Bot not found" && exit 1

  echo "Opening folder: $BOT_FOLDER"
  read -n 1 -s -rp "Make your changes then press any key to restart..."

  if pm2 list | grep -q "$BOT_NAME"; then
    pm2 restart "$BOT_NAME"
    echo "♻️ Bot '$BOT_NAME' restarted."
  else
    echo "❌ Bot is not running."
    exit 1
  fi

elif [[ "$OPTION" == "3" ]]; then
  echo "🗑 Available Bots:"
  ls -1 "$BOTS_DIR"
  read -rp "Bot name to remove/stop: " BOT_NAME
  BOT_FOLDER="$BOTS_DIR/$BOT_NAME"
  [[ ! -d "$BOT_FOLDER" ]] && echo "❌ Bot not found" && exit 1

  echo "1) Stop bot"
  echo "2) Delete bot completely"
  read -rp "Choose [1/2]: " CHOICE

  if [[ "$CHOICE" == "1" ]]; then
    pm2 stop "$BOT_NAME" && echo "⏹ Bot stopped."
  elif [[ "$CHOICE" == "2" ]]; then
    pm2 delete "$BOT_NAME"
    rm -rf "$BOT_FOLDER"
    rm -f "$LOGS_DIR/$BOT_NAME.log"
    echo "🗑 Bot deleted."
  else
    echo "❌ Invalid option."
    exit 1
  fi

else
  echo "👋 Exiting..."
  exit 0
fi

### 📊 Monitoring UI ###
cd "$UI_DIR"

if [[ ! -d node_modules ]]; then
  npm init -y &>/dev/null
  npm install express systeminformation cors pm2 express-session body-parser --save
fi

cat > index.js << 'EOF'
const express = require("express");
const si = require("systeminformation");
const fs = require("fs");
const os = require("os");
const cors = require("cors");
const pm2 = require("pm2");
const session = require("express-session");
const bodyParser = require("body-parser");
const path = require("path");

const app = express();
const PORT = 3000;
const LOG_DIR = `${os.homedir()}/discord-bots/logs`;
const ADMIN_USER = "admin";
const ADMIN_PASS = "admin";

app.use(cors());
app.use(bodyParser.urlencoded({ extended: false }));
app.use(session({
  secret: "mich_super_secret",
  resave: false,
  saveUninitialized: true,
  cookie: { maxAge: 3600000 }
}));

function authOnly(req, res, next) {
  if (req.session.loggedIn) return next();
  return res.redirect("/login");
}

app.get("/login", (req, res) => {
  res.sendFile(path.join(__dirname, "public", "login.html"));
});

app.post("/login", (req, res) => {
  const { username, password } = req.body;
  if (username === ADMIN_USER && password === ADMIN_PASS) {
    req.session.loggedIn = true;
    return res.redirect("/");
  }
  res.send("<p>❌ Login failed. <a href='/login'>Try again</a></p>");
});

app.use("/", authOnly, express.static("public"));

app.get("/logout", (req, res) => {
  req.session.destroy(() => res.redirect("/login"));
});

app.get("/api/status", authOnly, async (_, res) => {
  try {
    const [cpu, mem, fs, net] = await Promise.all([
      si.currentLoad(),
      si.mem(),
      si.fsSize(),
      si.networkStats()
    ]);

    pm2.connect(err => {
      if (err) return res.status(500).json({ error: "PM2 connection failed", details: err.message });

      pm2.list((err, list) => {
        pm2.disconnect();
        if (err) return res.status(500).json({ error: "PM2 list error", details: err.message });

        const processes = list.map(proc => ({
          name: proc.name,
          pm_id: proc.pm_id,
          cpu: proc.monit.cpu,
          memory: (proc.monit.memory / mem.total) * 100
        }));

        res.json({ cpu, mem, fs, net, processes });
      });
    });
  } catch (e) {
    res.status(500).json({ error: "Monitoring error", details: e.message });
  }
});

app.get("/api/logs/:bot", authOnly, async (req, res) => {
  try {
    const bot = req.params.bot;
    const logFile = `${LOG_DIR}/${bot}.log`;
    const logs = fs.existsSync(logFile)
      ? fs.readFileSync(logFile, "utf-8").split("\n").slice(-50).join("\n")
      : "❌ Log file not found.";

    pm2.connect(err => {
      if (err) return res.status(500).json({ error: "PM2 connection failed" });

      pm2.list((err, list) => {
        pm2.disconnect();
        if (err) return res.status(500).json({ error: "PM2 list error" });

        const proc = list.find(p => p.name === bot);
        if (!proc) return res.status(404).json({ error: "Bot not found in PM2" });

        res.json({
          cpu: proc.monit.cpu,
          ram: (proc.monit.memory / os.totalmem()) * 100,
          logs
        });
      });
    });
  } catch (err) {
    res.status(500).json({ error: "Log fetch error", details: err.message });
  }
});


app.listen(PORT, "0.0.0.0", () => {
  console.log(`🔐 Panel running: http://localhost:${PORT}`);
});
EOF

mkdir -p public
cat > public/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en" class="scroll-smooth">

<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>michBot Panel</title>
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css">
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
  <script src="https://cdn.tailwindcss.com"></script>
</head>

<body class="bg-zinc-900 text-white font-sans">

  <!-- Navbar -->
  <nav class="navbar navbar-dark bg-dark px-4 mb-4">
    <span class="navbar-brand mb-0 h1">🧠 Mich Panel</span>
    <div>
      <a href="https://github.com/m1chtv" target="_blank" class="text-white me-3"><i class="fab fa-github"></i>
        GitHub</a>
      <a href="https://m1ch.ir" target="_blank" class="text-white"><i class="fas fa-globe"></i> Website</a>
    </div>
  </nav>

  <div class="container-fluid">
    <div class="row text-center mb-4">
      <div class="col-md-4 mb-3">
        <div class="bg-gradient-to-r from-blue-600 to-cyan-500 rounded-2xl p-4 shadow">
          <h5><i class="fas fa-microchip"></i> CPU Usage</h5>
          <p id="cpuUsage" class="text-2xl font-bold">--%</p>
        </div>
      </div>
      <div class="col-md-4 mb-3">
        <div class="bg-gradient-to-r from-green-600 to-emerald-400 rounded-2xl p-4 shadow">
          <h5><i class="fas fa-memory"></i> RAM Usage</h5>
          <p id="ramUsage" class="text-2xl font-bold">--%</p>
        </div>
      </div>
      <div class="col-md-4 mb-3">
        <div class="bg-gradient-to-r from-indigo-600 to-purple-500 rounded-2xl p-4 shadow">
          <h5><i class="fas fa-network-wired"></i> Network</h5>
          <p id="netStats" class="text-lg">--</p>
        </div>
      </div>
    </div>

    <div class="bg-zinc-800 p-4 rounded shadow mb-4">
      <h5><i class="fas fa-robot"></i> Hosted Bots</h5>
      <ul id="botList" class="list-group list-group-flush bg-transparent"></ul>
    </div>

    <div id="botDetail" class="hidden">
      <div class="row">
        <div class="col-md-6 mb-3">
          <div class="bg-zinc-800 p-3 rounded shadow">
            <h6>CPU & RAM Usage</h6>
            <p id="botCpu">CPU: --%</p>
            <p id="botRam">RAM: --%</p>
          </div>
        </div>
        <div class="col-md-6 mb-3">
          <div class="bg-zinc-800 p-3 rounded shadow">
            <h6>Logs</h6>
            <pre id="botLogs" class="text-sm overflow-y-auto max-h-64 bg-black rounded p-2"></pre>
          </div>
        </div>
      </div>
    </div>
  </div>

  <script>
    let selectedBot = null;

    async function fetchStats() {
      try {
        const res = await fetch('/api/status');
        const data = await res.json();

        document.getElementById("cpuUsage").textContent =
          data.cpu && typeof data.cpu.currentload === 'number'
            ? data.cpu.currentload.toFixed(1) + "%"
            : "--%";

        function formatBytes(bytes) {
          if (typeof bytes !== "number" || isNaN(bytes)) return "--";
          if (bytes > 1024 * 1024) return (bytes / 1024 / 1024).toFixed(1) + " MB/s";
          if (bytes > 1024) return (bytes / 1024).toFixed(1) + " KB/s";
          return bytes.toFixed(1) + " B/s";
        }


        function formatBytes(bytes) {
          if (bytes > 1024 * 1024) return (bytes / 1024 / 1024).toFixed(1) + " MB/s";
          if (bytes > 1024) return (bytes / 1024).toFixed(1) + " KB/s";
          return bytes.toFixed(1) + " B/s";
        }

        document.getElementById("netStats").textContent =
          data?.net?.length
            ? `↑ ${formatBytes(data.net[0].tx_sec)} ↓ ${formatBytes(data.net[0].rx_sec)}`
            : "--";


        const botListEl = document.getElementById("botList");
        botListEl.innerHTML = '';
        data.processes.forEach(proc => {
          const li = document.createElement("li");
          li.className = "list-group-item bg-dark text-white cursor-pointer";
          li.innerHTML = `<b>${proc.name}</b> - ${proc.cpu.toFixed(1)}% CPU, ${proc.memory.toFixed(1)}% RAM`;
          li.onclick = () => selectBot(proc.name);
          botListEl.appendChild(li);
        });



        if (selectedBot) fetchBotDetails(selectedBot);
      } catch (err) {
        console.error('❌ Error fetching stats:', err);
      }
    }

    async function selectBot(name) {
      selectedBot = name;
      document.getElementById("botDetail").classList.remove("hidden");
      fetchBotDetails(name);
    }

    async function fetchBotDetails(name) {
      try {
        const res = await fetch(`/api/logs/${name}`);
        const data = await res.json();
        document.getElementById("botCpu").textContent = `CPU: ${data.cpu?.toFixed(1) ?? '0.0'}%`;
        document.getElementById("botRam").textContent = `RAM: ${data.ram?.toFixed(1) ?? '0.0'}%`;
        document.getElementById("botLogs").textContent = data.logs || "No logs available.";

      } catch (err) {
        document.getElementById("botLogs").textContent = "❌ Failed to load logs.";
      }
    }

    fetchStats();
    setInterval(fetchStats, 30000);
  </script>

</body>

</html>
EOF

cat > public/login.html << 'EOF'
<!DOCTYPE html>
<html lang="en" class="bg-zinc-900 text-white">

<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Login | michBot Panel</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet" />
  <style>
    body {
      background: linear-gradient(145deg, #0f0f0f, #1f1f1f);
    }

    .login-card {
      background-color: #18181b;
      border: 1px solid #2e2e2e;
      border-radius: 1rem;
      box-shadow: 0 0 30px rgba(0, 0, 0, 0.6);
      padding: 2.5rem;
      transition: all 0.3s ease;
    }

    .login-card:hover {
      transform: scale(1.01);
      box-shadow: 0 0 50px rgba(0, 102, 255, 0.3);
    }

    .form-control {
      background-color: #2c2c2e;
      color: white;
      border: 1px solid #444;
    }

    .form-control:focus {
      background-color: #2c2c2e;
      border-color: #0d6efd;
      box-shadow: none;
      color: white;
    }

    .btn-primary {
      background-color: #0d6efd;
      border: none;
    }

    .btn-primary:hover {
      background-color: #0b5ed7;
    }

    ::placeholder {
      color: #aaa;
    }

    .text-glow {
      color: #ffffff;
      text-shadow: 0 0 8px #0d6efd;
    }
  </style>
</head>

<body class="d-flex justify-content-center align-items-center vh-100">
  <form method="POST" action="/login" class="login-card w-100" style="max-width: 400px;">
    <h3 class="mb-4 text-center text-glow">🔐 Admin Login</h3>
    <div class="mb-3">
      <label for="username" class="form-label visually-hidden">Username</label>
      <input type="text" name="username" id="username" class="form-control" placeholder="Username" required />
    </div>
    <div class="mb-4">
      <label for="password" class="form-label visually-hidden">Password</label>
      <input type="password" name="password" id="password" class="form-control" placeholder="Password" required />
    </div>
    <button type="submit" class="btn btn-primary w-100">Login</button>
  </form>
</body>

</html>
EOF

clear
pm2 describe monitor-ui &>/dev/null || pm2 start index.js --name monitor-ui
pm2 save

### ℹ️ Summary ###
echo -e "\n📈 Monitor via:"
echo "➡️ pm2 list"
echo "➡️ pm2 logs <bot-name>"
echo "➡️ http://localhost:3000"
echo "✅ Setup complete."
exit 0

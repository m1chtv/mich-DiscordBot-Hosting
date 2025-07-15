#!/bin/bash

# ─────────────────────────────────────────────
# 🛡️ Secure Discord Bot Hosting Environment + Web UI
# Supports: discord.js (DJS) & discord.py (DPY)
# Auto Restart + System Monitoring via Web
# By: mich | github.com/m1chtv
# ─────────────────────────────────────────────

set -euo pipefail
IFS=$'\n\t'

### 📁 Directory Setup ###
PROJECT_DIR="$HOME/discord-bots"
BOTS_DIR="$PROJECT_DIR/bots"
LOGS_DIR="$PROJECT_DIR/logs"
UI_DIR="$PROJECT_DIR/ui"

mkdir -p "$BOTS_DIR" "$LOGS_DIR" "$UI_DIR"

### 🌐 Display Banner ###
echo -e "\n\e[35m🔧 Secure Discord Bot Hosting Setup\e[0m"
echo "-----------------------------------------"
echo "Location: $PROJECT_DIR"
echo "Bots Folder: $BOTS_DIR"
echo "Logs Folder: $LOGS_DIR"
echo "UI: http://<your-server-ip>:3000"
echo "-----------------------------------------"

### 🔍 Detect Existing Setup ###
if pm2 list | grep -qw discord-bot; then
  echo "⚠️  A Discord bot environment already exists."
  echo "1) Add a new bot"
  echo "2) Edit existing bot"
  read -rp "Select option [1/2]: " OPTION
else
  echo "🔄 Setting up new bot..."
  OPTION=1
fi

### 📦 Dependency Check & Install ###
echo -e "\n📦 Checking dependencies..."
sudo apt update -y
sudo apt install -y curl git ufw unzip python3 python3-pip net-tools build-essential

if ! command -v node &>/dev/null; then
  echo "⬇️ Installing Node.js..."
  curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
  sudo apt install -y nodejs
fi

if ! command -v pm2 &>/dev/null; then
  echo "⬇️ Installing PM2..."
  sudo npm install -g pm2
fi

### 🚧 Start Flow Based on Selection ###
if [[ "$OPTION" == "1" ]]; then
  echo -e "\n🧠 Select bot type:"
  echo "1) discord.js (JavaScript)"
  echo "2) discord.py (Python)"
  read -rp "Enter option [1/2]: " BOT_TYPE

  read -rp "Bot name: " BOT_NAME
  if [[ -z "$BOT_NAME" ]]; then
    echo "❌ Bot name cannot be empty!"
    exit 1
  fi

  # Sanitize BOT_NAME: remove spaces and special chars (optional)
  BOT_NAME="${BOT_NAME//[^a-zA-Z0-9_-]/}"

  BOT_FOLDER="$BOTS_DIR/$BOT_NAME"

  if [[ -d "$BOT_FOLDER" ]]; then
    echo "❌ Bot with that name already exists!"
    exit 1
  fi

  mkdir -p "$BOT_FOLDER"
  echo "📂 Created folder: $BOT_FOLDER"

  echo "⬆️ Please upload your bot code to: $BOT_FOLDER"
  read -n 1 -s -rp "Press any key to continue..."

  if [[ "$BOT_TYPE" == "1" ]]; then
    cd "$BOT_FOLDER"
    if [[ -f package.json ]]; then
      npm install || { echo "❌ npm install failed"; exit 1; }
    else
      echo "⚠️ package.json not found, skipping npm install."
    fi
    echo "🚀 Starting $BOT_NAME with PM2..."
    pm2 start index.js --name "$BOT_NAME" --log "$LOGS_DIR/$BOT_NAME.log"

  elif [[ "$BOT_TYPE" == "2" ]]; then
    cd "$BOT_FOLDER"
    if [[ -f requirements.txt ]]; then
      pip3 install -r requirements.txt || { echo "❌ pip install failed"; exit 1; }
    else
      echo "⚠️ requirements.txt not found, skipping pip install."
    fi
    echo "🚀 Starting $BOT_NAME with PM2..."
    pm2 start "python3 main.py" --name "$BOT_NAME" --log "$LOGS_DIR/$BOT_NAME.log"
  else
    echo "❌ Invalid selection"
    exit 1
  fi

  pm2 save
  pm2 startup | sudo tee /dev/null | bash
  echo "✅ Bot $BOT_NAME added successfully!"

elif [[ "$OPTION" == "2" ]]; then
  echo "🛠 Available Bots:"
  ls -1 "$BOTS_DIR"
  read -rp "Bot name to edit: " BOT_NAME

  BOT_FOLDER="$BOTS_DIR/$BOT_NAME"
  if [[ ! -d "$BOT_FOLDER" ]]; then
    echo "❌ Bot not found"
    exit 1
  fi

  echo "Opening folder: $BOT_FOLDER"
  read -n 1 -s -rp "Make your changes then press any key to restart bot..."

  pm2 restart "$BOT_NAME"
  echo "♻️ Bot restarted"
else
  echo "❌ Invalid option"
  exit 1
fi

### 📊 Start Monitoring UI ###
echo -e "\n📊 Installing Monitoring UI (Node.js Express)..."
cd "$UI_DIR"

if [[ ! -f package.json ]]; then
  npm init -y &>/dev/null
  npm install express systeminformation cors --save
fi

cat > index.js << 'EOF'
const express = require("express");
const si = require("systeminformation");
const app = express();
const PORT = 3000;
app.use(require("cors")());

app.get("/api/status", async (req, res) => {
  try {
    const [cpu, mem, fs, net, processes] = await Promise.all([
      si.currentLoad(),
      si.mem(),
      si.fsSize(),
      si.networkStats(),
      si.processes()
    ]);
    res.json({ cpu, mem, fs, net, processes });
  } catch (e) {
    res.status(500).json({ error: "Monitoring error", details: e.message });
  }
});

app.use(express.static("public"));
app.listen(PORT, () => console.log(`🌐 Monitor running on http://localhost:${PORT}`));
EOF

mkdir -p public
cat > public/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <title>Bot Monitor</title>
  <style>
    body { font-family: monospace; background: #111; color: #0f0; padding: 2rem; }
    h1 { color: #fff; }
    .stat { margin-bottom: 1rem; }
    .label { color: #ccc; }
  </style>
</head>
<body>
  <h1>📡 Discord Bot Monitor</h1>
  <div id="monitor"></div>
  <script>
    async function fetchData() {
      try {
        const res = await fetch('/api/status');
        const data = await res.json();
        document.getElementById('monitor').innerHTML = '<pre>' + JSON.stringify(data, null, 2) + '</pre>';
      } catch (err) {
        document.getElementById('monitor').innerText = '❌ Error loading monitor: ' + err;
      }
    }
    fetchData();
    setInterval(fetchData, 5000);
  </script>
</body>
</html>
EOF

pm2 start index.js --name monitor-ui
pm2 save

### 📡 Monitoring Summary ###
echo -e "\n📈 To monitor bots:"
echo "➡️ pm2 list"
echo "➡️ pm2 logs <bot-name>"
echo "➡️ http://<server-ip>:3000"
echo "➡️ Restart server = bots auto start 🔁"

echo "✅ Setup finished successfully."
exit 0

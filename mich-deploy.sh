#!/bin/bash

# ─────────────────────────────────────────────
# 🛡️ Secure Discord Bot Hosting Environment + Web UI
# Supports: discord.js (DJS) & discord.py (DPY)
# Auto Restart + System Monitoring via Web
# By: mich | github.com/yourname
# ─────────────────────────────────────────────

set -e

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
if pm2 list | grep -q discord-bot; then
  echo "⚠️  A Discord bot environment already exists."
  echo "1) Add a new bot"
  echo "2) Edit existing bot"
  read -p "Select option [1/2]: " OPTION
else
  echo "🔄 Setting up new bot..."
  OPTION=1
fi

### 📦 Dependency Check & Install ###
echo "\n📦 Checking dependencies..."
sudo apt update -y
sudo apt install -y curl git ufw unzip python3 python3-pip net-tools

if ! command -v node &> /dev/null; then
  echo "⬇️ Installing Node.js..."
  curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
  sudo apt install -y nodejs
fi

if ! command -v pm2 &> /dev/null; then
  echo "⬇️ Installing PM2..."
  sudo npm install -g pm2
fi

### 🚧 Start Flow Based on Selection ###
if [[ "$OPTION" == "1" ]]; then
  echo -e "\n🧠 Select bot type:"
  echo "1) discord.js (JavaScript)"
  echo "2) discord.py (Python)"
  read -p "Enter option [1/2]: " BOT_TYPE

  read -p "Bot name: " BOT_NAME
  BOT_FOLDER="$BOTS_DIR/$BOT_NAME"

  if [[ -d "$BOT_FOLDER" ]]; then
    echo "❌ Bot with that name already exists!"
    exit 1
  fi

  mkdir -p "$BOT_FOLDER"
  echo "📂 Created folder: $BOT_FOLDER"

  echo "⬆️ Please upload your bot code to: $BOT_FOLDER"
  echo "Then press any key to continue."
  read -n 1 -s

  if [[ "$BOT_TYPE" == "1" ]]; then
    cd "$BOT_FOLDER"
    npm install || { echo "❌ npm install failed"; exit 1; }
    echo "🚀 Starting $BOT_NAME with PM2..."
    pm2 start index.js --name "$BOT_NAME" --log "$LOGS_DIR/$BOT_NAME.log"

  elif [[ "$BOT_TYPE" == "2" ]]; then
    cd "$BOT_FOLDER"
    pip3 install -r requirements.txt || { echo "❌ pip install failed"; exit 1; }
    echo "🚀 Starting $BOT_NAME with PM2..."
    pm2 start "python3 $BOT_FOLDER/main.py" --name "$BOT_NAME" --log "$LOGS_DIR/$BOT_NAME.log"
  else
    echo "❌ Invalid selection"
    exit 1
  fi

  pm2 save
  pm2 startup | bash
  echo "✅ Bot $BOT_NAME added successfully!"

elif [[ "$OPTION" == "2" ]]; then
  echo "🛠 Available Bots:"
  ls "$BOTS_DIR"
  read -p "Bot name to edit: " BOT_NAME

  BOT_FOLDER="$BOTS_DIR/$BOT_NAME"
  if [[ ! -d "$BOT_FOLDER" ]]; then
    echo "❌ Bot not found"
    exit 1
  fi

  echo "Opening folder: $BOT_FOLDER"
  echo "Make your changes then press any key to restart bot."
  read -n 1 -s

  pm2 restart "$BOT_NAME"
  echo "♻️ Bot restarted"
else
  echo "❌ Invalid option"
  exit 1
fi

### 📊 Start Monitoring UI ###
echo "\n📊 Installing Monitoring UI (Node.js Express)..."
cd "$UI_DIR"
npm init -y &> /dev/null
npm install express systeminformation cors --save

cat <<EOF > index.js
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
app.listen(PORT, () => console.log(`🌐 Monitor running on http://localhost:\${PORT}`));
EOF

mkdir -p public
cat <<EOF > public/index.html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
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
        const monitor = document.getElementById('monitor');
        monitor.innerHTML = '<pre>' + JSON.stringify(data, null, 2) + '</pre>';
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

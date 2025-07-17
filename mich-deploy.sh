#!/bin/bash
if [ -z "$BASH_VERSION" ]; then exec bash "$0" "$@"; fi
set -euo pipefail
IFS=$'\n\t'

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
BOT_COUNT=$(pm2 list | grep -E "$BOTS_DIR" | wc -l || true)
if [[ $BOT_COUNT -gt 0 ]]; then
  echo "⚠️  Bot environment already set up."
  echo "1) Add a new bot"
  echo "2) Edit existing bot"
  echo "3) Exit"
  read -rp "Select option [1/2/3]: " OPTION
else
  OPTION=1
fi

### 📦 Dependencies ###
echo -e "\n📦 Installing dependencies..."
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
  BOT_NAME="${BOT_NAME//[^a-zA-Z0-9_-]/}"

  if [[ -z "$BOT_NAME" || -d "$BOTS_DIR/$BOT_NAME" ]]; then
    echo "❌ Invalid or duplicate bot name."
    exit 1
  fi

  BOT_FOLDER="$BOTS_DIR/$BOT_NAME"
  mkdir -p "$BOT_FOLDER"
  echo "📂 Upload your bot code to: $BOT_FOLDER"
  read -n 1 -s -rp "Press any key after upload to continue..."

  cd "$BOT_FOLDER"

  if [[ "$BOT_TYPE" == "1" ]]; then
    [[ ! -f index.js ]] && echo "❌ index.js not found." && exit 1
    [[ -f package.json ]] && npm install || echo "⚠️ No package.json found."
    pm2 start index.js --name "$BOT_NAME" --log "$LOGS_DIR/$BOT_NAME.log"
  else
    [[ ! -f main.py ]] && echo "❌ main.py not found." && exit 1
    [[ -f requirements.txt ]] && pip3 install -r requirements.txt || echo "⚠️ No requirements.txt found."
    pm2 start "python3 main.py" --name "$BOT_NAME" --log "$LOGS_DIR/$BOT_NAME.log"
  fi

  # PM2 Startup (Safe)
  STARTUP_CMD=$(pm2 startup | grep sudo)
  eval "$STARTUP_CMD"
  pm2 save

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

else
  echo "👋 Exiting..."
  exit 0
fi

### 📊 Monitoring UI ###
cd "$UI_DIR"

if [[ ! -f node_modules ]]; then
  npm init -y &>/dev/null
  npm install express systeminformation cors --save
fi

cat > index.js << 'EOF'
const express = require("express");
const si = require("systeminformation");
const app = express();
const PORT = 3000;

app.use(require("cors")());
app.get("/api/status", async (_, res) => {
  try {
    const [cpu, mem, fs, net, processes] = await Promise.all([
      si.currentLoad(), si.mem(), si.fsSize(), si.networkStats(), si.processes()
    ]);
    res.json({ cpu, mem, fs, net, processes });
  } catch (e) {
    res.status(500).json({ error: "Monitoring error", details: e.message });
  }
});
app.use(express.static("public"));
app.listen(PORT, '127.0.0.1', () => console.log(`🌐 Monitor: http://localhost:${PORT}`));
EOF

mkdir -p public
cat > public/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Bot Monitor</title>
  <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
  <link href="https://cdn.jsdelivr.net/npm/tailwindcss@2.2.19/dist/tailwind.min.css" rel="stylesheet">
</head>
<body class="bg-gray-900 text-white p-6 font-mono">
  <h1 class="text-3xl mb-4">📡 Discord Bot Monitor</h1>
  <div id="output" class="whitespace-pre text-green-400"></div>
  <canvas id="cpuChart" class="my-6"></canvas>
  <script>
    async function fetchData() {
      try {
        const res = await fetch('/api/status');
        const data = await res.json();
        document.getElementById('output').textContent = JSON.stringify(data, null, 2);

        const cpu = data.cpu;
        if (window.cpuChart) {
          window.cpuChart.data.datasets[0].data.push(cpu.currentload);
          window.cpuChart.data.labels.push(new Date().toLocaleTimeString());
          if (window.cpuChart.data.labels.length > 20) {
            window.cpuChart.data.labels.shift();
            window.cpuChart.data.datasets[0].data.shift();
          }
          window.cpuChart.update();
        } else {
          const ctx = document.getElementById('cpuChart').getContext('2d');
          window.cpuChart = new Chart(ctx, {
            type: 'line',
            data: {
              labels: [new Date().toLocaleTimeString()],
              datasets: [{
                label: 'CPU Load %',
                backgroundColor: 'rgba(34,197,94,0.2)',
                borderColor: '#22c55e',
                data: [cpu.currentload],
                fill: true,
              }]
            },
            options: {
              scales: {
                y: { beginAtZero: true, max: 100 }
              }
            }
          });
        }
      } catch (err) {
        document.getElementById('output').innerText = '❌ Error: ' + err;
      }
    }

    fetchData();
    setInterval(fetchData, 5000);
  </script>
</body>
</html>
EOF

pm2 describe monitor-ui &>/dev/null || pm2 start index.js --name monitor-ui
pm2 save

### ℹ️ Summary ###
echo -e "\n📈 Monitor via:"
echo "➡️ pm2 list"
echo "➡️ pm2 logs <bot-name>"
echo "➡️ http://localhost:3000"
echo "✅ Setup complete."
exit 0

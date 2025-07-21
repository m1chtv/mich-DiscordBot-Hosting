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
app.listen(PORT, '0.0.0.0', () => console.log(`🌐 Monitor: http://localhost:${PORT}`));
EOF

mkdir -p public
cat > public/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Bot Monitor</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
  <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body class="bg-dark text-white p-4">
  <div class="container">
    <h1 class="display-5 mb-4">📡 Discord Bot Monitor</h1>
    <pre id="output" class="bg-black p-3 rounded"></pre>
    <canvas id="cpuChart" class="my-4"></canvas>
  </div>
<script>
  let cpuChart;

  async function fetchData() {
    try {
      const res = await fetch('/api/status');
      const data = await res.json();
      document.getElementById('output').textContent = JSON.stringify(data, null, 2);

      const cpuLoad = data?.cpu?.currentload ?? 0;
      const time = new Date().toLocaleTimeString();

      if (!cpuChart) {
        const ctx = document.getElementById('cpuChart').getContext('2d');
        cpuChart = new Chart(ctx, {
          type: 'line',
          data: {
            labels: [time],
            datasets: [{
              label: 'CPU Load %',
              data: [cpuLoad],
              backgroundColor: 'rgba(13, 202, 240, 0.2)',
              borderColor: '#0dcaf0',
              fill: true,
              tension: 0.3,
            }]
          },
          options: {
            responsive: true,
            animation: true,
            scales: {
              y: { beginAtZero: true, max: 100 },
              x: { ticks: { maxTicksLimit: 10 } }
            }
          }
        });
      } else {
        cpuChart.data.labels.push(time);
        cpuChart.data.datasets[0].data.push(cpuLoad);

        if (cpuChart.data.labels.length > 20) {
          cpuChart.data.labels.shift();
          cpuChart.data.datasets[0].data.shift();
        }
        cpuChart.update();
      }
    } catch (err) {
      document.getElementById('output').innerText = '❌ Error: ' + (err.message || err);
    }
  }

  fetchData();
  setInterval(fetchData, 5000);
</script>


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

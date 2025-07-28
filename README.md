# mich-DiscordBot-Hosting

> 🔐 A full-featured, secure and user-friendly Discord bot hosting & monitoring toolkit for Linux (Ubuntu). Supports both discord.js (Node.js) and discord.py (Python) bots with web-based monitoring and automatic restart via PM2.

## 🧰 Features

- ✅ One-command setup for hosting Discord bots
- ⚡ Supports JavaScript (`discord.js`) & Python (`discord.py`) bots
- 🔁 Auto-restart on crash or server reboot (PM2)
- 📊 Web-based monitoring UI (RAM, CPU, Disk, Network, Processes)
- 📂 Organized bot folder structure (`bots/`, `logs/`, `ui/`)
- 🧠 Add/Edit multiple bots easily
- 🔥 Lightweight, secure, and modular design

---

## 🚀 Installation

```bash
sudo apt update
sudo apt install git -y
git clone https://github.com/m1chtv/mich-DiscordBot-Hosting.git
cd mich-DiscordBot-Hosting
chmod +x mich-deploy.sh
./mich-deploy.sh
```

> ⚠️ Make sure you're running on Ubuntu 20.04+ with `sudo` privileges.

---

## 🛠 Usage Flow

When you run `./mich-deploy.sh`, you will be prompted to:

1. **Choose action:** Add new bot or edit existing one
2. **Choose language:** `discord.js` or `discord.py`
3. **Enter bot name**
4. **Upload your bot's source code manually** to the generated folder
5. The script installs dependencies and runs your bot using `PM2`

All logs go to: `~/discord-bots/logs/<bot-name>.log`

---

## 🌐 Web Monitor UI

After deployment, a web-based dashboard will be available at:

```
http://<your-server-ip>:3000
user: admin
pass: admin
```

This displays real-time system stats including:

- ✅ CPU load
- ✅ Memory usage
- ✅ Disk space
- ✅ Network traffic
- ✅ Active processes

You can edit `ui/public/index.html` to customize the look.

---


## 🔐 Enable HTTPS with NGINX & Let's Encrypt

### To serve your Mich Bot Panel securely over HTTPS, follow this setup:

## ✅ Requirements

- A public VPS or cloud server (e.g., Ubuntu 20+)

- A valid domain pointed to your server (e.g., panel.yourdomain.com)

- Node.js app running on localhost:3000


### 📦 1. Install NGINX & Certbot
```
sudo apt update
sudo apt install nginx certbot python3-certbot-nginx -y
```

### ⚙️ 2. Configure NGINX
- Create a config file:
```
sudo nano /etc/nginx/sites-available/michBot
```
- Paste this:
```
server {
    listen 80;
    server_name panel.yourdomain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```
- Enable and test:
```
sudo ln -s /etc/nginx/sites-available/michBot /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### 🔐 3. Get SSL with Let’s Encrypt
```
sudo certbot --nginx -d panel.yourdomain.com
```

### 🧠 Done!
- Your panel is now live at:
```
https://panel.yourdomain.com
```
- With valid SSL & auto-renew.

---

## 🔄 PM2 CLI Tips

| Command                  | Purpose                         |
| ------------------------ | ------------------------------- |
| `pm2 list`               | Show all bots and services      |
| `pm2 logs <bot-name>`    | View live logs                  |
| `pm2 restart <bot-name>` | Restart bot manually            |
| `pm2 delete <bot-name>`  | Stop and remove bot             |
| `pm2 startup`            | Auto-run bots on server reboot  |
| `pm2 save`               | Save all current process states |

---

## 📦 Folder Structure

```
~/discord-bots/
├── bots/         # All bot folders live here
│   └── mybot/
│       ├── index.js  (or main.py)
│       └── ...
├── logs/         # PM2 logs
│   └── mybot.log
└── ui/           # Monitoring dashboard
    ├── index.js (API backend)
    └── public/index.html (UI frontend)
```

---

## 👨‍💻 Author

- Made by [mich](https://github.com/m1chtv)

---

## ⭐ Star the Project

If you found this helpful, star the repo on GitHub: [github.com/m1chtv/mich-DiscordBot-Hosting](https://github.com/m1chtv/mich-DiscordBot-Hosting)

---

## 🧠 License

AGPL-3.0 © 2025 m1chtv


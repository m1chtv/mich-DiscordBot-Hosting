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
```

This displays real-time system stats including:

- ✅ CPU load
- ✅ Memory usage
- ✅ Disk space
- ✅ Network traffic
- ✅ Active processes

You can edit `ui/public/index.html` to customize the look.

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

## ☁️ Hosting Notes

This script is intended for **personal VPS/servers**. Do not expose bot tokens in `.env` files without permissions. For production deployment, consider:

- Running on dedicated user with restricted permissions
- Isolating bot environments with Docker (future version)
- Adding a basic auth layer to the monitor UI (optional)

---

## ⭐ Star the Project

If you found this helpful, star the repo on GitHub: [github.com/m1chtv/mich-DiscordBot-Hosting](https://github.com/m1chtv/mich-DiscordBot-Hosting)

---

## 🧩 Future Features (Planned)

-

---

## 🧠 License

MIT © 2025 m1chtv


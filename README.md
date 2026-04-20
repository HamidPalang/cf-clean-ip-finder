
```markdown
# Cloudflare Clean IP + SNI Domain Finder

Find working Cloudflare IPs and SNI domains for v2ray, Xray, SNISPF.  
Optimized for filtered networks (Iran). Works on **Termux (Android)** and **Windows**.

> 💡 **New methods & updates**  
> Latest tricks, fresh IPs and SNI lists are shared on our Telegram channel:  
> **[https://t.me/maramivpn](https://t.me/maramivpn)**  
> Join to support this project and stay ahead!

---

## 📦 What you get

- ✅ Clean Cloudflare IPs (low latency, TLS working)
- ✅ SNI domains that work on those IPs
- ✅ Output as `.txt` and `.json`
- ✅ Custom domain list support

---

## 🔧 Prerequisites (install these first)

### On Termux (Android)

1. Install **Termux** from [F-Droid](https://f-droid.org/repo/com.termux_118.apk) (not Google Play).
2. Open Termux and run:

```bash
pkg update -y && pkg upgrade -y
pkg install -y curl openssl-tool netcat-openbsd
```

openssl and nc are optional but recommended. The script works without them.

On Windows

You have two choices:

Choice 1: Git Bash (easy)

· Download Git for Windows from git-scm.com
· Install with default settings.
· After installation, right-click any folder → Git Bash Here.

Choice 2: WSL (Windows Subsystem for Linux)

· Open PowerShell as Administrator and run:

```powershell
wsl --install
```

· Restart your PC.
· Launch Ubuntu from Start menu.
· Inside Ubuntu, run:

```bash
sudo apt update && sudo apt install curl -y
```

---

📥 Download the script (clone from GitHub)

Open a terminal (Termux, Git Bash, or WSL) and run:

```bash
git clone https://github.com/HamidPalang/cf-clean-ip-finder.git
cd cf-clean-ip-finder
```

Important for users in restricted networks (e.g., Iran):

· During download (git clone): You may need to use a VPN or anti-filtering tool to access GitHub.
· During script execution: You must turn off your VPN completely. The script needs a direct connection to test IPs and SNI domains.

If you don't have git, you can manually download the cf_finder.sh file and put it in a folder.

---

🧩 (Optional) Add your own SNI domains

Create a file named sni_domains.txt in the same folder as cf_finder.sh.
Add one domain per line. Lines starting with # are ignored.

Example sni_domains.txt:

```
# My domains
digikala.com
divar.ir
my-custom-proxy.ir
```

If this file is missing, the script uses a built-in list.

---

🚀 How to run – step by step

On Termux

1. Make sure you are in the project folder:

```bash
cd ~/storage/shared/cf-clean-ip-finder
```

(Adjust the path if you cloned elsewhere.)

1. Turn OFF your VPN – this is critical.
      The script will remind you. Press Enter after disabling.
2. Run the script:

```bash
bash cf_finder.sh
```

1. Enter the number of random IPs (e.g., 80). More IPs = better chance but slower.
2. Wait. The script will:
   · Test seed IPs
   · Generate and test random IPs
   · Pick the best IP
   · Test all SNI domains on that IP
3. When finished, you will see two files in the same folder:
   · cf_results_YYYYMMDD_HHMMSS.txt
   · cf_results_YYYYMMDD_HHMMSS.json
4. View the results:

```bash
cat cf_results_*.txt
```

Or open the .txt file with any text editor.

---

On Windows – Git Bash

1. Open the folder where you cloned the repo.
      Right-click inside the folder → Git Bash Here.
2. Disable any VPN or system proxy (very important).
3. Run the script:

```bash
bash cf_finder.sh
```

1. Enter the number of IPs (e.g., 80) and press Enter.
2. Wait for completion.
3. Results are saved as .txt and .json in the same folder.
      Double-click the .txt file to open with Notepad.

---

On Windows – WSL

1. Launch your WSL terminal (e.g., Ubuntu from Start menu).
2. Go to the project folder. If you cloned inside WSL home:

```bash
cd ~/cf-clean-ip-finder
```

If you cloned on Windows drive (e.g., Desktop):

```bash
cd /mnt/c/Users/YourUserName/Desktop/cf-clean-ip-finder
```

1. Turn off any VPN on your Windows host (the script runs inside WSL but uses the host's network).
2. Run:

```bash
bash cf_finder.sh
```

1. Follow the prompts.
2. Results are in the same folder. Use cat or ls to see them.

---

📄 Understanding the output

Terminal output example

```
Top Clean Cloudflare IPs:
   1. 104.21.1.123       45ms  CF:confirmed  Ports:2053,2087
   2. 172.67.0.45        67ms  CF:confirmed  Ports:none

Usable SNI Domains:
   1. digikala.com                   32ms
   2. divar.ir                       41ms
```

· CF:confirmed = IP returns Cloudflare headers (good).
· Ports = alternative ports open (2053, 2083, 2087, 8447).
· Latency = lower is better.

Saved .txt file content

```
# Cloudflare Clean IPs - generated ...

[CLEAN IPs - sorted by latency]
104.21.1.123    (45ms)
172.67.0.45     (67ms)

[SNI DOMAINS - usable as fake_sni / serverName]
digikala.com    (32ms)
divar.ir        (41ms)
```

Saved .json file

Contains structured data for automation – IPs, latency, ports, etc.

---

⚙️ Advanced options (for experienced users)

Change SNI verification mode

By default it uses tls (TLS handshake). To also check HTTP cf-ray header:

```bash
export SNI_VERIFICATION_MODE=http
bash cf_finder.sh
```

Control parallel threads

Default = up to 6. To use only 4:

```bash
export CF_PARALLEL=4
bash cf_finder.sh
```

Use a different SNI domain file

```bash
export CUSTOM_SNI_FILE="/path/to/your/domains.txt"
bash cf_finder.sh
```

---

❓ Troubleshooting

Problem Solution
bash: command not found You are not in Bash. Use Termux, Git Bash, or WSL.
curl: command not found Install curl: pkg install curl (Termux), sudo apt install curl (WSL). Git Bash has it.
No clean IPs found VPN must be 100% off. Try again with more IPs (e.g., 200). Run at different times.
No SNI domains found The best IP changed. Run the script again. Or add more domains to sni_domains.txt.
nc: invalid option -- 'z' (Termux) Ignore it – the script falls back to /dev/tcp. Works fine.
Script is very slow Reduce the number of IPs (e.g., 40) or lower CF_PARALLEL to 2.
git clone fails (network error) You may need a VPN to access GitHub. Turn on VPN only for download, then turn it off before running the script.

---

📁 Project files after run

```
cf-clean-ip-finder/
├── cf_finder.sh               # main script
├── sni_domains.txt            # your custom domains (if you made one)
├── cf_results_20250420_153022.txt
├── cf_results_20250420_153022.json
└── README.md                  # this file
```

---

📜 License

MIT – free to use, modify, and share.

---

Note: This tool is for educational purposes. Obey your local laws.
Join our Telegram for new methods & support: https://t.me/maramivpn

```

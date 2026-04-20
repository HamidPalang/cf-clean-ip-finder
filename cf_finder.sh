
#!/bin/bash
# ============================================================
#  Cloudflare Clean IP + SNI Domain Finder
#  For use with SNISPF / v2ray / xray configs
#  Works on Termux | Optimized for Iran filtered networks
#  Usage: ./cf_finder.sh
# ============================================================

# Colors
G='\033[0;32m'   # green
R='\033[0;31m'   # red
Y='\033[1;33m'   # yellow
C='\033[0;36m'   # cyan
M='\033[0;35m'   # magenta
B='\033[1m'      # bold
N='\033[0m'      # reset

# ------------------------------------------------------------
#  RESOURCE MANAGEMENT
# ------------------------------------------------------------
if command -v nproc &>/dev/null; then
    CORES=$(nproc)
else
    CORES=2
fi
PARALLEL=$(( CORES < 6 ? CORES : 6 ))
PARALLEL=${CF_PARALLEL:-$PARALLEL}

TLS_TIMEOUT=3
HTTP_TIMEOUT=4
TS=$(date +%Y%m%d_%H%M%S)
OUT_JSON="cf_results_${TS}.json"
OUT_TXT="cf_results_${TS}.txt"
TMPDIR_WORK=$(mktemp -d)

cleanup() {
    rm -rf "$TMPDIR_WORK"
    jobs -p | xargs -r kill -9 2>/dev/null
    exit
}
trap cleanup INT TERM EXIT

# ---- Cloudflare IP ranges ----
CF_RANGES=(
  "103.21.244.0/22" "103.22.200.0/22" "103.31.4.0/22"
  "104.16.0.0/13" "104.24.0.0/14" "108.162.192.0/18"
  "131.0.72.0/22" "141.101.64.0/18" "162.158.0.0/15"
  "172.64.0.0/13" "188.114.96.0/20" "190.93.240.0/20"
  "197.234.240.0/22" "198.41.128.0/17"
)

# ============================================================
#  SNI DOMAINS (از فایل خارجی یا داخلی)
# ============================================================
# حالت بررسی: "tls" (پیشفرض) یا "http"
SNI_VERIFICATION_MODE="${SNI_VERIFICATION_MODE:-tls}"

# دامنه‌های داخلی (در صورتی که فایل سفارشی وجود نداشته باشد)
IRAN_WHITELIST_DOMAINS=(
  "sni.mobillereza.ir" "sni.akbarjojetehran.ir" "cdn.mobillereza.ir"
  "cdntr.mobillereza.ir" "doh2.mobillereza.ir" "digikala.com"
  "divar.ir" "torob.com" "alibaba.ir" "snapp.ir" "tap30.ir"
  "bale.ir" "rubika.ir" "eitaa.com" "soroush.ir" "igap.net"
  "mci.ir" "irancell.ir" "rightel.ir" "bankmellat.ir"
  "tejaratbank.ir" "bsi.ir" "postbank.ir" "farsnews.ir"
  "varzesh3.com"
)

GLOBAL_CF_DOMAINS=(
  "dash.cloudflare.com" "blog.cloudflare.com" "developers.cloudflare.com"
  "workers.cloudflare.com" "pages.cloudflare.com" "one.one.one.one"
  "speed.cloudflare.com" "www.cloudflare.com" "api.cloudflare.com"
  "www.cdnjs.com" "cdnjs.cloudflare.com" "www.npmjs.com"
  "registry.npmjs.org" "www.gitlab.com" "assets.gitlab-static.net"
  "www.zendesk.com" "static.cloudflareinsights.com" "challenges.cloudflare.com"
  "imagedelivery.net" "www.bitdefender.com" "www.malwarebytes.com"
  "assets.ubuntu.com" "changelogs.ubuntu.com" "www.digitalocean.com"
  "www.linode.com" "www.backblaze.com" "www.cloudways.com"
)

# بارگذاری دامنه‌ها از فایل sni_domains.txt (در صورت وجود)
SNI_DOMAINS=()
CUSTOM_SNI_FILE="./sni_domains.txt"
if [[ -f "$CUSTOM_SNI_FILE" ]]; then
    echo -e "${C}[*] بارگذاری دامنه‌ها از فایل: ${CUSTOM_SNI_FILE}${N}"
    mapfile -t SNI_DOMAINS < "$CUSTOM_SNI_FILE"
    # حذف خطوط خالی و کامنت‌ها
    SNI_DOMAINS=($(printf '%s\n' "${SNI_DOMAINS[@]}" | grep -v '^#' | grep -v '^$' | tr -d '\r'))
else
    echo -e "${Y}[!] فایل ${CUSTOM_SNI_FILE} یافت نشد. استفاده از دامنه‌های داخلی.${N}"
    SNI_DOMAINS=("${IRAN_WHITELIST_DOMAINS[@]}" "${GLOBAL_CF_DOMAINS[@]}")
fi

echo -e "${C}[*] تعداد دامنه‌های SNI بارگذاری شده: ${#SNI_DOMAINS[@]}${N}"

# ---- Seed IPs ----
SEED_IPS=(
  "104.16.0.1" "104.16.1.1" "104.16.2.1" "104.16.3.1"
  "104.16.4.1" "104.16.5.1" "104.16.6.1" "104.16.7.1"
  "104.17.0.1" "104.17.1.1" "104.17.2.1" "104.17.3.1"
  "104.18.0.1" "104.18.1.1" "104.18.2.1" "104.18.3.1"
  "104.19.0.1" "104.19.1.1" "104.19.2.1" "104.19.3.1"
  "104.20.0.1" "104.20.1.1" "104.20.2.1" "104.20.3.1"
  "104.21.0.1" "104.21.1.1" "104.21.2.1" "104.21.3.1"
  "172.64.0.1" "172.64.1.1" "172.64.2.1" "172.64.3.1"
  "172.65.0.1" "172.65.1.1" "172.65.2.1" "172.65.3.1"
  "172.66.0.1" "172.66.1.1" "172.66.2.1" "172.66.3.1"
  "172.67.0.1" "172.67.1.1" "172.67.2.1" "172.67.3.1"
  "162.158.0.1" "162.158.1.1" "162.158.2.1" "162.158.3.1"
  "198.41.128.1" "198.41.192.1" "198.41.200.1" "198.41.208.1"
  "141.101.64.1" "141.101.72.1" "141.101.80.1" "141.101.88.1"
  "188.114.96.1" "188.114.97.1" "188.114.98.1" "188.114.99.1"
  "190.93.240.1" "190.93.241.1" "190.93.242.1" "190.93.243.1"
  "108.162.192.1" "108.162.193.1" "108.162.194.1" "108.162.195.1"
)

# ============================================================
#  STEP 1: تست آی‌پی (بدون تغییر)
# ============================================================
test_ip() {
  local ip=$1
  local result_file="${TMPDIR_WORK}/ip_${ip//./_}.result"
  [ -f "$result_file" ] && return

  local start end latency tls_ok=1
  start=$(date +%s%3N 2>/dev/null || date +%s)

  if command -v openssl &>/dev/null; then
    tls_out=$(echo "" | timeout "$TLS_TIMEOUT" openssl s_client \
      -connect "${ip}:443" \
      -servername "speed.cloudflare.com" \
      -verify_return_error 2>&1)
    echo "$tls_out" | grep -q "Cipher is" && tls_ok=0
  elif command -v nc &>/dev/null; then
    nc -zw"$TLS_TIMEOUT" "$ip" 443 2>/dev/null
    tls_ok=$?
  else
    timeout "$TLS_TIMEOUT" bash -c "echo >/dev/tcp/${ip}/443" 2>/dev/null
    tls_ok=$?
  fi

  [ "$tls_ok" != "0" ] && return

  end=$(date +%s%3N 2>/dev/null || date +%s)
  latency=$((end - start))

  # تست HTTP برای تأیید Cloudflare (اختیاری)
  http_out=$(curl -sI --max-time "$HTTP_TIMEOUT" \
    --resolve "speed.cloudflare.com:443:${ip}" \
    "https://speed.cloudflare.com" 2>/dev/null)
  if echo "$http_out" | grep -qi "cf-ray:"; then
    cf_header="confirmed"
  else
    cf_header="unconfirmed"
  fi

  # پورت‌های جایگزین
  local alt_ports=""
  for port in 2053 2083 2087 8443; do
    if command -v nc &>/dev/null; then
      nc -zw2 "$ip" "$port" 2>/dev/null && alt_ports="${alt_ports}${port},"
    fi
  done
  alt_ports="${alt_ports%,}"

  cat > "$result_file" << EOF
IP=${ip}
LATENCY=${latency}
CF_CONFIRMED=${cf_header}
ALT_PORTS=${alt_ports:-none}
EOF

  printf "${G}[CLEAN]${N} ${B}%-18s${N} ${C}%4dms${N}  CF:%s  AltPorts:%s\n" \
    "$ip" "$latency" "$cf_header" "${alt_ports:-none}"
}

# ============================================================
#  STEP 2: تولید آی‌پی تصادفی
# ============================================================
gen_random_ips() {
  local count=$1
  local ips=()
  for range in "${CF_RANGES[@]}"; do
    local base_ip="${range%/*}"
    local a b c d
    IFS='.' read -r a b c d <<< "$base_ip"
    local per_range=$(( count / ${#CF_RANGES[@]} + 1 ))
    for (( i=0; i<per_range; i++ )); do
      local rand_c=$(( RANDOM % 256 ))
      local rand_d=$(( RANDOM % 254 + 1 ))
      ips+=("${a}.${b}.${rand_c}.${rand_d}")
    done
  done
  printf '%s\n' "${ips[@]}" | head -"$count"
}

# ============================================================
#  STEP 3: بررسی دامنه SNI (حالت TLS یا HTTP)
# ============================================================
verify_sni_domain() {
  local domain=$1
  local clean_ip=$2
  local result_file="${TMPDIR_WORK}/sni_${domain//./_}.result"

  [ -f "$result_file" ] && return

  local tls_ok=1 latency=0

  local start end
  start=$(date +%s%3N 2>/dev/null || date +%s)

  # تست TLS handshake با openssl
  if command -v openssl &>/dev/null; then
    tls_out=$(echo "" | timeout "$TLS_TIMEOUT" openssl s_client \
      -connect "${clean_ip}:443" \
      -servername "$domain" \
      2>&1)
    if echo "$tls_out" | grep -q "Cipher is"; then
      tls_ok=0
    fi
  elif command -v nc &>/dev/null; then
    nc -zw"$TLS_TIMEOUT" "$clean_ip" 443 2>/dev/null
    tls_ok=$?
  else
    timeout "$TLS_TIMEOUT" bash -c "echo >/dev/tcp/${clean_ip}/443" 2>/dev/null
    tls_ok=$?
  fi

  [ "$tls_ok" != "0" ] && return

  end=$(date +%s%3N 2>/dev/null || date +%s)
  latency=$((end - start))

  # اگر حالت HTTP فعال باشد، هدر cf-ray را نیز بررسی می‌کنیم
  if [[ "$SNI_VERIFICATION_MODE" == "http" ]]; then
    local hdr
    hdr=$(curl -sI --max-time "$HTTP_TIMEOUT" \
      --resolve "${domain}:443:${clean_ip}" \
      "https://$domain" 2>/dev/null)
    if ! echo "$hdr" | grep -qi "cf-ray:"; then
      return  # در حالت HTTP، بدون cf-ray قبول نمی‌کنیم
    fi
  fi

  # ذخیره نتیجه
  cat > "$result_file" << EOF
DOMAIN=${domain}
LATENCY=${latency}
USABLE_AS_SNI=yes
MODE=${SNI_VERIFICATION_MODE}
EOF

  printf "${M}[SNI-OK]${N} ${B}%-35s${N} ${C}%4dms${N} (mode: %s)\n" \
    "$domain" "$latency" "$SNI_VERIFICATION_MODE"
}

# ============================================================
#  خروجی نهایی (بدون تغییر اساسی)
# ============================================================
generate_output() {
  local clean_ips=()
  local good_sni_domains=()

  for f in "$TMPDIR_WORK"/ip_*.result; do
    [ -f "$f" ] || continue
    ip=$(grep "^IP=" "$f" | cut -d= -f2)
    lat=$(grep "^LATENCY=" "$f" | cut -d= -f2)
    clean_ips+=("${lat}:${ip}")
  done
  IFS=$'\n' sorted_ips=($(sort -t: -k1 -n <<< "${clean_ips[*]}")); unset IFS

  for f in "$TMPDIR_WORK"/sni_*.result; do
    [ -f "$f" ] || continue
    dom=$(grep "^DOMAIN=" "$f" | cut -d= -f2)
    lat=$(grep "^LATENCY=" "$f" | cut -d= -f2)
    good_sni_domains+=("${lat}:${dom}")
  done
  IFS=$'\n' sorted_sni=($(sort -t: -k1 -n <<< "${good_sni_domains[*]}")); unset IFS

  echo ""
  echo -e "${B}${C}============================================${N}"
  echo -e "${B}${C}  RESULTS SUMMARY${N}"
  echo -e "${B}${C}============================================${N}"
  echo ""
  echo -e "${B}  Top Clean Cloudflare IPs:${N}"
  local rank=1
  for entry in "${sorted_ips[@]:0:10}"; do
    lat="${entry%%:*}"
    ip="${entry#*:}"
    rf="${TMPDIR_WORK}/ip_${ip//./_}.result"
    cf_status=$(grep "^CF_CONFIRMED=" "$rf" 2>/dev/null | cut -d= -f2)
    alt_ports=$(grep "^ALT_PORTS=" "$rf" 2>/dev/null | cut -d= -f2)
    printf "  ${G}%2d.${N} ${B}%-18s${N}  ${C}%4dms${N}  CF:%-13s  Ports:%s\n" \
      "$rank" "$ip" "$lat" "$cf_status" "$alt_ports"
    rank=$((rank+1))
  done

  echo ""
  echo -e "${B}  Usable SNI Domains (برای استفاده در SNISPF):${N}"
  if [[ ${#sorted_sni[@]} -eq 0 ]]; then
    echo -e "  ${R}هیچ دامنه‌ای یافت نشد.${N}"
    echo -e "  ${Y}راهکارها:${N}"
    echo -e "  ${Y}1. فایل ${CUSTOM_SNI_FILE} را با دامنه‌های بیشتر ایجاد کنید.${N}"
    echo -e "  ${Y}2. حالت بررسی را به TLS تغییر دهید (پیش‌فرض همین است).${N}"
    echo -e "  ${Y}3. از آی‌پی تمیز دیگری استفاده کنید (ممکن است این آی‌پی دامنه‌های خاصی را نپذیرد).${N}"
  else
    rank=1
    for entry in "${sorted_sni[@]:0:15}"; do
      lat="${entry%%:*}"
      dom="${entry#*:}"
      printf "  ${M}%2d.${N} ${B}%-35s${N}  ${C}%4dms${N}\n" "$rank" "$dom" "$lat"
      rank=$((rank+1))
    done
  fi

  # نوشتن JSON و TXT (مشابه قبل)
  echo "[" > "$OUT_JSON"
  local first_entry=true
  for entry in "${sorted_ips[@]:0:20}"; do
    lat="${entry%%:*}"
    ip="${entry#*:}"
    rf="${TMPDIR_WORK}/ip_${ip//./_}.result"
    cf=$(grep "^CF_CONFIRMED=" "$rf" 2>/dev/null | cut -d= -f2)
    ap=$(grep "^ALT_PORTS=" "$rf" 2>/dev/null | cut -d= -f2)
    $first_entry || echo "  ," >> "$OUT_JSON"
    cat >> "$OUT_JSON" << EOF
  {
    "ip": "$ip",
    "latency_ms": $lat,
    "cf_confirmed": "$cf",
    "alt_ports": "$ap",
    "port": 443
  }
EOF
    first_entry=false
  done
  echo "]" >> "$OUT_JSON"

  {
    echo "# Cloudflare Clean IPs - generated $(date)"
    echo ""
    echo "[CLEAN IPs - sorted by latency]"
    for entry in "${sorted_ips[@]:0:20}"; do
      ip="${entry#*:}"
      lat="${entry%%:*}"
      echo "${ip}    (${lat}ms)"
    done
    echo ""
    echo "[SNI DOMAINS - usable as fake_sni / serverName]"
    for entry in "${sorted_sni[@]:0:15}"; do
      dom="${entry#*:}"
      lat="${entry%%:*}"
      echo "${dom}    (${lat}ms)"
    done
  } > "$OUT_TXT"

  echo ""
  echo -e "${G}${B}Output files:${N}"
  echo -e "  JSON: ${B}$OUT_JSON${N}"
  echo -e "  TXT:  ${B}$OUT_TXT${N}"
}

# ============================================================
#  MAIN
# ============================================================
main() {
  clear
  echo -e "${B}${C}"
  echo "  +=====================================================+"
  echo "  |   Cloudflare Clean IP + SNI Finder (Enhanced)      |"
  echo "  |   Mode: ${SNI_VERIFICATION_MODE}                            |"
  echo "  +=====================================================+"
  echo -e "${N}"

  echo -e "${C}[*] Checking tools...${N}"
  command -v curl &>/dev/null || { echo -e "${R}curl is required. Install: pkg install curl${N}"; exit 1; }
  command -v openssl &>/dev/null && echo -e "${G}  ok: openssl${N}" || echo -e "${Y}  openssl not found (optional)${N}"
  command -v nc &>/dev/null && echo -e "${G}  ok: nc${N}" || echo -e "${Y}  nc not found${N}"
  echo ""

  echo -e "${B}How many random IPs to scan? (default: 80):${N}"
  read -r -p "  > " user_count
  local ip_count=${user_count:-80}

  echo ""
  echo -e "${B}${C}========================================${N}"
  echo -e "${B}${C}  PHASE 1: Scanning Cloudflare IPs${N}"
  echo -e "${B}${C}  VPN must be OFF for accurate results${N}"
  echo -e "${B}${C}========================================${N}"
  echo -e "${Y}  Turn OFF your VPN now, then press Enter${N}"
  read -r -p "  [Enter to start]: "
  echo ""

  export -f test_ip
  export TMPDIR_WORK TLS_TIMEOUT HTTP_TIMEOUT G R Y C M B N

  echo -e "${C}[*] Testing ${#SEED_IPS[@]} seed IPs (max $PARALLEL parallel)...${N}"
  printf '%s\n' "${SEED_IPS[@]}" | xargs -P "$PARALLEL" -n 1 bash -c 'test_ip "$1"' _

  echo ""
  echo -e "${C}[*] Generating and testing $ip_count random IPs...${N}"
  gen_random_ips "$ip_count" > "${TMPDIR_WORK}/random_ips.txt"
  split -l 50 "${TMPDIR_WORK}/random_ips.txt" "${TMPDIR_WORK}/batch_"
  for batch in "${TMPDIR_WORK}"/batch_*; do
    xargs -P "$PARALLEL" -n 1 bash -c 'test_ip "$1"' _ < "$batch"
    sleep 0.5
  done

  local clean_count
  clean_count=$(ls "$TMPDIR_WORK"/ip_*.result 2>/dev/null | wc -l)
  echo ""
  echo -e "${G}[*] Phase 1 done. Found ${B}${clean_count}${N}${G} reachable IPs.${N}"

  # انتخاب بهترین آی‌پی
  local best_ip=""
  for f in "$TMPDIR_WORK"/ip_*.result; do
    [ -f "$f" ] || continue
    if grep -q "CF_CONFIRMED=confirmed" "$f"; then
      best_ip=$(grep "^IP=" "$f" | cut -d= -f2)
      break
    fi
  done
  if [ -z "$best_ip" ]; then
    local first_result
    first_result=$(ls "$TMPDIR_WORK"/ip_*.result 2>/dev/null | head -1)
    [ -n "$first_result" ] && best_ip=$(grep "^IP=" "$first_result" | cut -d= -f2)
  fi

  echo ""
  echo -e "${B}${M}========================================${N}"
  echo -e "${B}${M}  PHASE 2: Verifying SNI Domains${N}"
  echo -e "${B}${M}  Mode: ${SNI_VERIFICATION_MODE}${N}"
  echo -e "${B}${M}========================================${N}"

  if [ -z "$best_ip" ]; then
    echo -e "${R}[!] No clean IP found. Cannot verify SNI domains.${N}"
    echo -e "${Y}    Try turning VPN OFF and running again.${N}"
  else
    echo -e "${C}[*] Using ${best_ip} to verify ${#SNI_DOMAINS[@]} SNI domains...${N}"
    export -f verify_sni_domain
    export best_ip SNI_VERIFICATION_MODE
    printf '%s\n' "${SNI_DOMAINS[@]}" | xargs -P "$PARALLEL" -n 1 bash -c 'verify_sni_domain "$1" "$best_ip"' _
  fi

  generate_output
  rm -rf "$TMPDIR_WORK"

  echo ""
  echo -e "${G}${B}Done!${N}"
  echo -e "  Copy IPs and SNI domains from: ${B}${OUT_TXT}${N}"
  echo -e "  ${Y}Hint: برای استفاده از دامنه‌های دلخواه، فایل ${CUSTOM_SNI_FILE} را ایجاد کنید (یک دامنه در هر خط).${N}"
}

main "$@"



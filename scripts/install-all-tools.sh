#!/usr/bin/env bash
#
# HexStrike AI - full tool installer (CTF setup)
# Target: Ubuntu/Debian (including WSL2 Ubuntu on Windows)
#
# Installs the ~150 tools HexStrike's MCP server can call, covering:
# network/recon, web app testing, password cracking, binary/reverse
# engineering, forensics/CTF, and cloud security.
#
# Usage:
#   chmod +x scripts/install-all-tools.sh
#   ./scripts/install-all-tools.sh
#
# Safe to re-run: every step is best-effort (failures are logged, not fatal),
# so re-running just fills in whatever didn't install the first time.

set -uo pipefail

LOG_FILE="$HOME/hexstrike-install.log"
FAILED=()
OK=()

log()  { echo -e "\033[1;36m[*]\033[0m $*" | tee -a "$LOG_FILE"; }
ok()   { echo -e "\033[1;32m[OK]\033[0m $*" | tee -a "$LOG_FILE"; OK+=("$1"); }
fail() { echo -e "\033[1;31m[FAIL]\033[0m $*" | tee -a "$LOG_FILE"; FAILED+=("$1"); }

run() {
  # run <label> <command...>  -- treats first arg as a human label
  local label="$1"; shift
  if "$@" >>"$LOG_FILE" 2>&1; then ok "$label"; else fail "$label"; fi
}

GOBIN="$HOME/go/bin"
mkdir -p "$GOBIN"
export PATH="$PATH:$GOBIN:$HOME/.cargo/bin:$HOME/.local/bin"

# ---------------------------------------------------------------------------
# 0. Base toolchain: apt, Go, Rust, pipx, Ruby
# ---------------------------------------------------------------------------
log "Updating apt and installing base toolchain..."
sudo apt update
sudo apt install -y \
  build-essential git curl wget unzip python3 python3-pip python3-venv pipx \
  golang-go ruby-full cargo default-jdk libssl-dev libffi-dev cmake \
  libcapstone-dev

pipx ensurepath >/dev/null 2>&1 || true
export PATH="$PATH:$HOME/.local/bin"

# ---------------------------------------------------------------------------
# 1. Network & reconnaissance (apt)
# ---------------------------------------------------------------------------
log "Installing network/recon tools..."
run "nmap"        sudo apt install -y nmap
run "masscan"      sudo apt install -y masscan
run "amass"        sudo apt install -y amass
run "fierce"       sudo apt install -y fierce
run "dnsenum"      sudo apt install -y dnsenum
run "theharvester"  sudo apt install -y theharvester
run "netexec"      pipx install netexec
run "enum4linux-ng" pipx install enum4linux-ng
run "smbmap"       pipx install smbmap
run "responder"    sudo apt install -y responder
run "nbtscan"      sudo apt install -y nbtscan
run "arp-scan"     sudo apt install -y arp-scan
run "rpcbind-tools(rpcclient)" sudo apt install -y smbclient

log "Installing rustscan (cargo)..."
run "rustscan" cargo install rustscan --root "$HOME/.cargo"

# ---------------------------------------------------------------------------
# 2. Web application security (apt + go)
# ---------------------------------------------------------------------------
log "Installing web app testing tools..."
run "gobuster"     sudo apt install -y gobuster
run "dirb"         sudo apt install -y dirb
run "nikto"        sudo apt install -y nikto
run "sqlmap"       sudo apt install -y sqlmap
run "wfuzz"        pipx install wfuzz
run "wafw00f"      pipx install wafw00f
run "dirsearch"    pipx install dirsearch
run "arjun"        pipx install arjun
run "paramspider"  pipx install paramspider
run "xsser"        sudo apt install -y xsser

log "Installing Go-based web tools..."
run "ffuf"           go install github.com/ffuf/ffuf/v2@latest
run "feroxbuster"     sudo apt install -y feroxbuster
run "subfinder"       go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
run "httpx"           go install github.com/projectdiscovery/httpx/cmd/httpx@latest
run "nuclei"          go install github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
run "katana"          go install github.com/projectdiscovery/katana/cmd/katana@latest
run "dalfox"          go install github.com/hahwul/dalfox/v2@latest
run "gau"             go install github.com/lc/gau/v2/cmd/gau@latest
run "waybackurls"     go install github.com/tomnomnom/waybackurls@latest
run "anew"            go install github.com/tomnomnom/anew@latest
run "qsreplace"       go install github.com/tomnomnom/qsreplace@latest
run "uro"             pipx install uro
run "hakrawler"       go install github.com/hakluke/hakrawler@latest
run "jaeles"          go install github.com/jaeles-project/jaeles@latest
run "x8"              cargo install x8 --root "$HOME/.cargo"

log "Installing WPScan (Ruby gem)..."
run "wpscan" sudo gem install wpscan

log "Installing ZAP (OWASP ZAP proxy)..."
run "zaproxy" sudo apt install -y zaproxy

# ---------------------------------------------------------------------------
# 3. Password / authentication attacks
# ---------------------------------------------------------------------------
log "Installing password cracking tools..."
run "hydra"      sudo apt install -y hydra
run "john"       sudo apt install -y john
run "hashcat"    sudo apt install -y hashcat
run "medusa"     sudo apt install -y medusa
run "patator"    pipx install patator
run "crackmapexec" pipx install crackmapexec
run "evil-winrm"  sudo gem install evil-winrm
run "hash-identifier" sudo apt install -y hash-identifier
run "ophcrack"    sudo apt install -y ophcrack

# ---------------------------------------------------------------------------
# 4. Binary analysis & reverse engineering (CTF core)
# ---------------------------------------------------------------------------
log "Installing binary/RE tools..."
run "gdb"        sudo apt install -y gdb
run "radare2"    sudo apt install -y radare2
run "binwalk"    sudo apt install -y binwalk
run "checksec"   sudo apt install -y checksec
run "objdump/binutils" sudo apt install -y binutils
run "xxd"        sudo apt install -y xxd
run "ropgadget"  pipx install ropgadget
run "ropper"     pipx install ropper
run "pwntools"   pipx install pwntools
run "one_gadget" sudo gem install one_gadget
run "angr"       pipx install angr

log "Installing GDB-PEDA (GDB exploit dev plugin)..."
if [ ! -d "$HOME/peda" ]; then
  run "gdb-peda" git clone https://github.com/longld/peda.git "$HOME/peda"
  echo "source $HOME/peda/peda.py" >> "$HOME/.gdbinit"
fi

log "Installing pwninit..."
run "pwninit" cargo install pwninit --root "$HOME/.cargo"

log "Installing libc-database..."
if [ ! -d "$HOME/libc-database" ]; then
  run "libc-database" git clone https://github.com/niklasb/libc-database.git "$HOME/libc-database"
fi

log "Installing Ghidra (NSA reverse-engineering suite)..."
if [ ! -d "$HOME/ghidra" ]; then
  GHIDRA_URL="https://github.com/NationalSecurityAgency/ghidra/releases/latest/download"
  log "Ghidra needs a manual version pin from GitHub releases; skipping auto-download."
  log "  -> https://github.com/NationalSecurityAgency/ghidra/releases (unzip to ~/ghidra)"
fi

# ---------------------------------------------------------------------------
# 5. Forensics & steganography (CTF)
# ---------------------------------------------------------------------------
log "Installing forensics tools..."
run "foremost"   sudo apt install -y foremost
run "steghide"   sudo apt install -y steghide
run "exiftool"   sudo apt install -y libimage-exiftool-perl
run "volatility3" pipx install volatility3
run "hashpump"   sudo apt install -y hashpump

# ---------------------------------------------------------------------------
# 6. Exploitation frameworks
# ---------------------------------------------------------------------------
log "Installing Metasploit Framework..."
if ! command -v msfconsole >/dev/null 2>&1; then
  curl -fsSL https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb \
    -o /tmp/msfinstall && chmod +x /tmp/msfinstall && run "metasploit" sudo /tmp/msfinstall
fi

# ---------------------------------------------------------------------------
# 7. Cloud & container security (bundled in HexStrike; optional for CTF)
# ---------------------------------------------------------------------------
log "Installing cloud/container security tools..."
run "trivy"       bash -c "curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sudo sh -s -- -b /usr/local/bin"
run "prowler"     pipx install prowler
run "scout-suite" pipx install scoutsuite
run "checkov"     pipx install checkov
run "kube-hunter" pipx install kube-hunter
run "kube-bench"  bash -c "curl -sL https://raw.githubusercontent.com/aquasecurity/kube-bench/main/hack/install.sh | sudo bash"
run "docker-bench-security" bash -c "[ -d $HOME/docker-bench-security ] || git clone https://github.com/docker/docker-bench-security.git $HOME/docker-bench-security"
run "terrascan"   bash -c "curl -sL https://raw.githubusercontent.com/tenable/terrascan/master/install.sh | sudo bash"

# ---------------------------------------------------------------------------
# 8. HexStrike's own Python dependencies
# ---------------------------------------------------------------------------
log "Installing HexStrike Python requirements..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
if [ -f "$REPO_ROOT/requirements.txt" ]; then
  python3 -m venv "$REPO_ROOT/hexstrike-env" 2>>"$LOG_FILE" || true
  # shellcheck disable=SC1091
  source "$REPO_ROOT/hexstrike-env/bin/activate"
  run "hexstrike requirements.txt" pip3 install -r "$REPO_ROOT/requirements.txt"
  deactivate
fi

# ---------------------------------------------------------------------------
# Persist PATH additions for future shells
# ---------------------------------------------------------------------------
for line in \
  'export PATH="$PATH:$HOME/go/bin"' \
  'export PATH="$PATH:$HOME/.cargo/bin"' \
  'export PATH="$PATH:$HOME/.local/bin"'
do
  grep -qxF "$line" "$HOME/.bashrc" || echo "$line" >> "$HOME/.bashrc"
done

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo
echo "=================== INSTALL SUMMARY ==================="
echo "Installed OK: ${#OK[@]}"
echo "Failed:       ${#FAILED[@]}"
if [ "${#FAILED[@]}" -gt 0 ]; then
  echo
  echo "The following failed and need a manual look (see $LOG_FILE):"
  printf '  - %s\n' "${FAILED[@]}"
fi
echo
echo "Restart your shell (or run 'source ~/.bashrc') so Go/Rust/pipx PATH entries take effect."
echo "Ghidra needs a manual download (see log above) — Java is already installed for it."
echo "========================================================="

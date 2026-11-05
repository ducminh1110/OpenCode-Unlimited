#!/usr/bin/env bash
set -euo pipefail

# opencode-unlimited install for Linux
# Mirrors install.ps1 but targets XDG paths and shell rc files.

root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bin="$root/bin"
entry="$bin/opencode-unlimited"
ps1="$bin/opencode-unlimited.ps1"
plugin_src="$root/plugins/unlimited-shield.js"
bridge="$root/lib/proxy-bridge.js"

ok()   { printf '  [+] %s\n' "$1"; }
bad()  { printf '  [x] %s\n' "$1" >&2; exit 1; }
info() { printf '      %s\n' "$1"; }

printf '==> opencode-unlimited install\n'

for required in "$entry" "$ps1" "$plugin_src" "$bridge"; do
  if [[ ! -e "$required" ]]; then bad "missing build artifact: $required"; fi
done
ok "build artifacts present"

if command -v node >/dev/null 2>&1; then
  ok "node $(node --version)"
else
  info "node not found: proxy bridge and -Db rotation stay unavailable"
fi

# XDG config dir
if [[ -z "${XDG_CONFIG_HOME:-}" ]]; then
  config_dir="$HOME/.config/opencode"
else
  config_dir="$XDG_CONFIG_HOME/opencode"
fi
plugin_dir="$config_dir/plugins"
plugin_dst="$plugin_dir/unlimited-shield.js"

mkdir -p "$plugin_dir"
cp -f "$plugin_src" "$plugin_dst"
ok "plugin deployed: $plugin_dst"

# PATH
if [[ -z "${BIN_DIR_ADDED:-}" ]]; then
  shell_rc=""
  if [[ -n "${ZSH_VERSION:-}" ]]; then shell_rc="$HOME/.zshrc"; fi
  if [[ -z "$shell_rc" && -f "$HOME/.bashrc" ]]; then shell_rc="$HOME/.bashrc"; fi
  if [[ -z "$shell_rc" && -f "$HOME/.profile" ]]; then shell_rc="$HOME/.profile"; fi
  if [[ -z "$shell_rc" ]]; then shell_rc="$HOME/.bashrc"; fi

  if ! grep -qF "$bin" "$shell_rc" 2>/dev/null; then
    {
      printf '\n# opencode-unlimited\n'
      printf 'export PATH="%s:$PATH"\n' "$bin"
    } >> "$shell_rc"
    ok "added to user PATH in $shell_rc: $bin"
    info "open a new terminal or run: source $shell_rc"
  else
    ok "already on PATH in $shell_rc: $bin"
  fi
  export PATH="$bin:$PATH"
fi

chmod +x "$entry"

if command -v pwsh >/dev/null 2>&1; then
  pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File "$ps1" install
else
  info "pwsh not found: install step (slash commands, org id) skipped; run install again after installing powershell"
fi

printf '\n'
printf '  next:\n'
info "opencode-unlimited status     identity, plugin, network, bucket"
info "opencode-unlimited id         rotate the project id"
info "opencode-unlimited test       probe the bucket on this IP (free)"
info "opencode-unlimited proxy set socks5://127.0.0.1:1080   optional IP path"
printf '\n'
ok "installed"

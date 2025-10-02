#!/usr/bin/env bash
# network-toolkit.sh
# A tiny network diagnostics helper for Linux.
# Commands used: ping, traceroute, dig, curl.
# License: MIT

set -euo pipefail

VERSION="0.1.0"

usage() {
  cat <<'EOF'
network-toolkit.sh - simple network diagnostics

Usage:
  network-toolkit.sh ping <host> [count]
  network-toolkit.sh trace <host>
  network-toolkit.sh dns <domain> [record=A]
  network-toolkit.sh http <url> [method=GET]
  network-toolkit.sh --help | -h
  network-toolkit.sh --version

Examples:
  network-toolkit.sh ping github.com 5
  network-toolkit.sh trace google.com
  network-toolkit.sh dns example.com MX
  network-toolkit.sh http https://example.com GET
EOF
}

need() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Error: '$1' is required but not installed." >&2
    exit 127
  }
}

cmd_ping() {
  need ping
  local host="${1:-}"; local count="${2:-4}"
  [[ -z "$host" ]] && { echo "Host required."; exit 2; }
  echo ">> ping -c $count $host"
  ping -c "$count" "$host"
}

cmd_trace() {
  # Use traceroute if available, else fall back to tracepath
  if command -v traceroute >/dev/null 2>&1; then
    local tracer="traceroute"
  else
    need tracepath
    local tracer="tracepath"
  fi
  local host="${1:-}"
  [[ -z "$host" ]] && { echo "Host required."; exit 2; }
  echo ">> $tracer $host"
  "$tracer" "$host"
}

cmd_dns() {
  need dig
  local domain="${1:-}"; local rr="${2:-A}"
  [[ -z "$domain" ]] && { echo "Domain required."; exit 2; }
  echo ">> dig +nocmd $domain $rr +noall +answer"
  dig +nocmd "$domain" "$rr" +noall +answer
}

cmd_http() {
  need curl
  local url="${1:-}"; local method="${2:-GET}"
  [[ -z "$url" ]] && { echo "URL required."; exit 2; }
  echo ">> curl -sS -X $method -w '\nHTTP %{http_code}\n' -o /tmp/ntk_body.$$ $url"
  curl -sS -X "$method" -w '\nHTTP %{http_code}\n' -o "/tmp/ntk_body.$$" "$url"
  echo ">> Response (first 20 lines):"
  head -n 20 "/tmp/ntk_body.$$" || true
  rm -f "/tmp/ntk_body.$$"
}

main() {
  case "${1:-}" in
    ping) shift; cmd_ping "$@";;
    trace) shift; cmd_trace "$@";;
    dns) shift; cmd_dns "$@";;
    http) shift; cmd_http "$@";;
    --help|-h|"") usage;;
    --version) echo "$VERSION";;
    *) echo "Unknown command: $1"; usage; exit 2;;
  esac
}

main "$@"

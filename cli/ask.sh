#!/usr/bin/env bash
API_URL=${API_URL:-http://localhost:4000}
AUTH_TOKEN_FILE="$HOME/.termuxcoder/token"

function login() {
  read -p "Username: " u
  read -s -p "Password: " p; echo
  tok=$(curl -s $API_URL/auth/api/login \
    -H "Content-Type: application/json" \
    -d "{\"username\":\"$u\",\"password\":\"$p\"}" | jq -r .token)
  echo $tok > $AUTH_TOKEN_FILE
  echo "✅ Logged in."
}

function ask() {
  local prompt="$*"
  token=$(cat $AUTH_TOKEN_FILE)
  curl -s "$API_URL/agent/chat" \
    -H "Authorization: Bearer $token" \
    -H "Content-Type: application/json" \
    -d "{\"prompt\": \"$prompt\"}" | jq -r .reply
}

case "$1" in
  login) login ;;
  ask) shift; ask "$@" ;;
  *) echo "Usage: termuxcoder {login|ask <prompt>}" ;;
esac

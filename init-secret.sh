#!/bin/sh
set -e

rm -f /rails/tmp/pids/server.pid

# Cria a pasta caso não exista (agora como root, sem erro)
mkdir -p /shared_data

SECRET_FILE="/shared_data/secret_key_base.txt"

if [ ! -f "$SECRET_FILE" ]; then
  cat /dev/urandom | tr -dc 'a-f0-9' | fold -w 128 | head -n 1 > "$SECRET_FILE"
fi

export SECRET_KEY_BASE=$(cat "$SECRET_FILE" | tr -d '\n' | tr -d '\r')

exec "$@"
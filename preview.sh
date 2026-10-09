#!/usr/bin/env bash
# Local preview with the legal notice details from .env (which git ignores).
cd "$(dirname "$0")" || exit 1
if [ -f .env ]; then set -a; . ./.env; set +a; else echo "No .env found: the legal notice shows placeholders."; fi
exec hugo server -D "$@"

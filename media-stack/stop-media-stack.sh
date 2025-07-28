#!/bin/bash
# Stops and removes all containers in the media-stack.
cd "$(dirname "$0")"
echo "🛑 Stopping the full media stack..."
docker compose down
echo "✅ The full media stack is down."

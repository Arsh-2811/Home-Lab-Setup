#!/bin/bash
# Starts all services in the media-stack.
cd "$(dirname "$0")"
echo "🚀 Starting the full media stack..."
docker compose up -d
echo "✅ The full media stack is up and running."

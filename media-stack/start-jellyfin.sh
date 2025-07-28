#!/bin/bash
# Starts only the Jellyfin container.
cd "$(dirname "$0")"
echo "🟢 Starting Jellyfin..."
docker compose up -d jellyfin
echo "✅ Jellyfin is up and running."

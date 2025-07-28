#!/bin/bash
# Stops all services EXCEPT Jellyfin.
cd "$(dirname "$0")"
echo "🟠 Stopping the download clients and Arr stack..."
docker compose stop gluetun qbittorrent prowlarr sonarr radarr jellyseerr
echo "✅ Download stack stopped. Jellyfin remains active."

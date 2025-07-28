#!/bin/bash
#
# stop-all.sh: Finds all docker-compose.yml files and stops the services.
#

echo "🛑 Stopping all Docker services..."
echo ""

# Find all docker-compose.yml files and loop through them
# Using "sort -r" attempts to stop services in reverse order, which can help with dependencies.
find . -type f -name "docker-compose.yml" | sort -r | while read -r compose_file; do
    dir=$(dirname "${compose_file}")
    echo "--------------------------------------------------"
    echo "Bringing DOWN services in: ${dir}"
    echo "--------------------------------------------------"
    (cd "${dir}" && docker compose down)
    echo ""
done

echo "✅ All services have been stopped."

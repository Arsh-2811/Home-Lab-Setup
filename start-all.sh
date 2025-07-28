#!/bin/bash
#
# start-all.sh: Finds all docker-compose.yml files and starts the services.
#

echo "🚀 Starting all Docker services..."
echo ""

# Find all docker-compose.yml files and loop through them
find . -type f -name "docker-compose.yml" | while read -r compose_file; do
    dir=$(dirname "${compose_file}")
    echo "--------------------------------------------------"
    echo "Bringing UP services in: ${dir}"
    echo "--------------------------------------------------"
    (cd "${dir}" && docker compose up -d)
    echo ""
done

echo "✅ All services have been started."

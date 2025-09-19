#!/bin/bash

# Simple Update Script für Private Repositories
# Für Portainer mit lokaler docker-compose.yml

set -e

STACK_NAME="tram-departures"
COMPOSE_FILE="docker-compose.local.yml"

echo "🚋 Updating Tram Departures Service..."

# Git pull
echo "📡 Pulling latest changes..."
git pull origin main

# Build and deploy with Portainer
echo "🔨 Building and deploying..."

# Stop existing containers
echo "⏹️  Stopping existing containers..."
docker-compose -f "$COMPOSE_FILE" down

# Build new image
echo "🏗️  Building new image..."
docker-compose -f "$COMPOSE_FILE" build --no-cache

# Start new containers
echo "▶️  Starting new containers..."
docker-compose -f "$COMPOSE_FILE" up -d

# Check health
echo "🏥 Checking application health..."
sleep 10

if docker ps --format 'table {{.Names}}' | grep -q tram-departures-app; then
    echo "✅ Update successful!"
    echo "🌐 Application running at: http://localhost:3000"
else
    echo "❌ Update failed!"
    docker logs tram-departures-app
    exit 1
fi

# Cleanup
echo "🧹 Cleaning up old images..."
docker image prune -f

echo "🎉 Update completed!"
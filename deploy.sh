#!/bin/bash

# Tram Departures Deployment Script
# Usage: ./deploy.sh [version]

set -e

# Configuration
APP_NAME="tram-departures"
IMAGE_NAME="tram-departures"
CONTAINER_NAME="tram-departures-app"
GIT_REPO="https://github.com/marcprojer/tram-departures-service.git"
DEPLOY_DIR="/opt/tram-departures"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root or with docker permissions
check_permissions() {
    if ! docker info >/dev/null 2>&1; then
        log_error "Docker is not running or you don't have permission to access it"
        exit 1
    fi
}

# Pull latest code from git
update_code() {
    log_info "Updating code from Git repository..."
    
    if [ ! -d "$DEPLOY_DIR" ]; then
        log_info "Cloning repository..."
        git clone "$GIT_REPO" "$DEPLOY_DIR"
    else
        log_info "Pulling latest changes..."
        cd "$DEPLOY_DIR"
        git pull origin main
    fi
    
    cd "$DEPLOY_DIR"
}

# Build new Docker image
build_image() {
    local version=${1:-"latest"}
    log_info "Building Docker image with tag: $version"
    
    # Build new image
    docker build -t "$IMAGE_NAME:$version" .
    
    # Tag as latest if not already
    if [ "$version" != "latest" ]; then
        docker tag "$IMAGE_NAME:$version" "$IMAGE_NAME:latest"
    fi
}

# Deploy application
deploy() {
    log_info "Deploying application..."
    
    # Stop and remove existing container
    if docker ps -a --format 'table {{.Names}}' | grep -q "$CONTAINER_NAME"; then
        log_info "Stopping existing container..."
        docker stop "$CONTAINER_NAME" || true
        docker rm "$CONTAINER_NAME" || true
    fi
    
    # Start new container
    log_info "Starting new container..."
    docker-compose up -d
    
    # Wait for health check
    log_info "Waiting for application to be healthy..."
    sleep 10
    
    # Check if container is running
    if docker ps --format 'table {{.Names}}' | grep -q "$CONTAINER_NAME"; then
        log_info "✅ Deployment successful!"
        log_info "Application is running at: http://localhost:3000"
    else
        log_error "❌ Deployment failed!"
        docker logs "$CONTAINER_NAME"
        exit 1
    fi
}

# Cleanup old images
cleanup() {
    log_info "Cleaning up old Docker images..."
    docker image prune -f
}

# Rollback to previous version
rollback() {
    log_warn "Rolling back to previous version..."
    # This would need to be implemented based on your versioning strategy
    docker-compose down
    docker run -d --name "$CONTAINER_NAME" -p 3000:3000 "$IMAGE_NAME:previous"
}

# Show logs
show_logs() {
    docker logs -f "$CONTAINER_NAME"
}

# Main deployment process
main() {
    local version=${1:-"latest"}
    
    log_info "🚀 Starting deployment of $APP_NAME"
    
    check_permissions
    update_code
    build_image "$version"
    deploy
    cleanup
    
    log_info "🎉 Deployment completed successfully!"
    log_info "Run './deploy.sh logs' to view application logs"
}

# Handle command line arguments
case "${1:-deploy}" in
    "deploy")
        main "${2:-latest}"
        ;;
    "logs")
        show_logs
        ;;
    "rollback")
        rollback
        ;;
    "status")
        docker ps | grep "$CONTAINER_NAME" || echo "Container not running"
        ;;
    "stop")
        docker stop "$CONTAINER_NAME"
        ;;
    "start")
        docker start "$CONTAINER_NAME"
        ;;
    "restart")
        docker restart "$CONTAINER_NAME"
        ;;
    *)
        echo "Usage: $0 {deploy|logs|rollback|status|stop|start|restart} [version]"
        echo "  deploy [version] - Deploy application (default: latest)"
        echo "  logs            - Show application logs"
        echo "  rollback        - Rollback to previous version"
        echo "  status          - Show container status"
        echo "  stop            - Stop application"
        echo "  start           - Start application"
        echo "  restart         - Restart application"
        exit 1
        ;;
esac
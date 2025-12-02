#!/bin/bash
# Wrapper script for docker-compose with both yml files
# Usage: ./dc.sh [command] [options]
#
# Examples:
#   ./dc.sh up -d              # Start all services
#   ./dc.sh down               # Stop all services
#   ./dc.sh ps                 # List containers
#   ./dc.sh logs -f backend    # Follow backend logs
#   ./dc.sh exec backend bash  # Shell into backend
#   ./dc.sh build backend      # Build backend image
#   ./dc.sh restart            # Restart all services

docker-compose -f pwd.yml -f docker-compose.override.yml "$@"

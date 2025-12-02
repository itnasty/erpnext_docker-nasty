#!/bin/bash
# ============================================
# Frappe Site Restore Script
# ============================================
# Usage: ./restore-site.sh [site_name] [backup_dir]
# Example: ./restore-site.sh frontend /home/frappe/backup
# ============================================

set -e

# Configuration
SITE_NAME="${1:-${SITE_NAME:-frontend}}"
BACKUP_DIR="${2:-/home/frappe/backup}"
DB_ROOT_PASSWORD="${DB_ROOT_PASSWORD:-admin}"

echo "============================================"
echo "🔄 Frappe Site Restore Script"
echo "============================================"
echo "Site: $SITE_NAME"
echo "Backup Directory: $BACKUP_DIR"
echo "============================================"

# Check if backup directory exists
if [ ! -d "$BACKUP_DIR" ]; then
    echo "❌ Backup directory not found: $BACKUP_DIR"
    exit 1
fi

# Find latest backup files
echo ""
echo "🔍 Looking for backup files..."

DB_BACKUP=$(ls -t ${BACKUP_DIR}/*-database.sql.gz 2>/dev/null | head -1)
FILES_BACKUP=$(ls -t ${BACKUP_DIR}/*-files.tar 2>/dev/null | head -1)
PRIVATE_BACKUP=$(ls -t ${BACKUP_DIR}/*-private-files.tar 2>/dev/null | head -1)
CONFIG_BACKUP=$(ls -t ${BACKUP_DIR}/*-site_config_backup.json 2>/dev/null | head -1)

# Validate database backup exists
if [ -z "$DB_BACKUP" ]; then
    echo "❌ No database backup found in ${BACKUP_DIR}"
    echo "   Expected file pattern: *-database.sql.gz"
    exit 1
fi

# Display found files
echo ""
echo "📦 Found backup files:"
echo "   Database:      $(basename "$DB_BACKUP")"
[ -n "$FILES_BACKUP" ] && echo "   Public Files:  $(basename "$FILES_BACKUP")"
[ -n "$PRIVATE_BACKUP" ] && echo "   Private Files: $(basename "$PRIVATE_BACKUP")"
[ -n "$CONFIG_BACKUP" ] && echo "   Site Config:   $(basename "$CONFIG_BACKUP")"

# Confirmation prompt
echo ""
read -p "⚠️  This will OVERWRITE the existing site. Continue? (y/N): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "❌ Restore cancelled."
    exit 0
fi

# Build restore command
echo ""
echo "🔄 Starting restore..."

RESTORE_CMD="bench --site $SITE_NAME restore $DB_BACKUP --db-root-password $DB_ROOT_PASSWORD"

if [ -n "$FILES_BACKUP" ]; then
    RESTORE_CMD="$RESTORE_CMD --with-public-files $FILES_BACKUP"
fi

if [ -n "$PRIVATE_BACKUP" ]; then
    RESTORE_CMD="$RESTORE_CMD --with-private-files $PRIVATE_BACKUP"
fi

# Execute restore
echo "   Running: bench --site $SITE_NAME restore [backup] --db-root-password ***"
$RESTORE_CMD

# Wait for restore to complete fully
echo ""
echo "⏳ Waiting for restore to complete..."
sleep 5

# Verify restore succeeded before migrating
echo ""
echo "🔍 Verifying restore..."
if ! bench --site $SITE_NAME list-apps > /dev/null 2>&1; then
    echo "❌ Restore verification failed. Please check the backup file and try again."
    exit 1
fi
echo "✅ Restore verified successfully"

# Show restored apps
echo ""
echo "📋 Apps from backup:"
bench --site $SITE_NAME list-apps

# Post-restore tasks
echo ""
echo "🔄 Running post-restore tasks..."

echo ""
echo "   → Running migrations (this may take several minutes)..."
bench --site $SITE_NAME migrate

echo ""
echo "   → Clearing cache..."
bench --site $SITE_NAME clear-cache
bench --site $SITE_NAME clear-website-cache

echo ""
echo "   → Disabling developer mode..."
bench --site $SITE_NAME set-config -p developer_mode 0 || true

echo ""
echo "============================================"
echo "✅ Restore completed successfully!"
echo "============================================"
echo ""
echo "Installed apps:"
bench --site $SITE_NAME list-apps
echo ""
echo "Next steps:"
echo "  1. Verify the site: bench --site $SITE_NAME doctor"
echo "  2. Access your site at: http://localhost:8080"
echo ""

#!/bin/bash
# ============================================
# Frappe Post-Install Script
# ============================================
# Installs apps to site and runs migrations
# Usage: ./post-install.sh [site_name]
# Example: ./post-install.sh frontend
# ============================================

set -e

# Configuration
SITE_NAME="${1:-${SITE_NAME:-frontend}}"

echo "============================================"
echo "📦 Frappe Post-Install Script"
echo "============================================"
echo "Site: $SITE_NAME"
echo "============================================"

# List of apps to install (in dependency order)
APPS=(
    "hrms"
    "insights"
    "frappe_s3_attachment"
    "nsty"
)

# Check if site exists
if ! bench --site $SITE_NAME list-apps > /dev/null 2>&1; then
    echo "❌ Site '$SITE_NAME' does not exist!"
    echo "   Create it first with: bench new-site $SITE_NAME"
    exit 1
fi

# Show currently installed apps
echo ""
echo "📋 Currently installed apps:"
bench --site $SITE_NAME list-apps
echo ""

# Register apps in apps.txt if not already there
APPS_TXT="/home/frappe/frappe-bench/sites/apps.txt"
echo "📝 Registering apps in apps.txt..."
for app in "${APPS[@]}"; do
    if [ -d "/home/frappe/frappe-bench/apps/$app" ]; then
        if ! grep -q "^$app$" "$APPS_TXT" 2>/dev/null; then
            echo "$app" >> "$APPS_TXT"
            echo "   ✓ Added $app to apps.txt"
        else
            echo "   - $app already in apps.txt"
        fi
    fi
done
echo ""

# Install each app
echo "🔧 Installing apps..."
for app in "${APPS[@]}"; do
    echo ""
    echo "   → Installing: $app"

    # Check if app exists in apps folder
    if [ -d "/home/frappe/frappe-bench/apps/$app" ]; then
        # Install app (|| true to continue if already installed)
        bench --site $SITE_NAME install-app $app || {
            echo "   ⚠️  $app may already be installed or failed. Continuing..."
        }
    else
        echo "   ⚠️  App directory not found: /home/frappe/frappe-bench/apps/$app"
        echo "      Run 'bench get-app' first or check the app name."
    fi
done

# Run migrations
echo ""
echo "🔄 Running migrations..."
bench --site $SITE_NAME migrate

# Clear cache
echo ""
echo "🧹 Clearing cache..."
bench --site $SITE_NAME clear-cache
bench --site $SITE_NAME clear-website-cache

# Build assets (optional)
# echo ""
# echo "🏗️  Building assets..."
# bench build --production

# Show final status
echo ""
echo "============================================"
echo "✅ Post-install completed!"
echo "============================================"
echo ""
echo "📋 Installed apps:"
bench --site $SITE_NAME list-apps
echo ""
echo "Next steps:"
echo "  1. Access your site"
echo "  2. Configure app-specific settings"
echo "  3. For S3 attachments, configure AWS credentials in site_config.json"
echo ""

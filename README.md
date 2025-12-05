# Frappe Docker Deployment

Custom Frappe/ERPNext Docker deployment with HRMS, Insights, S3 Attachments, and NSTY apps.

## 📁 Folder Structure

```
frappe_docker/
├── backup/                     # Backup files (gitignored)
├── config/
│   └── apps.json               # Apps configuration
├── images/
│   └── custom-apps.Dockerfile  # Custom Docker image
├── scripts/
│   ├── dc.sh                   # Docker-compose wrapper script
│   ├── post-install.sh         # App installation script
│   └── restore-site.sh         # Backup restore script
├── sites/                      # Frappe sites (auto-generated)
├── pwd.yml                     # Main compose file (from frappe_docker)
├── docker-compose.override.yml # Custom image overrides
├── .env                        # Environment variables (gitignored)
├── .env.example                # Environment template
├── .gitattributes              # Line ending normalization
├── .gitignore                  # Git ignore rules
└── README.md                   # This file
```

## 🚀 Quick Start

### 1. Setup Environment

```bash
# Copy environment template
cp .env.example .env

# Edit with your values
nano .env
```

**Required `.env` values to modify:**

```env
# GitHub token for private repos (generate at https://github.com/settings/tokens)
GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# ERPNext admin password
ADMIN_PASSWORD=your_secure_password

# MariaDB root password
DB_ROOT_PASSWORD=your_secure_password

# S3 credentials (if using S3 attachments)
S3_ACCESS_KEY=your_access_key
S3_SECRET_KEY=your_secret_key
S3_BUCKET=your_bucket_name
```

### 2. Build Custom Image

```bash
# Build using values from .env file
source .env && docker build -t custom-frappe:v15 \
  -f images/custom-apps.Dockerfile \
  --build-arg GITHUB_TOKEN=$GITHUB_TOKEN \
  --build-arg FRAPPE_VERSION=$FRAPPE_VERSION .

# Or use docker-compose to build (also reads from .env)
./scripts/dc.sh build backend
```

### 3. Start Services

```bash
# Using the wrapper script (recommended)
./scripts/dc.sh up -d

# Or manually with both compose files
docker-compose -f pwd.yml -f docker-compose.override.yml up -d
```

### 4. Install Apps to Site

```bash
# Run post-install script
./scripts/dc.sh exec backend bash //home/frappe/scripts/post-install.sh

# Or with docker exec (use // prefix on Windows Git Bash)
docker exec -it frappe_docker-backend-1 bash //home/frappe/scripts/post-install.sh
```

> **Note (Windows Git Bash):** Use `//home/...` (double slash) to prevent Git Bash from converting Linux paths to Windows paths.

### 5. Restore from Backup (Optional)

1. Place backup files in `./backup/` folder:
   - `*-database.sql.gz` (required)
   - `*-site_config_backup.json` (optional - site configuration)
   - `*-files.tar` (optional - public files)
   - `*-private-files.tar` (optional - private files)

2. Run restore script:

```bash
# ⚠️ IMPORTANT: Set DB_ROOT_PASSWORD (must match MariaDB root password in pwd.yml)
./scripts/dc.sh exec -e DB_ROOT_PASSWORD=<your_db_root_password> backend bash //home/frappe/scripts/restore-site.sh
```

> **Note:** The restore script will:
> 1. Restore the database from backup
> 2. Verify the restore was successful
> 3. Run migrations to update to current app versions
> 4. Clear cache
>
> If the backup already contains your apps (hrms, insights, etc.), you don't need to run the post-install script.

## 📦 Installed Apps

| App | Branch | Description |
|-----|--------|-------------|
| HRMS | version-15 | Human Resource Management |
| Insights | version-3 | Data Analytics & Reporting |
| S3 Attachments | main | AWS S3 File Storage |
| NSTY | develop | Custom Application |

## 🔧 Common Commands

### Using the Wrapper Script (Recommended)

The `scripts/dc.sh` script wraps docker-compose with both yml files:

```bash
# Start all services
./scripts/dc.sh up -d

# Stop all services
./scripts/dc.sh down

# List containers
./scripts/dc.sh ps

# View logs
./scripts/dc.sh logs -f backend

# Follow all logs
./scripts/dc.sh logs -f

# Rebuild and start
./scripts/dc.sh up -d --build

# Restart services
./scripts/dc.sh restart

# Shell access (frappe user)
./scripts/dc.sh exec backend bash

# Shell access (root user)
./scripts/dc.sh exec -u root backend bash
```

### Direct Docker Commands

```bash
# If not using the wrapper script
docker-compose -f pwd.yml -f docker-compose.override.yml up -d
docker-compose -f pwd.yml -f docker-compose.override.yml down
docker-compose -f pwd.yml -f docker-compose.override.yml ps
```

### Bench Commands

```bash
# List installed apps
bench --site frontend list-apps

# Install an app
bench --site frontend install-app <app_name>

# Run migrations
bench --site frontend migrate

# Clear cache
bench --site frontend clear-cache

# Create new site
bench new-site <site_name> --admin-password <password>

# Backup site
bench --site frontend backup --with-files

# Get new app
bench get-app <repo_url> --branch <branch>
```

## 🔄 Backup & Restore

### Manual Backup

```bash
docker exec -it frappe_docker-backend-1 bench --site frontend backup --with-files
```

### Restore from Backup

1. Place backup files in `./backup/` folder:
   - `*-database.sql.gz` (required)
   - `*-site_config_backup.json` (optional - site configuration)
   - `*-files.tar` (optional - public files)
   - `*-private-files.tar` (optional - private files)

2. Run restore script:
```bash
# ⚠️ Set DB_ROOT_PASSWORD (must match MariaDB root password in pwd.yml)
./scripts/dc.sh exec -e DB_ROOT_PASSWORD=<your_db_root_password> backend bash //home/frappe/scripts/restore-site.sh
```

> **Important:** The script verifies the restore completed before running migrations. If verification fails, it will stop and you can retry. Migrations can take several minutes for large databases.

### Windows: Copy Backups to Container

```powershell
docker cp "C:\path\to\backup\database.sql.gz" frappe_docker-backend-1:/home/frappe/backup/
docker cp "C:\path\to\backup\files.tar" frappe_docker-backend-1:/home/frappe/backup/
docker cp "C:\path\to\backup\private-files.tar" frappe_docker-backend-1:/home/frappe/backup/
```

## 🛠️ Troubleshooting

### Windows Line Ending Errors (`$'\r': command not found`)

If you see errors like `$'\r': command not found` or `syntax error near unexpected token '$'do\r''` when running scripts, the shell scripts have Windows (CRLF) line endings instead of Unix (LF).

**Fix:**
```bash
# Delete and re-checkout the scripts to get correct line endings
rm scripts/*.sh
git checkout -- scripts/
```

Or convert manually using dos2unix inside the container:
```bash
./scripts/dc.sh exec -u root backend bash -c "apt-get update && apt-get install -y dos2unix && dos2unix /home/frappe/scripts/*.sh"
```

### pkg-config / Build Issues

```bash
docker exec -u root frappe_docker-backend-1 apt-get update
docker exec -u root frappe_docker-backend-1 apt-get install -y \
    gcc build-essential python3-dev libmariadb-dev-compat libmariadb-dev pkg-config
```

### Module Not Found

```bash
docker exec -it frappe_docker-backend-1 pip install -e /home/frappe/frappe-bench/apps/<app_name>
```

### Permission Issues

```bash
docker exec -u root frappe_docker-backend-1 chown -R frappe:frappe /home/frappe/frappe-bench
```

### Site Not Loading

```bash
# Check site status
bench --site frontend doctor

# Rebuild assets
bench build --production

# Restart services
./scripts/dc.sh restart
```

## ⚙️ S3 Attachment Configuration

After installing `frappe_s3_attachment`, configure in `site_config.json`:

```json
{
  "s3_bucket": "your-bucket-name",
  "s3_access_key": "your-access-key",
  "s3_secret_key": "your-secret-key",
  "s3_region": "ap-southeast-1"
}
```

Or via bench:

```bash
bench --site frontend set-config s3_bucket "your-bucket-name"
bench --site frontend set-config s3_access_key "your-access-key"
bench --site frontend set-config s3_secret_key "your-secret-key"
bench --site frontend set-config s3_region "ap-southeast-1"
```

## 📝 Notes

- **First-time setup** requires manual site creation with admin password
- **Backup restore** should be manually triggered (safety measure)
- **Major version upgrades** should be tested in staging first
- **Private repos** require SSH keys or access tokens

## 📚 Resources

- [Frappe Framework Docs](https://frappeframework.com/docs)
- [ERPNext Docs](https://docs.erpnext.com/)
- [Frappe Docker Repo](https://github.com/frappe/frappe_docker)
- [HRMS Docs](https://frappehr.com/docs)

## 📄 License

See individual app repositories for their respective licenses.

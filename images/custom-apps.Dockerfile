# ============================================
# Custom Frappe Docker Image with Apps
# ============================================
# Build: docker build -t custom-frappe:v15 -f images/custom-apps.Dockerfile .
# ============================================

ARG FRAPPE_VERSION=v15
FROM frappe/erpnext:${FRAPPE_VERSION}

# Redeclare ARG after FROM to make it available in build stage
ARG GITHUB_TOKEN

# ============================================
# Install System Dependencies
# ============================================
USER root

RUN apt-get update && apt-get install -y \
    gcc \
    build-essential \
    python3-dev \
    libmariadb-dev-compat \
    libmariadb-dev \
    pkg-config \
    git \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# ============================================
# Switch to frappe user for app installation
# ============================================
USER frappe
WORKDIR /home/frappe/frappe-bench

# ============================================
# Get Custom Apps
# ============================================
# HRMS - Human Resource Management System
RUN bench get-app --skip-assets https://github.com/frappe/hrms --branch version-15

# Insights - Data Analytics
RUN bench get-app --skip-assets https://github.com/frappe/insights --branch version-3

# S3 Attachments
RUN bench get-app --skip-assets https://github.com/zerodhatech/Frappe-attachments-s3.git

# NSTY Custom App
# Private repo (with token)
RUN bench get-app --skip-assets https://${GITHUB_TOKEN}@github.com/matiyas-solutions/nsty --branch develop

# ============================================
# Install Python Dependencies for Apps
# ============================================
RUN pip install --no-cache-dir \
    -e /home/frappe/frappe-bench/apps/hrms \
    -e /home/frappe/frappe-bench/apps/insights \
    -e /home/frappe/frappe-bench/apps/frappe_s3_attachment \
    -e /home/frappe/frappe-bench/apps/nsty

# ============================================
# Build Assets (optional - can speed up startup)
# ============================================
# RUN bench build --production

# ============================================
# Labels
# ============================================
LABEL maintainer="Your Name <your.email@example.com>"
LABEL description="Custom Frappe/ERPNext image with HRMS, Insights, S3 Attachments, and NSTY"
LABEL version="${FRAPPE_VERSION}"

#!/bin/bash
set -euo pipefail

apt-get update -y
apt-get install -y docker.io docker-compose git wget

systemctl start docker
systemctl enable docker
usermod -aG docker ubuntu

mkdir -p /home/ubuntu/progetto-ecommerce
git clone ${app_repo} /home/ubuntu/progetto-ecommerce || true

cat > /home/ubuntu/progetto-ecommerce/.env <<EOF
DB_HOST=${db_host}
DB_USER=${db_user}
DB_PASS=${db_pass}
DB_NAME=${db_name}
EOF

chown -R ubuntu:ubuntu /home/ubuntu/progetto-ecommerce

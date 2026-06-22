#!/bin/bash

clear

# ===== Colors =====
RED='\033[0;31m'
GRN='\033[0;32m'
CYN='\033[0;36m'
YEL='\033[1;33m'
NC='\033[0m'

# ===== Banner =====
echo -e "${YEL}"
cat << "EOF"
 ███████╗ ███████╗
 ██╔════╝ ██╔════╝
 ███████╗ ██║  ███╗
 ╚════██║ ██║   ██║
 ███████║ ╚██████╔╝
 ╚══════╝  ╚═════╝
EOF
echo -e "${NC}"

echo -e "${GRN}🔥 Installing Pterodactyl Panel (Docker) 🔥${NC}"

# ===== Root Check =====
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}❌ Please run as root${NC}"
  exit 1
fi

# ===== Install dependencies =====
echo -e "${YEL}📦 Installing dependencies...${NC}"
apt update -y
apt install -y docker.io docker-compose-plugin curl

# ===== Start Docker =====
systemctl enable docker
systemctl start docker

# ===== Create project folder =====
echo -e "${CYN}📁 Setting up directories...${NC}"
mkdir -p /opt/pterodactyl
cd /opt/pterodactyl || exit

mkdir -p data/{database,var,nginx,certs,logs}

# ===== Variables (EDIT THESE IF NEEDED) =====
DB_PASS="StrongPassword123!"
ROOT_PASS="RootPassword123!"
APP_URL="http://$(hostname -I | awk '{print $1}'):8080"

# ===== docker-compose.yml =====
echo -e "${CYN}📝 Creating docker-compose.yml...${NC}"

cat <<EOF > docker-compose.yml
version: "3.8"

services:
  database:
    image: mariadb:10.5
    restart: always
    command: --default-authentication-plugin=mysql_native_password
    volumes:
      - "./data/database:/var/lib/mysql"
    environment:
      MYSQL_ROOT_PASSWORD: "${ROOT_PASS}"
      MYSQL_DATABASE: "panel"
      MYSQL_USER: "pterodactyl"
      MYSQL_PASSWORD: "${DB_PASS}"

  cache:
    image: redis:alpine
    restart: always

  panel:
    image: ghcr.io/pterodactyl/panel:latest
    restart: always
    depends_on:
      - database
      - cache
    ports:
      - "8080:80"
    volumes:
      - "./data/var:/app/var"
      - "./data/logs:/app/storage/logs"
      - "./data/nginx:/etc/nginx/http.d"
      - "./data/certs:/etc/letsencrypt"
    environment:
      APP_URL: "${APP_URL}"
      APP_TIMEZONE: "UTC"
      APP_SERVICE_AUTHOR: "admin@example.com"
      TRUSTED_PROXIES: "*"
      DB_PASSWORD: "${DB_PASS}"
      DB_HOST: "database"
      DB_PORT: "3306"
      APP_ENV: "production"
      CACHE_DRIVER: "redis"
      SESSION_DRIVER: "redis"
      QUEUE_DRIVER: "redis"
      REDIS_HOST: "cache"

networks:
  default:
    ipam:
      config:
        - subnet: 172.20.0.0/16
EOF

# ===== Start Containers =====
echo -e "${GRN}🚀 Starting containers...${NC}"
docker compose up -d

# ===== Wait for DB =====
echo -e "${YEL}⏳ Waiting for database...${NC}"
sleep 15

# ===== Initialize Panel =====
echo -e "${GRN}⚙️ Initializing panel...${NC}"
docker compose run --rm panel php artisan key:generate --force
docker compose run --rm panel php artisan migrate --seed --force

# ===== Create Admin =====
echo -e "${GRN}👤 Create Admin Account${NC}"
docker compose run --rm panel php artisan p:user:make

# ===== Done =====
echo -e "${GRN}✅ Installation Complete!${NC}"
echo -e "${YEL}🌐 Open: ${APP_URL}${NC}"

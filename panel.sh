#!/bin/bash

clear

# Colors
RED='\033[0;31m'
GRN='\033[0;32m'
CYN='\033[0;36m'
YEL='\033[1;33m'
NC='\033[0m' # No Color

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

echo -ne "${GRN}🔥 Please Subscribe \n"

for i in {1..3}; do
  echo -ne "${CYN}Subscribing To SanjitGaming"
  for dot in {1..3}; do
    echo -n "."
    sleep 0.3
  done
  echo -ne "\r                     \r"
done

echo -e "${GRN} Thanks for Subscribing! If Not Do It Rn${NC}\n"

sleep 1

echo -e "${YEL}X-> Installing Docker...${NC}"
apt update -y
apt install docker.io docker-compose-plugin -y

systemctl start docker
systemctl enable docker

echo -e "${CYN}X-> Setting up Pterodactyl Panel directories...${NC}"
mkdir -p pterodactyl/panel
cd pterodactyl/panel || exit

echo -e "${CYN}X-> Writing docker-compose.yml...${NC}"

cat <<EOF > docker-compose.yml
version: '3.8'

services:
  database:
    image: mariadb:10.5
    restart: always
    command: --default-authentication-plugin=mysql_native_password
    volumes:
      - "./data/database:/var/lib/mysql"
    environment:
      MYSQL_ROOT_PASSWORD: "root123"
      MYSQL_DATABASE: "panel"
      MYSQL_USER: "pterodactyl"
      MYSQL_PASSWORD: "pass123"

  cache:
    image: redis:alpine
    restart: always

  panel:
    image: ghcr.io/pterodactyl/panel:latest
    restart: always
    ports:
      - "8080:80"
    depends_on:
      - database
      - cache
    volumes:
      - "./data/var:/app/var"
      - "./data/logs:/app/storage/logs"
    environment:
      APP_URL: "http://localhost:8080"
      DB_PASSWORD: "pass123"
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

echo -e "${CYN}X-> Creating data directories...${NC}"
mkdir -p ./data/{database,var,logs}

echo -e "${GRN}X-> Starting Pterodactyl containers...${NC}"
docker compose up -d

echo -e "${YEL}X-> Waiting for database...${NC}"
sleep 15

echo -e "${GRN}X-> Initializing panel...${NC}"
docker compose run --rm panel php artisan key:generate --force
docker compose run --rm panel php artisan migrate --seed --force

echo -e "${GRN}X-> Creating Admin User...${NC}"
docker compose run --rm panel php artisan p:user:make

echo -e "${YEL}✅ All done! Open it manually on:${NC}"
echo -e "${CYN}http://YOUR_IP:8080${NC}"

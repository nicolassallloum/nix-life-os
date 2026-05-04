🔹 STEP 26 — Deployment Using Docker
1. Final Project Structure
Your project should look like this:
/u01/nix-life-os/├── backend/│   ├── Dockerfile│   ├── docker/│   │   └── php.ini│   ├── .env.production│   └── ...│├── frontend/│   ├── Dockerfile│   ├── nginx.conf│   └── ...│├── ai-engine/│   ├── Dockerfile│   ├── requirements.txt│   └── ...│├── docker/│   ├── nginx/│   │   └── default.conf│   └── postgres/│       └── init.sql│├── docker-compose.prod.yml└── .env.docker

2. Create Root Docker Environment File
Create this file:
nano /u01/nix-life-os/.env.docker
Paste:
APP_NAME=NIX_LIFE_OSAPP_ENV=productionAPP_DEBUG=falseAPP_URL=http://localhostDB_CONNECTION=pgsqlDB_HOST=postgresDB_PORT=5432DB_DATABASE=nixlifeos_dbDB_USERNAME=nixlifeos_userDB_PASSWORD=StrongProductionPassword123POSTGRES_DB=nixlifeos_dbPOSTGRES_USER=nixlifeos_userPOSTGRES_PASSWORD=StrongProductionPassword123BACKEND_PORT=8000FRONTEND_PORT=8080NGINX_PORT=80AI_ENGINE_PORT=5000TZ=Asia/Beirut

3. Laravel Backend Dockerfile
Create:
nano /u01/nix-life-os/backend/Dockerfile
Paste:
FROM php:8.3-fpmWORKDIR /var/www/htmlRUN apt-get update && apt-get install -y \    git \    curl \    unzip \    zip \    libpq-dev \    libzip-dev \    libpng-dev \    libonig-dev \    libxml2-dev \    && docker-php-ext-install \    pdo \    pdo_pgsql \    pgsql \    mbstring \    zip \    exif \    pcntl \    bcmath \    gd \    opcache \    && apt-get clean \    && rm -rf /var/lib/apt/lists/*COPY --from=composer:2 /usr/bin/composer /usr/bin/composerCOPY docker/php.ini /usr/local/etc/php/conf.d/custom.iniCOPY . .RUN composer install --no-dev --optimize-autoloader --no-interactionRUN chown -R www-data:www-data /var/www/html \    && chmod -R 775 storage bootstrap/cacheEXPOSE 9000CMD ["php-fpm"]

4. Laravel PHP Production Config
Create folder:
mkdir -p /u01/nix-life-os/backend/docker
Create file:
nano /u01/nix-life-os/backend/docker/php.ini
Paste:
memory_limit=512Mupload_max_filesize=50Mpost_max_size=50Mmax_execution_time=300max_input_time=300display_errors=Offlog_errors=Onerror_log=/proc/self/fd/2opcache.enable=1opcache.memory_consumption=256opcache.interned_strings_buffer=16opcache.max_accelerated_files=20000opcache.validate_timestamps=0opcache.save_comments=1opcache.fast_shutdown=1date.timezone=Asia/Beirut

5. Laravel Production Environment File
Create:
nano /u01/nix-life-os/backend/.env.production
Paste:
APP_NAME="NIX LIFE OS"APP_ENV=productionAPP_KEY=APP_DEBUG=falseAPP_URL=http://localhostLOG_CHANNEL=stackLOG_LEVEL=errorDB_CONNECTION=pgsqlDB_HOST=postgresDB_PORT=5432DB_DATABASE=nixlifeos_dbDB_USERNAME=nixlifeos_userDB_PASSWORD=StrongProductionPassword123SESSION_DRIVER=databaseSESSION_LIFETIME=120CACHE_STORE=databaseQUEUE_CONNECTION=databaseSANCTUM_STATEFUL_DOMAINS=localhost,127.0.0.1SESSION_DOMAIN=localhostAI_ENGINE_URL=http://ai-engine:5000FILESYSTEM_DISK=localBROADCAST_CONNECTION=logMAIL_MAILER=log
Important: after copying this file, Laravel will still need a real APP_KEY. The script below will generate it inside the container.

6. Vue Frontend Dockerfile
Create:
nano /u01/nix-life-os/frontend/Dockerfile
Paste:
FROM node:22-alpine AS buildWORKDIR /appCOPY package*.json ./RUN npm installCOPY . .RUN npm run buildFROM nginx:1.27-alpineCOPY nginx.conf /etc/nginx/conf.d/default.confCOPY --from=build /app/dist /usr/share/nginx/htmlEXPOSE 80CMD ["nginx", "-g", "daemon off;"]

7. Vue Frontend Nginx Config
Create:
nano /u01/nix-life-os/frontend/nginx.conf
Paste:
server {    listen 80;    server_name localhost;    root /usr/share/nginx/html;    index index.html;    client_max_body_size 50M;    location / {        try_files $uri $uri/ /index.html;    }    location /api/ {        proxy_pass http://nginx/api/;        proxy_http_version 1.1;        proxy_set_header Host $host;        proxy_set_header X-Real-IP $remote_addr;        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;        proxy_set_header X-Forwarded-Proto $scheme;    }}

8. Python AI Engine Dockerfile
Create:
nano /u01/nix-life-os/ai-engine/Dockerfile
Paste:
FROM python:3.12-slimWORKDIR /appRUN apt-get update && apt-get install -y \    build-essential \    libpq-dev \    curl \    && apt-get clean \    && rm -rf /var/lib/apt/lists/*COPY requirements.txt .RUN pip install --no-cache-dir -r requirements.txtCOPY . .EXPOSE 5000CMD ["python", "app.py"]

9. Python Requirements File
Create or update:
nano /u01/nix-life-os/ai-engine/requirements.txt
Paste:
fastapiuvicornpandasnumpyscikit-learnpsycopg2-binarypython-dotenvrequestspydantic

10. Python AI Engine App
If you do not already have a main Python API file, create:
nano /u01/nix-life-os/ai-engine/app.py
Paste:
from fastapi import FastAPIfrom datetime import datetimeapp = FastAPI(    title="NIX LIFE OS AI Engine",    version="1.0.0")@app.get("/")def root():    return {        "service": "NIX LIFE OS AI Engine",        "status": "running",        "timestamp": datetime.utcnow().isoformat()    }@app.get("/health")def health_check():    return {        "status": "healthy",        "service": "ai-engine"    }@app.get("/api/ai/daily-insights")def daily_insights():    return {        "status": "success",        "message": "Daily AI insights engine is running.",        "data": {            "finance": "Finance analysis ready.",            "health": "Health analysis ready.",            "projects": "Project analysis ready."        }    }
Update the Dockerfile command to use FastAPI properly:
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "5000"]
So the final /u01/nix-life-os/ai-engine/Dockerfile should be:
FROM python:3.12-slimWORKDIR /appRUN apt-get update && apt-get install -y \    build-essential \    libpq-dev \    curl \    && apt-get clean \    && rm -rf /var/lib/apt/lists/*COPY requirements.txt .RUN pip install --no-cache-dir -r requirements.txtCOPY . .EXPOSE 5000CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "5000"]

11. Production Nginx Reverse Proxy
Create folder:
mkdir -p /u01/nix-life-os/docker/nginx
Create:
nano /u01/nix-life-os/docker/nginx/default.conf
Paste:
server {    listen 80;    server_name localhost;    client_max_body_size 50M;    location / {        proxy_pass http://frontend:80;        proxy_http_version 1.1;        proxy_set_header Host $host;        proxy_set_header X-Real-IP $remote_addr;        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;        proxy_set_header X-Forwarded-Proto $scheme;    }    location /api/ {        proxy_pass http://backend-nginx/api/;        proxy_http_version 1.1;        proxy_set_header Host $host;        proxy_set_header X-Real-IP $remote_addr;        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;        proxy_set_header X-Forwarded-Proto $scheme;    }    location /ai/ {        proxy_pass http://ai-engine:5000/;        proxy_http_version 1.1;        proxy_set_header Host $host;        proxy_set_header X-Real-IP $remote_addr;        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;        proxy_set_header X-Forwarded-Proto $scheme;    }}

12. Laravel Backend Nginx Config
Create folder:
mkdir -p /u01/nix-life-os/docker/backend-nginx
Create:
nano /u01/nix-life-os/docker/backend-nginx/default.conf
Paste:
server {    listen 80;    server_name backend;    root /var/www/html/public;    index index.php index.html;    client_max_body_size 50M;    location / {        try_files $uri $uri/ /index.php?$query_string;    }    location ~ \.php$ {        fastcgi_pass nixlifeos-backend:9000;        fastcgi_index index.php;        fastcgi_param SCRIPT_FILENAME /var/www/html/public$fastcgi_script_name;        include fastcgi_params;    }    location ~ /\.ht {        deny all;    }}

13. PostgreSQL Init Script
Create folder:
mkdir -p /u01/nix-life-os/docker/postgres
Create:
nano /u01/nix-life-os/docker/postgres/init.sql
Paste:
CREATE EXTENSION IF NOT EXISTS pgcrypto;CREATE EXTENSION IF NOT EXISTS "uuid-ossp";CREATE SCHEMA IF NOT EXISTS nix_life_os;CREATE SCHEMA IF NOT EXISTS finance;CREATE SCHEMA IF NOT EXISTS health;CREATE SCHEMA IF NOT EXISTS projects;CREATE SCHEMA IF NOT EXISTS monitoring;CREATE SCHEMA IF NOT EXISTS automation;CREATE SCHEMA IF NOT EXISTS ai;GRANT ALL PRIVILEGES ON SCHEMA nix_life_os TO nixlifeos_user;GRANT ALL PRIVILEGES ON SCHEMA finance TO nixlifeos_user;GRANT ALL PRIVILEGES ON SCHEMA health TO nixlifeos_user;GRANT ALL PRIVILEGES ON SCHEMA projects TO nixlifeos_user;GRANT ALL PRIVILEGES ON SCHEMA monitoring TO nixlifeos_user;GRANT ALL PRIVILEGES ON SCHEMA automation TO nixlifeos_user;GRANT ALL PRIVILEGES ON SCHEMA ai TO nixlifeos_user;

14. Main Docker Compose Production File
Create:
nano /u01/nix-life-os/docker-compose.prod.yml
Paste:
services:  postgres:    image: postgres:18    container_name: nixlifeos-postgres    restart: unless-stopped    env_file:      - .env.docker    environment:      POSTGRES_DB: ${POSTGRES_DB}      POSTGRES_USER: ${POSTGRES_USER}      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}      TZ: ${TZ}    ports:      - "5432:5432"    volumes:      - nixlifeos_postgres_data:/var/lib/postgresql/data      - ./docker/postgres/init.sql:/docker-entrypoint-initdb.d/init.sql    networks:      - nixlifeos-network    healthcheck:      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}"]      interval: 10s      timeout: 5s      retries: 5  backend:    build:      context: ./backend      dockerfile: Dockerfile    container_name: nixlifeos-backend    restart: unless-stopped    env_file:      - .env.docker    volumes:      - ./backend:/var/www/html      - nixlifeos_backend_storage:/var/www/html/storage    depends_on:      postgres:        condition: service_healthy    networks:      - nixlifeos-network    healthcheck:      test: ["CMD-SHELL", "php artisan --version || exit 1"]      interval: 30s      timeout: 10s      retries: 3  backend-nginx:    image: nginx:1.27-alpine    container_name: nixlifeos-backend-nginx    restart: unless-stopped    ports:      - "8000:80"    volumes:      - ./backend:/var/www/html      - ./docker/backend-nginx/default.conf:/etc/nginx/conf.d/default.conf    depends_on:      - backend    networks:      - nixlifeos-network  frontend:    build:      context: ./frontend      dockerfile: Dockerfile    container_name: nixlifeos-frontend    restart: unless-stopped    depends_on:      - backend-nginx    networks:      - nixlifeos-network  ai-engine:    build:      context: ./ai-engine      dockerfile: Dockerfile    container_name: nixlifeos-ai-engine    restart: unless-stopped    env_file:      - .env.docker    ports:      - "5000:5000"    depends_on:      postgres:        condition: service_healthy    networks:      - nixlifeos-network    healthcheck:      test: ["CMD-SHELL", "curl -f http://localhost:5000/health || exit 1"]      interval: 30s      timeout: 10s      retries: 3  nginx:    image: nginx:1.27-alpine    container_name: nixlifeos-nginx    restart: unless-stopped    ports:      - "80:80"    volumes:      - ./docker/nginx/default.conf:/etc/nginx/conf.d/default.conf    depends_on:      - frontend      - backend-nginx      - ai-engine    networks:      - nixlifeos-networkvolumes:  nixlifeos_postgres_data:  nixlifeos_backend_storage:networks:  nixlifeos-network:    driver: bridge

15. Important Laravel .env Setup Inside Docker
Before running containers, copy the production environment:
cd /u01/nix-life-os/backendcp .env.production .env
Then go back to root:
cd /u01/nix-life-os

16. Build and Start Production Containers
Run:
cd /u01/nix-life-osdocker compose -f docker-compose.prod.yml --env-file .env.docker up -d --build
Check containers:
docker ps
You should see:
nixlifeos-postgresnixlifeos-backendnixlifeos-backend-nginxnixlifeos-frontendnixlifeos-ai-enginenixlifeos-nginx

17. Laravel First-Time Production Commands
Run these commands inside the backend container:
docker exec -it nixlifeos-backend bash
Inside the container:
php artisan key:generate --forcephp artisan migrate --forcephp artisan db:seed --forcephp artisan config:cachephp artisan route:cachephp artisan view:cachephp artisan optimizeexit

18. Test Backend API
From your host machine:
curl http://127.0.0.1:8000/api/v1/dashboard/summary \  -H "Accept: application/json"
If the endpoint requires authentication, use:
curl http://127.0.0.1:8000/api/v1/dashboard/summary \  -H "Accept: application/json" \  -H "Authorization: Bearer YOUR_TOKEN"

19. Test AI Engine
Run:
curl http://127.0.0.1:5000/health
Expected response:
{  "status": "healthy",  "service": "ai-engine"}
Also test through the main Nginx reverse proxy:
curl http://127.0.0.1/ai/health

20. Test Frontend
Open in browser:
http://127.0.0.1
Or:
http://localhost

21. Useful Docker Commands
Stop all services
docker compose -f docker-compose.prod.yml down
Restart services
docker compose -f docker-compose.prod.yml restart
View logs
docker compose -f docker-compose.prod.yml logs -f
View backend logs only
docker logs -f nixlifeos-backend
View PostgreSQL logs
docker logs -f nixlifeos-postgres
Enter Laravel container
docker exec -it nixlifeos-backend bash
Enter PostgreSQL container
docker exec -it nixlifeos-postgres psql -U nixlifeos_user -d nixlifeos_db

22. Production Backup Script
Create:
mkdir -p /u01/nix-life-os/backupsnano /u01/nix-life-os/backup-postgres.sh
Paste:
#!/bin/bashset -eBACKUP_DIR="/u01/nix-life-os/backups"DATE=$(date +"%Y%m%d_%H%M%S")BACKUP_FILE="$BACKUP_DIR/nixlifeos_db_$DATE.sql"mkdir -p "$BACKUP_DIR"docker exec nixlifeos-postgres pg_dump \  -U nixlifeos_user \  -d nixlifeos_db > "$BACKUP_FILE"gzip "$BACKUP_FILE"echo "Backup completed: $BACKUP_FILE.gz"
Make executable:
chmod +x /u01/nix-life-os/backup-postgres.sh
Run backup:
/u01/nix-life-os/backup-postgres.sh

23. Production Restart Script
Create:
nano /u01/nix-life-os/restart-production.sh
Paste:
#!/bin/bashset -ecd /u01/nix-life-osecho "Restarting NIX LIFE OS production containers..."docker compose -f docker-compose.prod.yml --env-file .env.docker downdocker compose -f docker-compose.prod.yml --env-file .env.docker up -d --buildecho "Running Laravel optimization..."docker exec nixlifeos-backend php artisan config:cachedocker exec nixlifeos-backend php artisan route:cachedocker exec nixlifeos-backend php artisan view:cachedocker exec nixlifeos-backend php artisan optimizeecho "NIX LIFE OS restarted successfully."
Make executable:
chmod +x /u01/nix-life-os/restart-production.sh
Run:
/u01/nix-life-os/restart-production.sh

24. Production Deployment Verification Checklist
Use this checklist after deployment:
[ ] PostgreSQL container is running[ ] Laravel backend container is running[ ] Backend Nginx container is running[ ] Vue frontend container is running[ ] Python AI engine container is running[ ] Main Nginx reverse proxy is running[ ] Laravel APP_KEY generated[ ] Laravel migrations completed[ ] Laravel seeders completed[ ] Laravel config cached[ ] Laravel route cache generated[ ] API tested successfully[ ] AI engine health endpoint tested[ ] Frontend opened successfully[ ] PostgreSQL backup script tested[ ] Restart script tested

25. Final Service URLs
After Step 26, your local production deployment will be:
Frontend:http://127.0.0.1Laravel Backend Direct:http://127.0.0.1:8000Laravel API Through Main Nginx:http://127.0.0.1/apiPython AI Engine Direct:http://127.0.0.1:5000Python AI Engine Through Main Nginx:http://127.0.0.1/aiPostgreSQL:Host: 127.0.0.1Port: 5432Database: nixlifeos_dbUser: nixlifeos_user

26. STEP 26 Completion Summary
STEP 26 — Deployment (Docker) is completed.Implemented:- Docker setup- Laravel backend container- Laravel PHP-FPM production image- Backend Nginx container- PostgreSQL production container- Vue frontend production container- Python AI engine container- Main Nginx reverse proxy- Production environment variables- PostgreSQL initialization script- Laravel production optimization commands- Backup script- Restart script- Health check endpoints- Deployment verification checklistNIX LIFE OS is now ready to run as a containerized production-style system.
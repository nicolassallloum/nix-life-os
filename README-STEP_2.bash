STEP 2 — Environment Setup
Size:1,093,328,896 bytes
1) Final project structure
Use this structure from the start:
nix-life-os/
├── backend/                  # Laravel API / admin backend
├── frontend/                 # Vue app
├── analytics/                # Python analytics scripts/notebooks/services
├── docs/
├── scripts/
├── infra/
│   ├── nginx/
│   ├── systemd/
│   └── docker/               # optional later
├── .gitignore
├── README.md
└── .env.example

2) Windows setup first: enable WSL2
Run this in PowerShell as Administrator:
wsl --install
Then reboot if prompted.
List distros:
wsl -l -v
Install Ubuntu if needed:
wsl --install -d Ubuntu-24.04
Open Ubuntu and create your Linux username/password.

3) Base Ubuntu / WSL packages
Run these inside Ubuntu terminal:
sudo apt update && sudo apt upgrade -y
sudo apt install -y \
  curl wget git unzip zip ca-certificates gnupg lsb-release software-properties-common \
  build-essential pkg-config libssl-dev
Create your workspace:
mkdir -p nix-life-os/{backend,frontend,analytics,docs,scripts,infra/nginx,infra/systemd,infra/docker}
cd nix-life-os

4) Install PHP + required extensions for Laravel
Install PHP and common Laravel extensions:
sudo apt install -y \
  php php-cli php-fpm php-common \
  php-mbstring php-xml php-bcmath php-curl php-zip \
  php-pgsql php-sqlite3 php-intl php-gd
Verify:
php -v
php -m | grep -E "mbstring|xml|bcmath|curl|zip|pdo_pgsql|pgsql|intl|gd"

5) Install Composer
Composer’s official install flow on Linux is:
cd /tmp
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php composer-setup.php
sudo mv composer.phar /usr/local/bin/composer
composer --version
--On Windows, Composer’s official documentation also provides Composer-Setup.exe, but because you are using WSL for the stack, installing Composer inside Ubuntu is the cleanest path.

6) Install Node.js and npm
For Ubuntu/WSL, install Node.js from NodeSource:
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt install -y nodejs
node -v
npm -v

7) Install PostgreSQL
Run:
sudo apt install -y postgresql postgresql-contrib
sudo systemctl enable postgresql
sudo systemctl start postgresql
sudo systemctl status postgresql
Check version:
psql --version

8) Configure PostgreSQL for NIX LIFE OS
sudo -u postgres psql
Inside PostgreSQL:
CREATE ROLE nixlifeos_user WITH LOGIN PASSWORD 'StrongPass_ChangeMe_2026';
CREATE DATABASE nixlifeos_db OWNER nixlifeos_user;
ALTER ROLE nixlifeos_user SET client_encoding TO 'utf8';
ALTER ROLE nixlifeos_user SET default_transaction_isolation TO 'read committed';
ALTER ROLE nixlifeos_user SET timezone TO 'UTC';
\q
Test connection:
psql -h localhost -U nixlifeos_user -d nixlifeos_db
If prompted for password, enter:
StrongPass_ChangeMe_2026

9) Create the Laravel backend
From the repo root:
cd ~/Projects/nix-life-os/backend
composer create-project laravel/laravel .
If Fail:
Option 1 — Best fix: give ownership to your WSL user
Run:
sudo chown -R nix:nix /u01/nix-life-os
chmod -R u+rwX /u01/nix-life-os
Then retry:
cd /u01/nix-life-os/backend
composer create-project laravel/laravel .

Now create the environment file:
cp .env.example .env
php artisan key:generate
Edit .env:
APP_NAME="NIX LIFE OS"
APP_ENV=local
APP_KEY=
APP_DEBUG=true
APP_URL=http://localhost:8000

LOG_CHANNEL=stack
LOG_LEVEL=debug

DB_CONNECTION=pgsql
DB_HOST=127.0.0.1
DB_PORT=5432
DB_DATABASE=nixlifeos_db
DB_USERNAME=nixlifeos_user
DB_PASSWORD=StrongPass_ChangeMe_2026

CACHE_STORE=database
QUEUE_CONNECTION=database
SESSION_DRIVER=database
SESSION_LIFETIME=120
Run Laravel database setup:
php artisan migrate
If you want API auth from the beginning:
composer require laravel/sanctum
php artisan vendor:publish --provider="Laravel\Sanctum\SanctumServiceProvider"
php artisan migrate
Useful backend packages:
composer require spatie/laravel-permission
composer require barryvdh/laravel-debugbar --dev
composer require laravel/pint --dev
composer require pestphp/pest --dev
composer require pestphp/pest-plugin-laravel --dev
Publish permissions package:
php artisan vendor:publish --provider="Spatie\Permission\PermissionServiceProvider"
php artisan migrate

10) Recommended Laravel backend folders
Inside backend/, add this organization:
backend/
├── app/
│   ├── Actions/
│   ├── DTOs/
│   ├── Enums/
│   ├── Events/
│   ├── Exceptions/
│   ├── Helpers/
│   ├── Http/
│   │   ├── Controllers/
│   │   │   ├── Api/
│   │   │   └── Admin/
│   │   ├── Middleware/
│   │   ├── Requests/
│   │   └── Resources/
│   ├── Jobs/
│   ├── Models/
│   ├── Policies/
│   ├── Repositories/
│   ├── Services/
│   └── Support/
├── config/
├── database/
│   ├── factories/
│   ├── migrations/
│   └── seeders/
├── routes/
│   ├── api.php
│   ├── web.php
│   └── console.php
├── storage/
└── tests/

Create the extra folders:
cd ~/Projects/nix-life-os/backend
mkdir -p app/{Actions,DTOs,Enums,Events,Exceptions,Helpers,Jobs,Policies,Repositories,Services,Support}
mkdir -p app/Http/Controllers/{Api,Admin}
mkdir -p app/Http/{Middleware,Requests,Resources}

11) Create the Vue frontend
From repo root:
cd ~/Projects/nix-life-os/frontend
npm create vue@latest .
At Package name: just type:
frontend
Then use these recommended answers for NIX LIFE OS:
TypeScript? Yes
JSX Support? No
Vue Router? Yes
Pinia? Yes
Vitest? Yes
End-to-End Testing? No
ESLint? Yes
Prettier? Yes
Vue DevTools? Yes
After setup finishes, run:
npm install
Add core frontend packages:
npm install axios dayjs chart.js vue-chartjs zod
npm install @vueuse/core
npm install -D sass
Recommended optional UI packages:
npm install pinia-plugin-persistedstate
npm install vue-sonner
npm install lucide-vue-next

12) Recommended Vue frontend structure
Inside frontend/src:
frontend/src/
├── api/
├── assets/
├── components/
│   ├── common/
│   ├── dashboard/
│   ├── finance/
│   ├── health/
│   └── projects/
├── composables/
├── layouts/
├── router/
├── stores/
├── types/
├── utils/
├── views/
│   ├── dashboard/
│   ├── finance/
│   ├── health/
│   ├── projects/
│   └── settings/
├── App.vue
└── main.ts
Create them:
cd ~/Projects/nix-life-os/frontend
mkdir -p src/{api,assets,composables,layouts,router,stores,types,utils}
mkdir -p src/components/{common,dashboard,finance,health,projects}
mkdir -p src/views/{dashboard,finance,health,projects,settings}

13) Configure frontend environment
Create frontend/.env:
VITE_APP_NAME="NIX LIFE OS"
VITE_API_BASE_URL="http://127.0.0.1:8000/api"
Create a reusable Axios client in frontend/src/api/http.ts:
import axios from "axios";

export const http = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL,
  headers: {
    "Content-Type": "application/json",
    Accept: "application/json",
  },
});

14) Python analytics environment
Install Python tooling:
sudo apt install -y python3 python3-pip python3-venv python3-dev
python3 --version
pip3 --version
Create the analytics environment:
cd ~/Projects/nix-life-os/analytics
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip setuptools wheel
Install analytics packages:
pip install pandas numpy matplotlib seaborn jupyterlab sqlalchemy psycopg2-binary scikit-learn python-dotenv
Create a requirements.txt:
pip freeze > requirements.txt
Recommended analytics structure:
analytics/
├── .venv/
├── notebooks/
├── src/
│   ├── config/
│   ├── db/
│   ├── etl/
│   ├── features/
│   ├── models/
│   ├── reports/
│   └── utils/
├── tests/
├── .env
└── requirements.txt
Create it:
mkdir -p notebooks tests
mkdir -p src/{config,db,etl,features,models,reports,utils}
Create analytics/.env:
PG_HOST=127.0.0.1
PG_PORT=5432
PG_DB=nixlifeos_db
PG_USER=nixlifeos_user
PG_PASSWORD=StrongPass_ChangeMe_2026

15) Git initialization
From repo root:
cd ~/Projects/nix-life-os
git init
Create root .gitignore:
# OS
.DS_Store
Thumbs.db
# IDE
.vscode/
.idea/
# Logs
*.log
# Env
.env
.env.*
!.env.example
# Node
frontend/node_modules/
frontend/dist/
# Python
analytics/.venv/
analytics/__pycache__/
analytics/.pytest_cache/
analytics/.ipynb_checkpoints/
# Laravel
backend/vendor/
backend/node_modules/
backend/storage/*.key
backend/bootstrap/cache/*.php
backend/public/build/

16) Add useful scripts
Create scripts/dev.sh:
#!/usr/bin/env bash
set -e
echo "Starting Laravel..."
gnome-terminal -- bash -c "cd ~/Projects/nix-life-os/backend && php artisan serve; exec bash" 2>/dev/null || true
echo "Starting Vue..."
gnome-terminal -- bash -c "cd ~/Projects/nix-life-os/frontend && npm run dev; exec bash" 2>/dev/null || true
Make executable:
chmod +x scripts/dev.sh

17) Start the full stack
Terminal 1 — PostgreSQL
Usually already running:
sudo systemctl start postgresql
Terminal 2 — Laravel + Vue 
From repo root:
cd ~/Projects/nix-life-os/backend
php artisan serve
Laravel default dev URL:
http://127.0.0.1:8000
Terminal 3 — Vue frontend
cd ~/Projects/nix-life-os/frontend
npm run dev
Vite dev URL will usually be:
http://127.0.0.1:5173
Terminal 4 — Python analytics test
cd ~/Projects/nix-life-os/analytics
source .venv/bin/activate
python -c "import pandas, sqlalchemy, psycopg2; print('Analytics env OK')"

18) Test PostgreSQL from Laravel
Run:
cd ~/Projects/nix-life-os/backend
php artisan migrate:status

19) Test PostgreSQL from Python
Create analytics/src/db/test_connection.py:
import os
from dotenv import load_dotenv
from sqlalchemy import create_engine, text

load_dotenv()

user = os.getenv("PG_USER")
password = os.getenv("PG_PASSWORD")
host = os.getenv("PG_HOST")
port = os.getenv("PG_PORT")
db = os.getenv("PG_DB")

engine = create_engine(f"postgresql+psycopg2://{user}:{password}@{host}:{port}/{db}")

with engine.connect() as conn:
    result = conn.execute(text("SELECT current_database(), current_user, now()"))
    print(result.fetchone())

Run:
cd ~/Projects/nix-life-os/analytics
source .venv/bin/activate
python src/db/test_connection.py

20) Recommended first Laravel API setup
Generate modules for the first domains:
cd ~/Projects/nix-life-os/backend

php artisan make:model Finance/Expense -mcr
php artisan make:model Finance/Income -mcr
php artisan make:model Health/WeightEntry -mcr
php artisan make:model Health/StepEntry -mcr
php artisan make:model Health/CalorieEntry -mcr
php artisan make:model Projects/Project -mcr
php artisan make:model Projects/Task -mcr
Then add API routes in routes/api.php:
<?php

use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {
    Route::get('/health', fn () => response()->json(['status' => 'ok']));
});
Test:
curl http://127.0.0.1:8000/api/v1/health

21) Recommended frontend app initialization
In frontend/src/router/index.ts, wire up views.
Install Vue Router through the scaffold if not already selected. Vue’s official tooling recommends Router and Pinia as standard app-building companions for Vite-based Vue projects.

Create starter views:
cd ~/Projects/nix-life-os/frontend
touch src/views/dashboard/DashboardView.vue
touch src/views/finance/ExpensesView.vue
touch src/views/health/HealthView.vue
touch src/views/projects/ProjectsView.vue

22) Exact one-shot setup script for Ubuntu / WSL
If you want a near one-pass bootstrap, run this carefully section by section:
sudo apt update && sudo apt upgrade -y

sudo apt install -y \
  curl wget git unzip zip ca-certificates gnupg lsb-release software-properties-common \
  build-essential pkg-config libssl-dev \
  php php-cli php-fpm php-common php-mbstring php-xml php-bcmath php-curl php-zip php-pgsql php-sqlite3 php-intl php-gd \
  python3 python3-pip python3-venv python3-dev \
  postgresql postgresql-contrib

cd /tmp
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php composer-setup.php
sudo mv composer.phar /usr/local/bin/composer

curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt install -y nodejs

mkdir -p ~/Projects/nix-life-os/{backend,frontend,analytics,docs,scripts,infra/nginx,infra/systemd,infra/docker}

sudo systemctl enable postgresql
sudo systemctl start postgresql

Then continue with:

PostgreSQL role/database creation
Laravel app creation
Vue app creation
Python venv creation

23) Required packages summary
System
git
curl
wget
unzip
zip
build-essential
Backend
php
php-cli
php-fpm
php-mbstring
php-xml
php-bcmath
php-curl
php-zip
php-pgsql
php-intl
php-gd
composer
Database
postgresql
postgresql-contrib
Frontend
nodejs
npm
vue
vite
pinia
vue-router
axios
chart.js
sass
Analytics
python3
python3-pip
python3-venv
pandas
numpy
matplotlib
seaborn
sqlalchemy
psycopg2-binary
scikit-learn
jupyterlab
python-dotenv

24) Daily dev commands
Backend
cd ~/Projects/nix-life-os/backend
php artisan serve
php artisan migrate
php artisan test
Frontend
cd ~/Projects/nix-life-os/frontend
npm run dev
npm run build
Analytics
cd ~/Projects/nix-life-os/analytics
source .venv/bin/activate
jupyter lab
#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="/u01/nix-life-os"
EXPORT_ROOT="$PROJECT_ROOT/step85-frontend-build-optimization-export"
ARCHIVE_NAME="step85-frontend-build-optimization-export.tar.gz"

echo "=================================================="
echo " STEP 85 — Frontend Build Optimization Export"
echo " Project Root: $PROJECT_ROOT"
echo " Export Root:  $EXPORT_ROOT"
echo " Archive:      $ARCHIVE_NAME"
echo "=================================================="

rm -rf "$EXPORT_ROOT"
mkdir -p "$EXPORT_ROOT"

copy_if_exists() {
  local src="$1"
  local dest="$EXPORT_ROOT/$src"

  if [ -e "$PROJECT_ROOT/$src" ]; then
    mkdir -p "$(dirname "$dest")"
    cp -a "$PROJECT_ROOT/$src" "$dest"
    echo "✅ Copied: $src"
  else
    echo "⚠️  Missing: $src"
  fi
}

copy_dir_if_exists() {
  local src="$1"
  local dest="$EXPORT_ROOT/$src"

  if [ -d "$PROJECT_ROOT/$src" ]; then
    mkdir -p "$(dirname "$dest")"
    cp -a "$PROJECT_ROOT/$src" "$dest"
    echo "✅ Copied directory: $src"
  else
    echo "⚠️  Missing directory: $src"
  fi
}

echo ""
echo "📦 Copying frontend configuration files..."

copy_if_exists "frontend/package.json"
copy_if_exists "frontend/package-lock.json"
copy_if_exists "frontend/pnpm-lock.yaml"
copy_if_exists "frontend/yarn.lock"
copy_if_exists "frontend/vite.config.js"
copy_if_exists "frontend/vite.config.ts"
copy_if_exists "frontend/index.html"
copy_if_exists "frontend/.env"
copy_if_exists "frontend/.env.production"
copy_if_exists "frontend/.env.docker"
copy_if_exists "frontend/tsconfig.json"
copy_if_exists "frontend/jsconfig.json"
copy_if_exists "frontend/postcss.config.js"
copy_if_exists "frontend/postcss.config.cjs"
copy_if_exists "frontend/tailwind.config.js"
copy_if_exists "frontend/tailwind.config.cjs"

echo ""
echo "📦 Copying Vue source files..."

copy_if_exists "frontend/src/main.js"
copy_if_exists "frontend/src/main.ts"
copy_if_exists "frontend/src/App.vue"

copy_dir_if_exists "frontend/src/router"
copy_dir_if_exists "frontend/src/stores"
copy_dir_if_exists "frontend/src/api"
copy_dir_if_exists "frontend/src/services"
copy_dir_if_exists "frontend/src/utils"
copy_dir_if_exists "frontend/src/composables"
copy_dir_if_exists "frontend/src/layouts"
copy_dir_if_exists "frontend/src/views"
copy_dir_if_exists "frontend/src/pages"
copy_dir_if_exists "frontend/src/components"
copy_dir_if_exists "frontend/src/assets"
copy_dir_if_exists "frontend/src/styles"
copy_dir_if_exists "frontend/src/css"
copy_dir_if_exists "frontend/public"

echo ""
echo "📦 Copying Docker / Nginx / production files..."

copy_if_exists "Dockerfile"
copy_if_exists "docker-compose.yml"
copy_if_exists "docker-compose.prod.yml"
copy_if_exists "frontend/Dockerfile"
copy_if_exists "frontend/Dockerfile.prod"
copy_if_exists "frontend/nginx.conf"
copy_if_exists "nginx.conf"
copy_dir_if_exists "docker/nginx"

echo ""
echo "📊 Creating diagnostics folder..."

mkdir -p "$EXPORT_ROOT/diagnostics"

echo ""
echo "📊 Collecting project tree summary..."

if command -v tree >/dev/null 2>&1; then
  tree -a -I "node_modules|.git|dist|build|coverage|.vite" "$PROJECT_ROOT/frontend" > "$EXPORT_ROOT/diagnostics/frontend-tree.txt" || true
else
  find "$PROJECT_ROOT/frontend" \
    -path "*/node_modules" -prune -o \
    -path "*/.git" -prune -o \
    -path "*/dist" -prune -o \
    -path "*/build" -prune -o \
    -path "*/coverage" -prune -o \
    -path "*/.vite" -prune -o \
    -print > "$EXPORT_ROOT/diagnostics/frontend-tree.txt" || true
fi

echo "✅ Created: diagnostics/frontend-tree.txt"

echo ""
echo "📊 Listing largest source/assets files..."

find "$PROJECT_ROOT/frontend" \
  -path "*/node_modules" -prune -o \
  -path "*/.git" -prune -o \
  -type f \
  -printf "%s %p\n" 2>/dev/null \
  | sort -nr \
  | head -100 \
  > "$EXPORT_ROOT/diagnostics/frontend-largest-files.txt" || true

echo "✅ Created: diagnostics/frontend-largest-files.txt"

echo ""
echo "📊 Detecting dependency usage..."

grep -R "from ['\"]" "$PROJECT_ROOT/frontend/src" 2>/dev/null \
  > "$EXPORT_ROOT/diagnostics/frontend-imports.txt" || true

grep -R "import " "$PROJECT_ROOT/frontend/src" 2>/dev/null \
  >> "$EXPORT_ROOT/diagnostics/frontend-imports.txt" || true

echo "✅ Created: diagnostics/frontend-imports.txt"

echo ""
echo "📊 Detecting chart/icon/library usage..."

grep -R "chart\|Chart\|apex\|Apex\|echarts\|ECharts\|recharts\|d3\|lodash\|moment\|dayjs\|lucide\|fontawesome\|bootstrap\|vuetify\|element-plus" \
  "$PROJECT_ROOT/frontend/src" 2>/dev/null \
  > "$EXPORT_ROOT/diagnostics/frontend-heavy-library-usage.txt" || true

echo "✅ Created: diagnostics/frontend-heavy-library-usage.txt"

echo ""
echo "📊 Detecting router lazy loading..."

grep -R "component:" "$PROJECT_ROOT/frontend/src/router" 2>/dev/null \
  > "$EXPORT_ROOT/diagnostics/frontend-router-components.txt" || true

grep -R "() => import" "$PROJECT_ROOT/frontend/src/router" 2>/dev/null \
  > "$EXPORT_ROOT/diagnostics/frontend-router-lazy-imports.txt" || true

echo "✅ Created router diagnostics"

echo ""
echo "📊 Detecting large CSS / asset imports..."

grep -R ".css\|.scss\|.sass\|.png\|.jpg\|.jpeg\|.svg\|.webp\|.gif" \
  "$PROJECT_ROOT/frontend/src" 2>/dev/null \
  > "$EXPORT_ROOT/diagnostics/frontend-css-assets-imports.txt" || true

echo "✅ Created: diagnostics/frontend-css-assets-imports.txt"

echo ""
echo "📊 Running npm dependency summary if available..."

if [ -f "$PROJECT_ROOT/frontend/package.json" ]; then
  cd "$PROJECT_ROOT/frontend"

  npm ls --depth=0 > "$EXPORT_ROOT/diagnostics/npm-ls-depth0.txt" 2>&1 || true
  npm outdated > "$EXPORT_ROOT/diagnostics/npm-outdated.txt" 2>&1 || true

  echo "✅ Created npm dependency diagnostics"
fi

echo ""
echo "🏗️ Running production build diagnostics..."

cd "$PROJECT_ROOT/frontend"

if [ -f "package.json" ]; then
  {
    echo "===== npm scripts ====="
    npm run 2>/dev/null || true
  } > "$EXPORT_ROOT/diagnostics/npm-scripts.txt" 2>&1

  echo "✅ Created: diagnostics/npm-scripts.txt"

  if npm run build > "$EXPORT_ROOT/diagnostics/frontend-build-output.log" 2>&1; then
    echo "✅ Production build completed"

    if [ -d "$PROJECT_ROOT/frontend/dist" ]; then
      mkdir -p "$EXPORT_ROOT/frontend/dist-summary"

      find "$PROJECT_ROOT/frontend/dist" -type f -printf "%s %p\n" 2>/dev/null \
        | sort -nr \
        > "$EXPORT_ROOT/frontend/dist-summary/dist-files-by-size.txt" || true

      du -sh "$PROJECT_ROOT/frontend/dist" \
        > "$EXPORT_ROOT/frontend/dist-summary/dist-total-size.txt" || true

      find "$PROJECT_ROOT/frontend/dist" -maxdepth 3 -type f \
        > "$EXPORT_ROOT/frontend/dist-summary/dist-file-list.txt" || true

      echo "✅ Created dist summary"
    fi
  else
    echo "⚠️ Production build failed. Build log included."
  fi
fi

echo ""
echo "🧹 Removing risky or unnecessary files from export..."

find "$EXPORT_ROOT" -type d -name "node_modules" -prune -exec rm -rf {} + 2>/dev/null || true
find "$EXPORT_ROOT" -type d -name ".git" -prune -exec rm -rf {} + 2>/dev/null || true
find "$EXPORT_ROOT" -type d -name ".vite" -prune -exec rm -rf {} + 2>/dev/null || true
find "$EXPORT_ROOT" -type d -name "coverage" -prune -exec rm -rf {} + 2>/dev/null || true

echo ""
echo "🔐 Redacting sensitive environment values..."

find "$EXPORT_ROOT" -type f \( -name ".env" -o -name ".env.*" \) -print0 | while IFS= read -r -d '' envfile; do
  sed -i -E \
    -e 's/(PASSWORD|PASS|SECRET|TOKEN|KEY|API_KEY|PRIVATE|CLIENT_SECRET|DB_PASSWORD|VITE_API_KEY)=.*/\1=REDACTED/gI' \
    "$envfile" || true
done

echo ""
echo "🗜️ Creating archive..."

cd "$PROJECT_ROOT"
tar -czf "$ARCHIVE_NAME" "$(basename "$EXPORT_ROOT")"

echo ""
echo "=================================================="
echo "✅ STEP 85 export completed successfully"
echo "📦 Archive created:"
echo "$PROJECT_ROOT/$ARCHIVE_NAME"
echo "=================================================="

#!/usr/bin/env bash
set -e

echo "Starting Laravel..."
gnome-terminal -- bash -c "cd ~/Projects/nix-life-os/backend && php artisan serve; exec bash" 2>/dev/null || true

echo "Starting Vue..."
gnome-terminal -- bash -c "cd ~/Projects/nix-life-os/frontend && npm run dev; exec bash" 2>/dev/null || true

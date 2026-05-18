# STEP 89.3.1 — Notification Offline UI Fix

## Purpose
This patch fixes the Notification Settings screen after the UI polish patch.

## Problem Fixed
When the backend/Docker service is off, the page displayed only the warning message and hid the settings form.

## Expected Behavior After This Patch
- The warning message still appears when the backend is off.
- The form remains visible using default local values.
- This allows the design regression test to validate the full UI even when backend services are stopped.

## Install

```bash
cd /u01/nix-life-os

tar -xzf step89-3-1-notification-offline-fix.tar.gz

chmod +x step89-3-1-notification-offline-fix/scripts/install_step89_3_1_notification_offline_fix.sh

./step89-3-1-notification-offline-fix/scripts/install_step89_3_1_notification_offline_fix.sh
```

## Validate

```bash
cd /u01/nix-life-os/frontend
npm run build
npm run dev -- --host 0.0.0.0
```

Open:

```text
http://127.0.0.1:5173/notifications/settings
```

## QA Expected Result
The page should show:
- Notification Settings title
- Backend-off warning
- Meal Reminders card
- Weight Reminder card
- Expense Reminder card
- Smart Alerts card
- Reload button
- Save Settings button

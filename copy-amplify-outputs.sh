#!/usr/bin/env bash

set -euo pipefail

# ────────────────────────────────────────────────────────────────────────────────
# Script: copy-amplify-outputs.sh
# Purpose: Copy the latest amplify_outputs.json from backend to frontend folders
# Usage:   ./copy-amplify-outputs.sh
# ────────────────────────────────────────────────────────────────────────────────

BACKEND_DIR="packages/backend"
SOURCE_FILE="$BACKEND_DIR/amplify_outputs.json"

if [[ ! -f "$SOURCE_FILE" ]]; then
  echo "❌ Error: $SOURCE_FILE not found."
  echo "   → Make sure you ran 'npx ampx sandbox' in $BACKEND_DIR and it completed successfully."
  exit 1
fi

echo "📄 Found amplify_outputs.json in $BACKEND_DIR"
echo "Copying to frontends..."

# Next.js web app
cp "$SOURCE_FILE" "apps/web/src/amplify_outputs.json" && \
  echo "✓ Copied to apps/web/src/amplify_outputs.json"

# Next.js admin app
cp "$SOURCE_FILE" "apps/admin/src/amplify_outputs.json" && \
  echo "✓ Copied to apps/admin/src/amplify_outputs.json"

# Flutter mobile app (place in lib/ for easy Dart import)
cp "$SOURCE_FILE" "apps/mobile/lib/amplify_outputs.json" && \
  echo "✓ Copied to apps/mobile/lib/amplify_outputs.json"

# Optional: If you prefer Flutter assets/ folder instead (then add to pubspec.yaml assets)
# mkdir -p apps/mobile/assets/amplify
# cp "$SOURCE_FILE" "apps/mobile/assets/amplify/amplify_outputs.json"
# echo "✓ Copied to apps/mobile/assets/amplify/amplify_outputs.json"

echo ""
echo "🎉 Done! All frontends now have the latest amplify_outputs.json"
echo "   → Restart your dev servers (nx serve web/admin, nx run mobile:run) to pick up changes."
echo "   → If paths differ in your project, edit this script."
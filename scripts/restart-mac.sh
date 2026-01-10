#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="$ROOT/Casa.xcodeproj"
SCHEME="Casa"
DERIVED_DATA="$ROOT/DerivedData"
DESTINATION="platform=macOS,variant=Mac Catalyst"
FORCE_LEGACY_TABS="${FORCE_LEGACY_TABS:-}"

pkill -x Casa >/dev/null 2>&1 || true

if [[ -n "$FORCE_LEGACY_TABS" ]]; then
  defaults write dev.shadowing.casa forceLegacyTabs -bool "$FORCE_LEGACY_TABS"
fi

xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Debug \
  -destination "$DESTINATION" \
  -derivedDataPath "$DERIVED_DATA" \
  build

APP_PATH="$DERIVED_DATA/Build/Products/Debug-maccatalyst/Casa.app"
open -n "$APP_PATH"

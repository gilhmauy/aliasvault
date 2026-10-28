#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

# Named cache volumes are created root-owned
sudo chown -R vscode:vscode "$HOME/.nuget" "$HOME/.gradle"

rustup target add \
  wasm32-unknown-unknown \
  aarch64-linux-android armv7-linux-androideabi x86_64-linux-android
command -v wasm-pack >/dev/null || cargo install wasm-pack

# core packages first; apps link them via file: references
for dir in core/models core/vault core/i18n core/client \
           apps/web apps/browser-extension apps/mobile-app \
           apps/server/AliasVault.Admin docs; do
  echo "==> npm ci in $dir"
  (cd "$dir" && npm ci)
done

dotnet restore apps/server/aliasvault.sln

# Install the browsers matching each project's pinned Playwright version (a bare
# `npx playwright` would pull the latest release instead). The .NET E2E tests share
# the same browser cache.
for dir in apps/web apps/browser-extension; do
  echo "==> playwright install in $dir"
  (cd "$dir" && npx --no-install playwright install --with-deps chromium)
done

./core/build-and-distribute.sh --web --browser-extension

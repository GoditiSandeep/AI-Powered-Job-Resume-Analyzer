#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
flutter_home="${FLUTTER_HOME:-$HOME/flutter}"

python -m pip install -r "$project_root/backend/requirements.txt"

if [[ ! -x "$flutter_home/bin/flutter" ]]; then
  git clone --depth 1 --branch stable https://github.com/flutter/flutter.git "$flutter_home"
fi

export PATH="$flutter_home/bin:$PATH"
flutter config --no-analytics

cd "$project_root/frontend"
flutter pub get
flutter build web --release --base-href /

test -s build/web/index.html
test -s build/web/flutter_bootstrap.js
test -s build/web/main.dart.js
test -s build/web/canvaskit/canvaskit.js
test -s build/web/canvaskit/canvaskit.wasm

#!/usr/bin/env bash
set -euo pipefail

PLUGIN_NAME="health-rca-toolkit"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_PLUGIN_DIR="${SCRIPT_DIR}/plugins/${PLUGIN_NAME}"
TARGET_PLUGIN_ROOT="${CODEX_PLUGIN_DIR:-${HOME}/.codex/plugins}"
TARGET_PLUGIN_DIR="${TARGET_PLUGIN_ROOT}/${PLUGIN_NAME}"
MARKETPLACE_PATH="${CODEX_MARKETPLACE_PATH:-${HOME}/.agents/plugins/marketplace.json}"

if [[ ! -f "${SOURCE_PLUGIN_DIR}/.codex-plugin/plugin.json" ]]; then
  echo "Could not find ${PLUGIN_NAME} plugin at ${SOURCE_PLUGIN_DIR}" >&2
  echo "Run this script from the downloaded or cloned skills repository." >&2
  exit 1
fi

mkdir -p "${TARGET_PLUGIN_ROOT}"
rm -rf "${TARGET_PLUGIN_DIR}"
cp -R "${SOURCE_PLUGIN_DIR}" "${TARGET_PLUGIN_DIR}"

mkdir -p "$(dirname "${MARKETPLACE_PATH}")"

MARKETPLACE_PATH="${MARKETPLACE_PATH}" TARGET_PLUGIN_DIR="${TARGET_PLUGIN_DIR}" PLUGIN_NAME="${PLUGIN_NAME}" python3 - <<'PY'
import json
import os
from pathlib import Path

marketplace_path = Path(os.environ["MARKETPLACE_PATH"]).expanduser()
target_plugin_dir = Path(os.environ["TARGET_PLUGIN_DIR"]).expanduser()
plugin_name = os.environ["PLUGIN_NAME"]

if marketplace_path.exists():
    with marketplace_path.open() as handle:
        marketplace = json.load(handle)
else:
    marketplace = {
        "name": "local-codex",
        "interface": {"displayName": "Local Codex"},
        "plugins": [],
    }

plugins = marketplace.setdefault("plugins", [])
entry = {
    "name": plugin_name,
    "source": {
        "source": "local",
        "path": str(target_plugin_dir),
    },
    "policy": {
        "installation": "AVAILABLE",
        "authentication": "ON_INSTALL",
    },
    "category": "Productivity",
}

for index, existing in enumerate(plugins):
    if isinstance(existing, dict) and existing.get("name") == plugin_name:
        plugins[index] = entry
        break
else:
    plugins.append(entry)

with marketplace_path.open("w") as handle:
    json.dump(marketplace, handle, indent=2)
    handle.write("\n")
PY

echo "Installed ${PLUGIN_NAME} to ${TARGET_PLUGIN_DIR}"
echo "Updated marketplace at ${MARKETPLACE_PATH}"
echo "Restart Codex if the plugin does not appear immediately."

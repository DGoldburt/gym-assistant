#!/bin/bash
set -euo pipefail
repo_dir="$(cd "$(dirname "$0")/../.." && pwd)"
scratchpad_build_root="$(mktemp -d /private/tmp/gym-assistant-scratchpad-development.XXXXXX)"
cd "$repo_dir"
swift build --product ScratchpadDevelopment
scratchpad_bin_dir="$(swift build --show-bin-path)"
scratchpad_bundle="$scratchpad_build_root/Gym Assistant Scratchpad Development.app"
mkdir -p "$scratchpad_bundle/Contents/MacOS"
cp "$scratchpad_bin_dir/ScratchpadDevelopment" "$scratchpad_bundle/Contents/MacOS/ScratchpadDevelopment"
cp "$repo_dir/app/scratchpad-development/Info.plist" "$scratchpad_bundle/Contents/Info.plist"
/usr/bin/codesign --force --sign - "$scratchpad_bundle"
/usr/bin/codesign --verify --strict "$scratchpad_bundle"
/usr/bin/plutil -lint "$scratchpad_bundle/Contents/Info.plist"
printf '%s\n' "$scratchpad_bundle"

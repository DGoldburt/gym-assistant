#!/bin/bash
set -euo pipefail

repo_dir="$(cd "$(dirname "$0")/../.." && pwd)"
build_root="/private/tmp/gym-assistant-exercise-09"
app_dir="$build_root/Gym Assistant.app"
contents_dir="$app_dir/Contents"
macos_dir="$contents_dir/MacOS"

cd "$repo_dir"
swift build --product GymAssistantNotesService
bin_dir="$(swift build --product GymAssistantNotesService --show-bin-path)"

mkdir -p "$macos_dir"
cp "$repo_dir/app/notes-service/Info.plist" "$contents_dir/Info.plist"
cp "$bin_dir/GymAssistantNotesService" "$macos_dir/GymAssistantNotesService"

xattr -cr "$app_dir"
codesign --force --sign - "$app_dir"
codesign --verify --strict "$app_dir"
plutil -lint "$contents_dir/Info.plist"

echo "$app_dir"

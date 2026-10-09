#!/bin/bash
set -euo pipefail

repo_dir="$(cd "$(dirname "$0")/../.." && pwd)"
swift_bin="${SWIFT_BIN:-swift}"
build_root="${BUILD_ROOT:-/private/tmp/gym-assistant-exercise-09}"
app_dir="$build_root/Gym Assistant.app"
contents_dir="$app_dir/Contents"
macos_dir="$contents_dir/MacOS"
resources_dir="$contents_dir/Resources"
iconset_dir="$build_root/GymAssistant.iconset"

cd "$repo_dir"
"$swift_bin" build --product GymAssistantNotesService
"$swift_bin" build --product FieldFeedbackReport
"$swift_bin" build --product SetFieldFeedbackDisposition
bin_dir="$("$swift_bin" build --product GymAssistantNotesService --show-bin-path)"

mkdir -p "$macos_dir" "$resources_dir" "$iconset_dir"
for icon_size in 16 32 128 256 512; do
    cp "$repo_dir/assets/branding/appicon/gym-assistant-icon-$icon_size.png" "$iconset_dir/icon_${icon_size}x${icon_size}.png"
    retina_size=$((icon_size * 2))
    cp "$repo_dir/assets/branding/appicon/gym-assistant-icon-$retina_size.png" "$iconset_dir/icon_${icon_size}x${icon_size}@2x.png"
done
iconutil -c icns "$iconset_dir" -o "$resources_dir/GymAssistant.icns"
cp "$repo_dir/app/notes-service/Info.plist" "$contents_dir/Info.plist"
cp "$bin_dir/GymAssistantNotesService" "$macos_dir/GymAssistantNotesService"
cp "$bin_dir/FieldFeedbackReport" "$macos_dir/FieldFeedbackReport"
cp "$bin_dir/SetFieldFeedbackDisposition" "$macos_dir/SetFieldFeedbackDisposition"

xattr -cr "$app_dir"
codesign --force --sign - "$app_dir"
codesign --verify --strict "$app_dir"
plutil -lint "$contents_dir/Info.plist"

echo "$app_dir"

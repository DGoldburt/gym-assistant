#!/bin/bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
build_dir="/private/tmp/gym-assistant-notes-spike"
app_dir="$build_dir/Gym Assistant Service.app"
contents_dir="$app_dir/Contents"
macos_dir="$contents_dir/MacOS"
sdk_path="$(xcrun --sdk macosx --show-sdk-path)"

mkdir -p "$macos_dir"
cp "$script_dir/Info.plist" "$contents_dir/Info.plist"

swiftc \
    -parse-as-library \
    -sdk "$sdk_path" \
    -framework AppKit \
    "$script_dir/Sources/main.swift" \
    -o "$macos_dir/GymAssistantService"

xattr -cr "$app_dir"
codesign --force --sign - "$app_dir"

echo "$app_dir"

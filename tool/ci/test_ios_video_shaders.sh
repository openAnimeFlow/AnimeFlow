#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
output=build/ios-video-shaders
mkdir -p "$output"

# The package runner uses only package-owned synthetic fixtures.
bash packages/video_player_avfoundation/tool/test_shaders.sh

# Mac runtime compilation cannot validate the iPhone target, so compile every preset
# and x2 fixture for iOS as well. Requires the Xcode Metal Toolchain component.
for shader in assets/shaders/video_player/ios/*.metal test/fixtures/video_shaders/ios/*.metal; do
  xcrun --sdk iphoneos metal -std=ios-metal2.2 -c "$shader" \
    -o "$output/$(basename "$shader").air"
done
echo 'All generated Metal shaders compiled for iOS.'

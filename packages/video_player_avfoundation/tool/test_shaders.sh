#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
output=build/shader-tests
source=darwin/video_player_avfoundation/Sources/video_player_avfoundation_objc
mkdir -p "$output"

xcrun --sdk macosx clang -fobjc-arc -fblocks -fmodules -Wall \
  -I "$source/include/video_player_avfoundation_objc" \
  "$source/FVPShaderBundle.m" "$source/FVPMetalVideoEffect.m" darwin/Tests/ShaderTests.m \
  -framework Foundation -framework Metal -framework CoreVideo -framework CoreGraphics \
  -o "$output/shader-tests"
"$output/shader-tests"

# Compile the renderer's embedded vertex/copy shader for the iPhone target as well.
python3 - "$source/FVPMetalVideoEffect.m" "$output/video_builtin.metal" <<'PY'
import json
import pathlib
import re
import sys
source = pathlib.Path(sys.argv[1]).read_text()
literal = re.search(r'static NSString \*const VertexSource =([\s\S]*?);\n', source).group(1)
strings = re.findall(r'"(?:\\.|[^"\\])*"', literal)
pathlib.Path(sys.argv[2]).write_text(''.join(json.loads(value) for value in strings))
PY

xcrun --sdk iphoneos metal -std=ios-metal2.2 -c "$output/video_builtin.metal" \
  -o "$output/video_builtin.air"
echo 'Plugin shader tests and iOS built-in shader compilation passed.'

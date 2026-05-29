#!/bin/bash
set -e

QT6="/opt/homebrew/Cellar/qt/6.11.1"
HAMLIB="/opt/local/jtdxhamlib"
VULKAN="/opt/homebrew/opt/vulkan-headers"

rm -rf build
mkdir build
cd build

export PATH="$QT6/bin:$PATH"
export CMAKE_PREFIX_PATH="$QT6;/opt/homebrew"

cmake -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=26.0 \
  -DCMAKE_PREFIX_PATH="$QT6;/opt/homebrew" \
  -DVulkan_INCLUDE_DIR="$VULKAN/include" \
  -DHamlib_INCLUDE_DIR="$HAMLIB/include" \
  -DHamlib_LIBRARY="$HAMLIB/lib/libhamlib.4.dylib" \
  ..

ninja

"$QT6/bin/macdeployqt" JS8Call.app \
  -verbose=2 \
  -libpath="$QT6/lib" \
  -libpath="$QT6/Frameworks" \
  -libpath="/opt/homebrew/lib" \
  -libpath="$HAMLIB/lib"

codesign --remove-signature JS8Call.app 2>/dev/null || true
codesign --force --sign - JS8Call.app
codesign --verify --deep --strict --verbose=2 JS8Call.app

xattr -dr com.apple.quarantine JS8Call.app

find JS8Call.app -type f -perm +111 -print0 | while IFS= read -r -d '' f; do
  if file "$f" | grep -q "Mach-O"; then
    otool -L "$f" | awk -v file="$f" '
      NR==1 { next }
      /^[[:space:]]/ {
        lib=$1
        if (lib ~ /^\/opt\//) {
          print file ": " lib
        }
      }'
  fi
done

open JS8Call.app

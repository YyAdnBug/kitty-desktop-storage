#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR/../KittyDesktop"
BUILD_DIR="$SCRIPT_DIR/../build"
APP_NAME="Kitty 桌面收纳"
DMG_NAME="KittyDesktop"
VERSION="1.0.0"

echo "=== Kitty 桌面收纳 — 打包 DMG ==="

# 1. Regenerate Xcode project
echo "[1/5] 生成 Xcode 项目..."
cd "$PROJECT_DIR"
xcodegen generate 2>&1 | grep -v "^$"

# 2. Build Release
echo "[2/5] 编译 Release 版本..."
xcodebuild -project KittyDesktop.xcodeproj \
  -scheme KittyDesktop \
  -configuration Release \
  -derivedDataPath "$BUILD_DIR/DerivedData" \
  clean build 2>&1 | grep -E "(error:|warning:|BUILD)" | head -20

BUILT_APP="$BUILD_DIR/DerivedData/Build/Products/Release/KittyDesktop.app"
if [ ! -d "$BUILT_APP" ]; then
  echo "❌ 编译失败，找不到 app"
  exit 1
fi
echo "   ✅ 编译成功: $BUILT_APP"

# 3. Prepare DMG staging directory
echo "[3/5] 准备 DMG 内容..."
DMG_STAGING="$BUILD_DIR/dmg_staging"
rm -rf "$DMG_STAGING"
mkdir -p "$DMG_STAGING"

cp -R "$BUILT_APP" "$DMG_STAGING/$APP_NAME.app"
ln -s /Applications "$DMG_STAGING/Applications"

# 4. Create DMG
echo "[4/5] 创建 DMG..."
DMG_OUTPUT="$BUILD_DIR/${DMG_NAME}_${VERSION}.dmg"
rm -f "$DMG_OUTPUT"

hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$DMG_STAGING" \
  -ov \
  -format UDZO \
  "$DMG_OUTPUT" 2>&1 | grep -v "^$"

# 5. Cleanup
echo "[5/5] 清理临时文件..."
rm -rf "$DMG_STAGING"

echo ""
echo "=== 打包完成 ==="
echo "📦 DMG 路径: $DMG_OUTPUT"
echo "📦 大小: $(du -h "$DMG_OUTPUT" | cut -f1)"
echo ""
echo "双击 DMG -> 拖动 App 到 Applications 文件夹即可安装"

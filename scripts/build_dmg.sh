#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/.."
PROJECT_DIR="$ROOT_DIR/KittyDesktop"
BUILD_DIR="$ROOT_DIR/build"
APP_NAME="Kitty 桌面收纳"
DMG_NAME="KittyDesktop"

PROJECT_YML="$PROJECT_DIR/project.yml"
INFO_PLIST="$PROJECT_DIR/Resources/Info.plist"

# ── Read current version info from project.yml ──
MARKETING_VERSION=$(grep 'CFBundleShortVersionString:' "$PROJECT_YML" | head -1 | sed 's/.*: *"\(.*\)"/\1/')
CURRENT_BUILD=$(grep 'CFBundleVersion:' "$PROJECT_YML" | head -1 | sed 's/.*: *"\(.*\)"/\1/')

NEW_BUILD=$((CURRENT_BUILD + 1))

echo "=== Kitty 桌面收纳 — 打包 DMG ==="
echo "    版本: $MARKETING_VERSION  构建号: $CURRENT_BUILD -> $NEW_BUILD"
echo ""

# ── Update build number in project.yml ──
sed -i '' "s/CFBundleVersion: \"$CURRENT_BUILD\"/CFBundleVersion: \"$NEW_BUILD\"/" "$PROJECT_YML"

# ── Update build number in Info.plist ──
# Replace the value in the line AFTER the CFBundleVersion key
sed -i '' "/<key>CFBundleVersion<\/key>/{n;s/<string>.*<\/string>/<string>$NEW_BUILD<\/string>/;}" "$INFO_PLIST"

echo "[1/5] 生成 Xcode 项目..."
cd "$PROJECT_DIR"
xcodegen generate 2>&1 | grep -v "^$"

echo "[2/5] 编译 Release 版本..."
xcodebuild -project KittyDesktop.xcodeproj \
  -scheme KittyDesktop \
  -configuration Release \
  -derivedDataPath "$BUILD_DIR/DerivedData" \
  clean build 2>&1 | grep -E "(error:|warning:|BUILD)" | head -20

BUILT_APP="$BUILD_DIR/DerivedData/Build/Products/Release/KittyDesktop.app"
if [ ! -d "$BUILT_APP" ]; then
  echo "❌ 编译失败，找不到 app — 回滚构建号"
  sed -i '' "s/CFBundleVersion: \"$NEW_BUILD\"/CFBundleVersion: \"$CURRENT_BUILD\"/" "$PROJECT_YML"
  sed -i '' "/<key>CFBundleVersion<\/key>/{n;s/<string>.*<\/string>/<string>$CURRENT_BUILD<\/string>/;}" "$INFO_PLIST"
  exit 1
fi
echo "   ✅ 编译成功"

echo "[3/5] 准备 DMG 内容..."
DMG_STAGING="$BUILD_DIR/dmg_staging"
rm -rf "$DMG_STAGING"
mkdir -p "$DMG_STAGING"

cp -R "$BUILT_APP" "$DMG_STAGING/$APP_NAME.app"
ln -s /Applications "$DMG_STAGING/Applications"

echo "[4/5] 创建 DMG..."
DMG_OUTPUT="$BUILD_DIR/${DMG_NAME}_${MARKETING_VERSION}_b${NEW_BUILD}.dmg"
rm -f "$DMG_OUTPUT"

hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$DMG_STAGING" \
  -ov \
  -format UDZO \
  "$DMG_OUTPUT" 2>&1 | grep -v "^$"

echo "[5/5] 清理临时文件..."
rm -rf "$DMG_STAGING"

echo ""
echo "=== 打包完成 ==="
echo "    版本: v${MARKETING_VERSION} (build ${NEW_BUILD})"
echo "    DMG:  $DMG_OUTPUT"
echo "    大小: $(du -h "$DMG_OUTPUT" | cut -f1)"
echo ""
echo "双击 DMG -> 拖动 App 到 Applications 文件夹即可安装"

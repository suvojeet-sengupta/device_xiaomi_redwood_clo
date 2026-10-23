#!/bin/bash
#
# Build a signed Paranoid Android for redwood.
#
# Run it from the root of the AOSPA tree, after setup.sh:
#   ~/redwood-setup/build.sh
#
# The flashable zip ends up in the tree root, boot, vendor_boot and dtbo for
# fastboot in images/, and the OTA feed in device/xiaomi/redwood/ota. Set
# KEYS_DIR to sign with other keys, and OTA_URL when the zip won't be a
# GitHub release asset of the device tree (see device/xiaomi/redwood/ota/README.md).

set -euo pipefail

KEYS_DIR=${KEYS_DIR:-$HOME/keys}

die() { echo "build: $*" >&2; exit 1; }

[ -f rom-build.sh ] || die "run this from the root of the AOSPA tree"
[ -f "$KEYS_DIR/releasekey.pk8" ] || die "no keys in $KEYS_DIR, run setup.sh first"

./rom-build.sh redwood -t user -s "$KEYS_DIR"

tf=$(ls -t aospa-*-signed-target_files.zip 2>/dev/null | head -n 1)
[ -n "$tf" ] || die "no signed target files, the build failed"
zip=${tf%-signed-target_files.zip}.zip

mkdir -p images
unzip -o -j -q "$tf" IMAGES/boot.img IMAGES/vendor_boot.img IMAGES/dtbo.img -d images

feed=device/xiaomi/redwood/ota/make-feed.sh
if [ -x "$feed" ]; then
	"$feed" "$zip" ${OTA_URL:+"$OTA_URL"} || echo "build: no OTA feed, see above"
fi

echo
echo "ROM:    $(pwd)/$zip"
echo "Images: $(pwd)/images/{boot,vendor_boot,dtbo}.img"

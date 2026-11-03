#!/bin/bash
#
# Build a signed Paranoid Android for redwood with the 6.12 kernel.
#
# Run it from the root of the AOSPA or PenguinOS tree, after setup.sh:
#   ~/redwood-6.12-setup/build.sh
#
# The flashable zip ends up in the tree root, boot, vendor_boot and dtbo for
# fastboot in images/, and the OTA feed in device/xiaomi/redwood/ota. 6.12
# builds have their own feed on the clo-6.12 branch, so phones on the 5.4 ROM
# are never offered one. Set KEYS_DIR to sign with other keys, and OTA_URL
# when the zip won't be a GitHub release asset of the device tree (see
# device/xiaomi/redwood/ota/README.md).

set -euo pipefail

KEYS_DIR=${KEYS_DIR:-$HOME/keys}

die() { echo "build: $*" >&2; exit 1; }

[ -f rom-build.sh ] || die "run this from the root of the AOSPA tree"
[ -f "$KEYS_DIR/releasekey.pk8" ] || die "no keys in $KEYS_DIR, run setup.sh first"
grep -q "redwood-kernel-6.12" device/xiaomi/redwood/BoardConfig.mk ||
    die "device/xiaomi/redwood isn't the clo-6.12 device tree, run setup.sh first"
[ -f device/xiaomi/redwood-kernel-6.12/Image ] || die "no 6.12 kernel prebuilt, run setup.sh first"

# AOSPA only knows the alpha, beta and stable variants and builds unofficial
# without one; PenguinOS takes official.
variant=()
if [ -f .repo/manifests/penguin.xml ] || [ -d vendor/custom-preference ] ||
        [ -f frameworks/base/core/res/res/values/custom_config.xml ]; then
    variant=(-v official)
fi

./rom-build.sh redwood -t user "${variant[@]}" -s "$KEYS_DIR"

tf=$(ls -t ./*redwood*-signed-target_files.zip 2>/dev/null | head -n 1)
[ -n "$tf" ] || die "no signed target files, the build failed"
zip=${tf%-signed-target_files.zip}.zip

mkdir -p images
unzip -o -j -q "$tf" IMAGES/boot.img IMAGES/vendor_boot.img IMAGES/dtbo.img -d images

feed=device/xiaomi/redwood/ota/make-feed.sh
if [ -x "$feed" ]; then
	"$feed" "$zip" ${OTA_URL:+"$OTA_URL"} || echo "build: no OTA feed, see above"
fi

echo
echo "Kernel: $(sed -n 's/^release=//p' device/xiaomi/redwood-kernel-6.12/build-info.txt)"
echo "ROM:    $(pwd)/$zip"
echo "Images: $(pwd)/images/{boot,vendor_boot,dtbo}.img"

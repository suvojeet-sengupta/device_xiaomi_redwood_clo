#!/bin/bash
#
# Build a signed Paranoid Android for redwood with the 6.18 kernel.
#
# Run it from the root of the AOSPA or PenguinOS tree, after setup.sh:
#   ~/redwood-6.18-setup/build.sh
#
# The flashable zip ends up in the tree root, boot, vendor_boot and dtbo for
# fastboot in images/. It never writes an OTA feed: 6.18 builds are tests,
# and no phone on the 6.12 or 5.4 ROM must be offered one. Set KEYS_DIR to
# sign with other keys.

set -euo pipefail

KEYS_DIR=${KEYS_DIR:-$HOME/keys}

die() { echo "build: $*" >&2; exit 1; }

[ -f rom-build.sh ] || die "run this from the root of the AOSPA tree"
[ -f "$KEYS_DIR/releasekey.pk8" ] || die "no keys in $KEYS_DIR, run setup.sh first"
grep -q "redwood-kernel-6.18" device/xiaomi/redwood/BoardConfig.mk ||
    die "device/xiaomi/redwood isn't the 6.18 device tree, run setup.sh first"
[ -f device/xiaomi/redwood-kernel-6.18/Image ] || die "no 6.18 kernel prebuilt, run setup.sh first"

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


echo
echo "Kernel: $(sed -n 's/^release=//p' device/xiaomi/redwood-kernel-6.18/build-info.txt)"
echo "ROM:    $(pwd)/$zip"
echo "Images: $(pwd)/images/{boot,vendor_boot,dtbo}.img"

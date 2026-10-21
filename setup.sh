#!/bin/bash
#
# Set up redwood in a Paranoid Android calcite tree.
#
# Run it from the root of a synced AOSPA tree:
#   ~/redwood-setup/setup.sh
#
# It adds the redwood local manifest, syncs the redwood repos and makes
# signing keys in ~/keys if there are none yet. Set KEYS_DIR to use other keys.

set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
KEYS_DIR=${KEYS_DIR:-$HOME/keys}

die() { echo "setup: $*" >&2; exit 1; }

[ -d .repo ] && [ -f build/envsetup.sh ] ||
    die "run this from the root of a synced AOSPA tree"

echo "==> Adding the redwood local manifest"
mkdir -p .repo/local_manifests
cp "$HERE/redwood.xml" .repo/local_manifests/redwood.xml

echo "==> Syncing the redwood repos"
paths=$(grep -oE 'path="[^"]+"' "$HERE/redwood.xml" | cut -d'"' -f2)
# shellcheck disable=SC2086
repo sync -c --no-tags --force-sync -j"$(nproc --all)" $paths

echo "==> Signing keys"
mkdir -p "$KEYS_DIR"
subject='/C=US/ST=California/L=Mountain View/O=Android/OU=Android/CN=Android/emailAddress=android@android.com'
for key in releasekey platform shared media networkstack sdk_sandbox; do
    if [ -f "$KEYS_DIR/$key.pk8" ]; then
        echo "    $key: already there"
    else
        echo | ./development/tools/make_key "$KEYS_DIR/$key" "$subject" >/dev/null 2>&1 ||
            [ -f "$KEYS_DIR/$key.pk8" ] || die "couldn't make the $key key"
        echo "    $key: made"
    fi
done

echo
echo "Done. Keep a copy of $KEYS_DIR off this machine."
echo "Now build with: $HERE/build.sh"

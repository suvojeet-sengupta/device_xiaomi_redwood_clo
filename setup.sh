#!/bin/bash
#
# Set up redwood in a Paranoid Android calcite tree.
#
# Run it from the root of a synced AOSPA tree:
#   ~/redwood-setup/setup.sh
#
# It adds the redwood local manifest, syncs the redwood repos and clones the
# signing keys from GitHub into ~/keys. It never makes keys: a build signed
# with new keys can't be flashed over a phone running the old ones without
# wiping it. Set KEYS_REPO (default suvojeet-sengupta/keys) to clone another
# repo and KEYS_DIR to keep them elsewhere. For a private repo, be logged in
# with gh or pass GH_TOKEN.

set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
KEYS_DIR=${KEYS_DIR:-$HOME/keys}
KEYS_REPO=${KEYS_REPO:-suvojeet-sengupta/keys}
KEYS="releasekey platform shared media networkstack sdk_sandbox"

die() { echo "setup: $*" >&2; exit 1; }

# Use GH_TOKEN or the gh login for GitHub without putting a token in a URL.
git_auth() {
    if [ -n "${GH_TOKEN:-}" ]; then
        git -c credential.helper= \
            -c credential.helper='!f() { echo username=x-access-token; echo "password=$GH_TOKEN"; }; f' "$@"
    elif command -v gh >/dev/null && gh auth status >/dev/null 2>&1; then
        git -c credential.helper= -c credential.helper='!gh auth git-credential' "$@"
    else
        git "$@"
    fi
}

fingerprint() {
    openssl x509 -noout -fingerprint -sha256 -in "$1" | cut -d= -f2
}

[ -d .repo ] && [ -f build/envsetup.sh ] ||
    die "run this from the root of a synced AOSPA tree"

echo "==> Adding the redwood local manifest"
mkdir -p .repo/local_manifests
cp "$HERE/redwood.xml" .repo/local_manifests/redwood.xml

echo "==> Syncing the redwood repos"
paths=$(grep -oE 'path="[^"]+"' "$HERE/redwood.xml" | cut -d'"' -f2)
# shellcheck disable=SC2086
repo sync -c --no-tags --force-sync -j"$(nproc --all)" $paths

echo "==> Signing keys from $KEYS_REPO"
if [ -d "$KEYS_DIR/.git" ]; then
    git_auth -C "$KEYS_DIR" pull -q --ff-only || die "couldn't update $KEYS_DIR"
    echo "    updated $KEYS_DIR"
elif [ -f "$KEYS_DIR/releasekey.pk8" ]; then
    # Keys from somewhere else: only keep going if they are the same keys.
    tmp=$(mktemp -d)
    trap 'rm -rf "$tmp"' EXIT
    git_auth clone -q --depth=1 "https://github.com/$KEYS_REPO.git" "$tmp/keys" ||
        die "couldn't clone $KEYS_REPO to check $KEYS_DIR against it"
    for key in releasekey platform; do
        [ "$(fingerprint "$KEYS_DIR/$key.x509.pem")" = "$(fingerprint "$tmp/keys/$key.x509.pem")" ] ||
            die "$KEYS_DIR/$key isn't the $key from $KEYS_REPO; move $KEYS_DIR aside and run this again"
    done
    echo "    $KEYS_DIR has the keys from $KEYS_REPO"
else
    if [ -e "$KEYS_DIR" ]; then
        rmdir "$KEYS_DIR" 2>/dev/null ||
            die "$KEYS_DIR has no releasekey but isn't empty; move it aside and run this again"
    fi
    git_auth clone -q --depth=1 "https://github.com/$KEYS_REPO.git" "$KEYS_DIR" ||
        die "couldn't clone $KEYS_REPO; log in with gh or set GH_TOKEN"
    echo "    cloned into $KEYS_DIR"
fi
chmod -R go-rwx "$KEYS_DIR"
for key in $KEYS; do
    [ -f "$KEYS_DIR/$key.pk8" ] && [ -f "$KEYS_DIR/$key.x509.pem" ] ||
        die "$KEYS_REPO has no $key key"
done

echo
echo "Now build with: $HERE/build.sh"

#!/bin/bash
#
# SPDX-FileCopyrightText: Paranoid Android
# SPDX-License-Identifier: Apache-2.0
#
# Write the ParanoidHub feed for a signed redwood build:
#   device/xiaomi/redwood/ota/make-feed.sh <rom.zip> [url]
#
# Run it from the root of the AOSPA tree right after the build, so the
# build props in out/ belong to the zip. Without a url the zip is expected
# as an asset of the redwood-6.18-<date> release of the device tree on GitHub,
# or on SourceForge (AOSPA/redwood-6.18/<date>/) when it's over 2 GiB.
# The changelog comes from changelog.txt next to this script, if there is
# one. The feed is written to <device>.json next to this script; commit and
# push it to publish the build (see README.md).

set -euo pipefail

die() { echo "make-feed: $*" >&2; exit 1; }

zip=${1:-}
[ -f "$zip" ] || die "usage: $0 <rom.zip> [url]"
here=$(cd "$(dirname "$0")" && pwd)
prop=out/target/product/redwood/system/build.prop
[ -f "$prop" ] || die "no $prop, run this from the tree you built in"
grep -q "redwood-kernel-6.18" device/xiaomi/redwood/BoardConfig.mk ||
    die "this tree doesn't build the 6.18 kernel; its builds don't belong in the 6.18 feed"

getprop() { sed -n "s/^$1=//p" "$prop" | tail -n 1; }
meta() { unzip -p "$zip" META-INF/com/android/metadata | sed -n "s/^$1=//p"; }

device=$(getprop ro.aospa.device)
timestamp=$(meta post-timestamp)
[ -n "$device" ] && [ -n "$timestamp" ] || die "can't read the device or the build time"
[ "$timestamp" = "$(getprop ro.build.date.utc)" ] ||
    die "$zip isn't the build in out/ (the build times differ)"
last=$(python3 -c 'import json, sys; u = json.load(open(sys.argv[1])).get("updates", []); print(max([int(x["datetime"]) for x in u] or [0]))' "$here/$device.json" 2>/dev/null || echo 0)
[ "$timestamp" -gt "$last" ] ||
    die "build time $timestamp isn't newer than the published $last, so phones wouldn't be offered it (an incremental build keeps the old build.prop date: build with -i)"

major=$(getprop ro.aospa.version.major)
minor=$(getprop ro.aospa.version.minor)
date=$(date -u -d "@$timestamp" +%Y%m%d)
size=$(stat -c %s "$zip")
name=$(basename "$zip")
# Up to 2 GiB the zip fits a GitHub release of the device tree; a bigger
# one goes to SourceForge, AOSPA/redwood-6.18/<date>/ of builds-by-suvojeet.
if [ -n "${2:-}" ]; then
    url=$2
elif [ "$size" -lt $((2 * 1024 * 1024 * 1024)) ]; then
    url=https://github.com/suvojeet-sengupta/device_xiaomi_redwood_clo/releases/download/$device-6.18-$date/$name
else
    url=https://downloads.sourceforge.net/project/builds-by-suvojeet/AOSPA/redwood-6.18/$date/$name
fi

FEED_SPL=$(meta post-security-patch-level) \
FEED_TYPE=$(getprop ro.aospa.build.variant) \
FEED_TIME=$timestamp \
FEED_NAME=$name \
FEED_MAINTAINER=$(getprop ro.aospa.maintainer) \
FEED_SHA256=$(sha256sum "$zip" | cut -d " " -f 1) \
FEED_SIZE=$size \
FEED_URL=$url \
FEED_VERSION=${major^} \
FEED_CODE=${minor:-$date} \
FEED_CHANGELOG=$here/changelog.txt \
python3 - "$here/$device.json" <<'PY'
import json, os, sys

e = os.environ
try:
    with open(e["FEED_CHANGELOG"]) as f:
        changelog = f.read().strip()
except FileNotFoundError:
    changelog = ""

entry = {
    "android_spl": e["FEED_SPL"],
    "build_type": e["FEED_TYPE"],
    "changelog_device": changelog,
    "datetime": e["FEED_TIME"],
    "filename": e["FEED_NAME"],
    "maintainer": e["FEED_MAINTAINER"],
    "recovery_sha256": e["FEED_SHA256"],
    "size": e["FEED_SIZE"],
    "url": e["FEED_URL"],
    "version": e["FEED_VERSION"],
    "version_code": e["FEED_CODE"],
}
with open(sys.argv[1], "w") as f:
    json.dump({"updates": [entry]}, f, indent=2)
    f.write("\n")
PY

echo "Feed:   $here/$device.json"
echo "Upload: $name to $url"

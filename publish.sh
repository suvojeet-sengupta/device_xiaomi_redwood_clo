#!/usr/bin/env bash
#
# SPDX-FileCopyrightText: 2026 suvojeet-sengupta
# SPDX-License-Identifier: Apache-2.0
#
# Publish the latest redwood ROM build to the ServerHive web server, with an
# IST timestamp, and optionally to SourceForge. Works for both PenguinOS and
# AOSPA; the ROM is detected from the build ZIP. The boot, vendor_boot and
# dtbo images are taken from the signed target files, never from out/.
#
# Usage, run from the ROM tree root (or pass it as the first argument):
#   device/xiaomi/redwood/publish.sh [TREE_DIR] [--sf] [--dry-run]
#     TREE_DIR   ROM tree root (default: current directory)
#     --sf       also upload to SourceForge
#     --dry-run  show what would happen, copy and upload nothing

set -euo pipefail

# --- settings ---------------------------------------------------------------
WEB_ROOT="/var/www/html/suvojeetsengupta"
WEB_URL="https://ferrari.serverhive.in/suvojeetsengupta"
SF_KEY="$HOME/.ssh/sf_ed25519"
SF_HOST="frs.sourceforge.net"
SF_ROOT="/home/frs/project/builds-by-suvojeet"

# --- arguments --------------------------------------------------------------
TREE="" ; SF=0 ; DRY=0
for arg in "$@"; do
    case "$arg" in
        --sf) SF=1 ;;
        --dry-run|-n) DRY=1 ;;
        -*) echo "unknown option: $arg" >&2; exit 2 ;;
        *) TREE="$arg" ;;
    esac
done
TREE="$(cd "${TREE:-$PWD}" && pwd)"
OUT="$TREE/out/target/product/redwood"

say() { printf '%s\n' "$*"; }
run() { if [ "$DRY" -eq 1 ]; then echo "  [dry-run] $*"; else eval "$*"; fi; }

# --- find the flashable ROM ZIP ---------------------------------------------
# PenguinOS leaves its ZIP in the tree root; AOSPA leaves it under out/.
zip="$(ls -t \
        "$TREE"/PenguinOS-*-redwood.zip \
        "$OUT"/aospa-*.zip \
        "$OUT"/*-redwood.zip \
        2>/dev/null | grep -vE -- '-ota|target_files' | head -n1 || true)"
[ -n "$zip" ] && [ -f "$zip" ] || { echo "ERROR: no build ZIP found in $TREE or $OUT" >&2; exit 1; }

base="$(basename "$zip")"
case "$base" in
    PenguinOS*) rom="PenguinOS-celerity"; sf_proj="PenguinOS"; img_prefix="penguinos-redwood"; web_sub="penguin" ;;
    *)          rom="aospa-calcite";      sf_proj="AOSPA";     img_prefix="aospa-redwood";     web_sub="aospa" ;;
esac
# optional variant tag from the ZIP name (gms / vanilla)
variant=""
case "$base" in *gms*) variant="-gms" ;; *vanilla*) variant="-vanilla" ;; esac

# --- find the three images in the signed target files -----------------------
# Prefer an already-unpacked IMAGES dir, else unzip from the target files ZIP.
imgdir="$(ls -dt \
        "$TREE"/*-signed-target_files/IMAGES \
        "$OUT"/obj/PACKAGING/target_files_intermediates/*target_files/IMAGES \
        2>/dev/null | head -n1 || true)"
tf_zip="$(ls -t \
        "$TREE"/*-signed-target_files.zip \
        "$OUT"/obj/PACKAGING/target_files_intermediates/*target_files.zip \
        2>/dev/null | head -n1 || true)"

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
declare -A img
for i in boot vendor_boot dtbo; do
    if [ -n "$imgdir" ] && [ -f "$imgdir/$i.img" ]; then
        img[$i]="$imgdir/$i.img"
    elif [ -n "$tf_zip" ]; then
        unzip -q -o "$tf_zip" "IMAGES/$i.img" -d "$tmp"
        img[$i]="$tmp/IMAGES/$i.img"
    fi
    [ -n "${img[$i]:-}" ] && [ -f "${img[$i]}" ] || { echo "ERROR: $i.img not found in signed target files" >&2; exit 1; }
done

# --- names ------------------------------------------------------------------
ts="$(TZ=Asia/Kolkata date +%Y%m%d-%H%M)"     # IST, to match GitHub
day="$(TZ=Asia/Kolkata date +%Y%m%d)"
name="$rom-redwood${variant}-$ts"

say "ROM ZIP : $zip"
say "Images  : ${img[boot]} / ${img[vendor_boot]} / ${img[dtbo]}"
say "Name    : $name"
say "Verifying ROM ZIP..."
[ "$DRY" -eq 1 ] || unzip -tq "$zip" >/dev/null

# --- publish to the web server ----------------------------------------------
web="$WEB_ROOT/$web_sub"
say "Publishing to $web ..."
run "mkdir -p '$web'"
run "cp -- '$zip' '$web/$name.zip'"
for i in boot vendor_boot dtbo; do
    run "cp -- '${img[$i]}' '$web/$name-$i.img'"
done
if [ "$DRY" -eq 0 ]; then
    ( cd "$web"
      sha256sum "$name.zip" "$name-boot.img" "$name-vendor_boot.img" "$name-dtbo.img" > "$name-SHA256SUMS"
      chmod 644 "$name".* "$name"-*.img )
    chmod 755 "$WEB_ROOT" "$web"
fi

say ""
say "========================================"
say "       WEB LINKS"
say "========================================"
for f in "$name.zip" "$name-boot.img" "$name-vendor_boot.img" "$name-dtbo.img" "$name-SHA256SUMS"; do
    say "$WEB_URL/$web_sub/$f"
done

# --- optional SourceForge upload --------------------------------------------
if [ "$SF" -eq 1 ]; then
    say ""
    say "Uploading to SourceForge ($sf_proj/redwood) ..."
    [ -f "$SF_KEY" ] || { echo "ERROR: SourceForge key $SF_KEY missing" >&2; exit 1; }
    sfdir="$SF_ROOT/$sf_proj/redwood"
    sftp_cmd="-mkdir $sfdir/$day
put $web/$name.zip $sfdir/$day/$name.zip
put @STAGE@/$name.zip.sha256 $sfdir/$day/$name.zip.sha256
put @STAGE@/$img_prefix-boot.img $sfdir/common/$img_prefix-boot.img
put @STAGE@/$img_prefix-vendor_boot.img $sfdir/common/$img_prefix-vendor_boot.img
put @STAGE@/$img_prefix-dtbo.img $sfdir/common/$img_prefix-dtbo.img
put @STAGE@/SHA256SUMS $sfdir/common/SHA256SUMS"
    if [ "$DRY" -eq 1 ]; then
        echo "  [dry-run] stage images + checksums, then sftp to $SF_HOST:"
        printf '    %s\n' "${sftp_cmd//@STAGE@/<stage>}"
    else
        stage="$(mktemp -d)"; trap 'rm -rf "$tmp" "$stage"' EXIT
        cp -- "${img[boot]}"        "$stage/$img_prefix-boot.img"
        cp -- "${img[vendor_boot]}" "$stage/$img_prefix-vendor_boot.img"
        cp -- "${img[dtbo]}"        "$stage/$img_prefix-dtbo.img"
        ( cd "$stage"; sha256sum "$img_prefix"-*.img > SHA256SUMS )
        sha256sum "$zip" | awk -v n="$name.zip" '{print $1"  "n}' > "$stage/$name.zip.sha256"
        sftp -b - -i "$SF_KEY" -o BatchMode=yes "$SF_HOST" <<EOF
${sftp_cmd//@STAGE@/$stage}
EOF
    fi
    say ""
    say "========================================"
    say "       SOURCEFORGE"
    say "========================================"
    say "https://sourceforge.net/projects/builds-by-suvojeet/files/$sf_proj/redwood/$day/$name.zip/download"
    say "https://sourceforge.net/projects/builds-by-suvojeet/files/$sf_proj/redwood/common/"
fi

say ""
say "Done."

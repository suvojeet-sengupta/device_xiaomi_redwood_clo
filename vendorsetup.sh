#
# Copyright (C) 2026 Paranoid Android
#
# SPDX-License-Identifier: Apache-2.0
#

# Apply the source patches redwood needs. Patches in patches/common/ apply
# to both ROMs, the ones in patches/aospa/ and patches/penguinos/ only to
# that ROM. Patches that are already applied are skipped, so this is safe
# to run on every envsetup. The ROM is found from the repo manifest; set
# REDWOOD_ROM=aospa or REDWOOD_ROM=penguinos to pick it by hand.

redwood_apply_patches() {
    local top="${T:-$(gettop)}"
    local device="$top/device/xiaomi/redwood"
    local rom patches patch dir subject

    case "$REDWOOD_ROM" in
    aospa|penguinos)
        rom="$REDWOOD_ROM"
        ;;
    "")
        # PenguinOS adds penguin.xml to the manifest and its own repos;
        # its frameworks/base also has custom_config.xml
        if [ -f "$top/.repo/manifests/penguin.xml" ] ||
                [ -d "$top/vendor/custom-preference" ] ||
                [ -f "$top/frameworks/base/core/res/res/values/custom_config.xml" ]; then
            rom=penguinos
        else
            rom=aospa
        fi
        ;;
    *)
        echo "redwood: unknown REDWOOD_ROM '$REDWOOD_ROM', use aospa or penguinos" >&2
        return 1
        ;;
    esac
    echo "redwood: applying the common and $rom patches" >&2

    for patches in "$device/patches/common" "$device/patches/$rom"; do
        [ -d "$patches" ] || continue

        for patch in $(cd "$patches" && find . -name '*.patch' | sort); do
            patch="${patch#./}"
            dir="$top/$(dirname "$patch")"
            [ -d "$dir" ] || continue

            # Already applied. A later patch can change the same lines, so
            # also look for the commit itself, not just for its changes.
            if git -C "$dir" apply --check --reverse "$patches/$patch" &>/dev/null; then
                continue
            fi
            subject="$(git mailinfo /dev/null /dev/null < "$patches/$patch" | sed -n 's/^Subject: //p')"
            if [ -n "$subject" ] && git -C "$dir" log -n 500 --format=%s | grep -Fxq -- "$subject"; then
                continue
            fi

            if git -C "$dir" -c user.name=suvojeet-sengupta -c user.email=suvojitsengupta21@gmail.com \
                    am -q --3way "$patches/$patch" &>/dev/null; then
                echo "redwood: applied $patch" >&2
            else
                git -C "$dir" am --abort &>/dev/null
                echo "redwood: failed to apply $patch" >&2
            fi
        done
    done
}

redwood_apply_patches
unset -f redwood_apply_patches

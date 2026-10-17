Copyright (C) 2026 Paranoid Android

# Device tree for Xiaomi Poco X5 Pro 5G / Redmi Note 12 Pro Speed (redwood)

This is a CLO device tree for redwood, written and maintained by
[Suvojeet Sengupta](https://github.com/suvojeet-sengupta).

CLO stands for CodeLinaro (formerly CodeAurora), where Qualcomm publishes its
Android sources. A CLO tree builds on Qualcomm's own QSSI and vendor
components instead of the AOSP versions, the same base Paranoid Android uses.
This tree builds Paranoid Android `calcite` (Android 17) and PenguinOS
`celerity`.

## Specifications

| Component | Details |
|-----------|---------|
| Chipset   | Qualcomm Snapdragon 778G 5G (SM7325) |
| CPU       | Octa-core Kryo 670, up to 2.4 GHz |
| GPU       | Adreno 642L |
| RAM       | 6/8 GB LPDDR4X |
| Storage   | 128/256 GB UFS 2.2 |
| Display   | 6.67" AMOLED, 2400 x 1080, 120 Hz, HDR10+, Dolby Vision |
| Battery   | 5000 mAh, 67 W charging |
| Cameras   | 108 MP main, 8 MP ultra wide, 2 MP macro, 16 MP front |
| Shipped   | Android 12 (MIUI 14) |

![Poco X5 Pro 5G](https://i.blogs.es/98a725/poco-x5-pro/1366_2000.jpeg)

## What's in the tree

- Kernel: prebuilt Vajra 3.1 (5.4.302) by genie1997, with KernelSU-Next
  and SuSFS, from `device/xiaomi/redwood-kernel`
- Vendor: extracted from stock HyperOS, in `vendor/xiaomi/redwood`
- Camera: Leica mod MIUI Camera, from `vendor/xiaomi/redwood-miuicamera` (`leica` branch)
- Audio: Dolby Atmos, from `hardware/dolby`
- Face unlock: ParanoidSense
- Xiaomi parts: charging control and other device settings
- Play Integrity: basic integrity out of the box, device and strong integrity
  with Play Integrity Fix and Tricky Store
- Gestures: double tap to wake, three finger swipe to screenshot

## Getting the sources

Add this to `.repo/local_manifests/redwood.xml`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<manifest>
  <remote name="penguin" fetch="https://github.com/" />

  <!-- lahaina platform -->
  <project path="vendor/qcom/opensource/audio-hal/primary-hal" name="AOSPA/android_hardware_qcom_audio" remote="aospa" revision="calcite-888" />
  <project path="hardware/qcom/display" name="AOSPA/android_hardware_qcom_display" remote="aospa" revision="calcite-888" />
  <project path="hardware/qcom/gps" name="AOSPA/android_hardware_qcom_gps" remote="aospa" revision="calcite-legacy-component" />
  <project path="hardware/qcom/media" name="AOSPA/android_hardware_qcom_media" remote="aospa" revision="calcite-888" />
  <remove-project name="AOSPA/android_hardware_qcom_thermal" />
  <project path="vendor/qcom/opensource/thermal-hal" name="AOSPA/android_hardware_qcom_thermal" remote="aospa" revision="calcite-legacy" />

  <!-- qcom common -->
  <remove-project name="AOSPA/android_device_qcom_common" />
  <project path="device/qcom/common" name="Project-PenguinOS/device_qcom_common" remote="penguin" revision="celerity">
    <linkfile dest="vendor/qcom/build/tasks/generate_extra_images.mk" src="generate_extra_images.mk"/>
  </project>

  <!-- redwood -->
  <project path="device/xiaomi/redwood" name="suvojeet-sengupta/device_xiaomi_redwood_clo" remote="github" revision="clo" />
  <project path="device/xiaomi/redwood-kernel" name="suvojeet-sengupta/device_xiaomi_redwood-kernel" remote="github" revision="clo" clone-depth="1" />
  <project path="vendor/xiaomi/redwood" name="suvojeet-sengupta/vendor_xiaomi_redwood" remote="github" revision="clo" clone-depth="1" />
  <project path="vendor/xiaomi/redwood-miuicamera" name="suvojeet-sengupta/android_vendor_xiaomi_redwood-miuicamera" remote="github" revision="leica" clone-depth="1" />
  <project path="packages/apps/ParanoidSense" name="AOSPA/android_packages_apps_ParanoidSense" remote="aospa" revision="calcite" />
  <project path="hardware/xiaomi" name="AOSPA/android_hardware_xiaomi" remote="aospa" revision="calcite" />
  <project path="hardware/dolby" name="suvojeet-sengupta/hardware_dolby" remote="github" revision="moto/dolby-dolbyvision" clone-depth="1" />
</manifest>
```

Then sync:

```bash
repo sync --current-branch --no-tags -j4
```

The tree carries the source patches redwood needs in `patches/`:
`common/` for both ROMs, `aospa/` and `penguinos/` for one ROM only.
Features live in `features/<name>/`, split the same way into `common/`,
`aospa/` and `penguinos/`, and are applied after the fixes, in name order.
`vendorsetup.sh` applies them automatically when you run
`build/envsetup.sh` or `rom-build.sh`, so there's nothing to apply by hand,
and they survive a `repo sync`.
The ROM is found from the repo manifest; set `REDWOOD_ROM=aospa` or
`REDWOOD_ROM=penguinos` before `. build/envsetup.sh` to pick it by hand.

## Building

```bash
./rom-build.sh redwood
```

For a release signed build, pass the folder with your signing keys:

```bash
./rom-build.sh redwood -t user -s ~/.android-certs
```

Moving between test keys and release keys needs a data wipe. Keep a backup of
your keys off the build server, since a build signed with different keys can't
be flashed over yours.

## Updating vendor blobs

Re-extract `vendor/xiaomi/redwood` whenever `proprietary-files.txt` changes,
from a dump of the stock HyperOS firmware:

```bash
cd device/xiaomi/redwood
./extract-files.py /path/to/stock/dump
```

## Credits

- [Paranoid Android](https://github.com/AOSPA) and
  [PenguinOS](https://github.com/Project-PenguinOS) for the ROMs and the qcom
  common trees

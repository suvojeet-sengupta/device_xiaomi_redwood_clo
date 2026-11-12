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

- Kernel: prebuilt 6.18.33-Suvkernel (Android Common Kernel
  android17-6.18 with Qualcomm's lahaina platform carried over from 6.12),
  from [device_xiaomi_redwood-kernel-6.18](https://github.com/suvojeet-sengupta/device_xiaomi_redwood-kernel-6.18)
  in `device/xiaomi/redwood-kernel-6.18`, with every module in the vendor
  ramdisk. Source: [redwood-6.18-kernel](https://github.com/suvojeet-sengupta/redwood-6.18-kernel)
  and [redwood-6.18-modules](https://github.com/suvojeet-sengupta/redwood-6.18-modules)
  (`main`); what works is tracked in
  [redwood-6.18-devicetrees](https://github.com/suvojeet-sengupta/redwood-6.18-devicetrees).
  The 6.12 ROM is the `clo-6.12` branch, the 5.4 ROM the `clo` branch.
- Vendor: extracted from stock HyperOS, in `vendor/xiaomi/redwood`
- Camera: stock MIUI Camera, from [genie1997/redwood_miuicamera](https://github.com/genie1997/redwood_miuicamera) (`seventeen` branch) in `vendor/xiaomi/redwood-miuicamera`
- Audio: Dolby Atmos, from `hardware/dolby`
- Face unlock: ParanoidSense
- Xiaomi parts: charging control and other device settings
- Play Integrity: basic integrity out of the box, device and strong integrity
  with Play Integrity Fix and Tricky Store
- Gestures: double tap to wake, three finger swipe to screenshot
- Power menu: restart to recovery or the bootloader, switched on in
  System > Gestures > Power menu
- App Lock, and a heads-up notifications switch in Notifications
- Display: 120 Hz forced by default, adaptive refresh can be turned back on

## Building

You need a synced Paranoid Android `calcite` tree. The setup and build
scripts for this branch are in
[`6.18-setup`](https://github.com/suvojeet-sengupta/device_xiaomi_redwood_clo/tree/6.18-setup).
Run these from the root of the tree:

```bash
git clone -b 6.18-setup https://github.com/suvojeet-sengupta/device_xiaomi_redwood_clo.git ~/redwood-6.18-setup
~/redwood-6.18-setup/setup.sh
~/redwood-6.18-setup/build.sh
```

`setup.sh` adds the redwood local manifest (this branch and the 6.18 kernel
prebuilt), syncs the redwood repos and clones the signing keys into `~/keys`.
`build.sh` builds a ROM signed with those keys; the flashable zip ends up in
the tree root, and boot, vendor_boot and dtbo in `images/`. 6.18 builds
never write an OTA feed. For the 6.12 ROM use
[`clo-6.12-setup`](https://github.com/suvojeet-sengupta/device_xiaomi_redwood_clo/tree/clo-6.12-setup)
instead.

6.18 shares `/data` with the ROM on the other slot: back up before
flashing, and go back with `fastboot --set-active` if it doesn't boot.

Keep a copy of your keys off the build machine: a build signed with other
keys can't be flashed over yours without wiping data.

The source patches redwood needs are kept in
[device_xiaomi_redwood-patches](https://github.com/suvojeet-sengupta/device_xiaomi_redwood-patches),
which the local manifest syncs to `device/xiaomi/redwood-patches`. They're
applied when you run `envsetup.sh`, so there's nothing to apply by hand.

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

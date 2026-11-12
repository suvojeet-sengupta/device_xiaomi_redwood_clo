# redwood setup, 6.18 kernel

Scripts to build Paranoid Android `calcite` for the Poco X5 Pro 5G / Redmi
Note 12 Pro Speed (redwood) with the **6.18.33-Suvkernel** kernel (Android
Common Kernel `android17-6.18` with Qualcomm's lahaina platform), from the
[`6.18`](https://github.com/suvojeet-sengupta/device_xiaomi_redwood_clo/tree/6.18)
device tree and the
[`device_xiaomi_redwood-kernel-6.18`](https://github.com/suvojeet-sengupta/device_xiaomi_redwood-kernel-6.18)
prebuilt. For the 6.12 ROM use the
[`clo-6.12-setup`](https://github.com/suvojeet-sengupta/device_xiaomi_redwood_clo/tree/clo-6.12-setup)
branch, for 5.4 [`clo-setup`](https://github.com/suvojeet-sengupta/device_xiaomi_redwood_clo/tree/clo-setup).

You need a synced AOSPA calcite tree. Run everything from its root:

```bash
git clone -b 6.18-setup https://github.com/suvojeet-sengupta/device_xiaomi_redwood_clo.git ~/redwood-6.18-setup
~/redwood-6.18-setup/setup.sh
~/redwood-6.18-setup/build.sh
```

- `setup.sh` puts this `redwood.xml` in `.repo/local_manifests` (device tree
  on `6.18`, the source patches at `device/xiaomi/redwood-patches`, the 6.18
  kernel prebuilt at `device/xiaomi/redwood-kernel-6.18`), syncs the redwood
  repos, clones the signing keys into `~/keys` and checks that the tree
  really builds 6.18.
- `build.sh` builds a signed ROM. The flashable zip ends up in the tree
  root, and boot, vendor_boot and dtbo in `images/`. It refuses a tree that
  isn't set up for 6.18, and it never writes an OTA feed, so phones on the
  6.12 or 5.4 ROM aren't offered a 6.18 build.

Before flashing: 6.18 uses the same `/data` as the ROM on the other slot.
Back up your data first. If 6.18 doesn't boot, go back with
`fastboot --set-active=<the other slot>`. What works on 6.18 is tracked in
[redwood-6.18-devicetrees](https://github.com/suvojeet-sengupta/redwood-6.18-devicetrees).

The keys work as on `clo-setup`: `setup.sh` never makes keys, it clones them
from `KEYS_REPO` (default `suvojeet-sengupta/keys`), and stops if `~/keys`
(or `KEYS_DIR`) holds other keys.

To update, pull this branch and run both scripts again:

```bash
git -C ~/redwood-6.18-setup pull
~/redwood-6.18-setup/setup.sh
~/redwood-6.18-setup/build.sh
```

To go back to building 6.12 in the same tree, run `clo-6.12-setup`'s
`setup.sh`; it puts the 6.12 `redwood.xml` back and syncs the `clo-6.12`
device tree.

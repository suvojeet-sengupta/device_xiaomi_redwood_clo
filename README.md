# redwood setup, 6.12 kernel

Scripts to build Paranoid Android `calcite` for the Poco X5 Pro 5G / Redmi
Note 12 Pro Speed (redwood) with the **6.12.81-Suvkernel** kernel (Qualcomm
KERNEL.PLATFORM.5.0), from the
[`clo-6.12`](https://github.com/suvojeet-sengupta/device_xiaomi_redwood_clo/tree/clo-6.12)
device tree and the
[`device_xiaomi_redwood-kernel-6.12`](https://github.com/suvojeet-sengupta/device_xiaomi_redwood-kernel-6.12)
prebuilt. For the 5.4 ROM use the
[`clo-setup`](https://github.com/suvojeet-sengupta/device_xiaomi_redwood_clo/tree/clo-setup)
branch instead.

You need a synced AOSPA calcite tree. Run everything from its root:

```bash
git clone -b clo-6.12-setup https://github.com/suvojeet-sengupta/device_xiaomi_redwood_clo.git ~/redwood-6.12-setup
~/redwood-6.12-setup/setup.sh
~/redwood-6.12-setup/build.sh
```

- `setup.sh` puts this `redwood.xml` in `.repo/local_manifests` (device tree
  on `clo-6.12`, the 6.12 kernel prebuilt at
  `device/xiaomi/redwood-kernel-6.12`), syncs the redwood repos, clones the
  signing keys into `~/keys` and checks that the tree really builds 6.12.
- `build.sh` builds a signed ROM. The flashable zip ends up in the tree root,
  and boot, vendor_boot and dtbo in `images/`. It refuses a tree that isn't
  set up for 6.12, and it never touches the OTA feed, so phones on the 5.4
  ROM aren't offered a 6.12 build.

Before flashing: 6.12 uses the same `/data` as the 5.4 ROM on the other slot.
Back up your data first. If 6.12 doesn't boot, go back with
`fastboot --set-active=<the 5.4 slot>`.

The keys work as on `clo-setup`: `setup.sh` never makes keys, it clones them
from `KEYS_REPO` (default `suvojeet-sengupta/keys`), and stops if `~/keys`
(or `KEYS_DIR`) holds other keys.

To update, pull this branch and run both scripts again:

```bash
git -C ~/redwood-6.12-setup pull
~/redwood-6.12-setup/setup.sh
~/redwood-6.12-setup/build.sh
```

To go back to building 5.4 in the same tree, run `clo-setup`'s `setup.sh`;
it puts the 5.4 `redwood.xml` back and syncs the `clo` device tree.

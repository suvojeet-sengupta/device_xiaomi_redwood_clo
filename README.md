# redwood setup

Scripts to build Paranoid Android `calcite` for the Poco X5 Pro 5G / Redmi
Note 12 Pro Speed (redwood), from the
[`clo`](https://github.com/suvojeet-sengupta/device_xiaomi_redwood_clo/tree/clo)
device tree.

You need a synced AOSPA calcite tree. Run everything from its root:

```bash
git clone -b clo-setup https://github.com/suvojeet-sengupta/device_xiaomi_redwood_clo.git ~/redwood-setup
~/redwood-setup/setup.sh
~/redwood-setup/build.sh
```

- `setup.sh` adds `redwood.xml` to `.repo/local_manifests`, syncs the redwood
  repos and makes signing keys in `~/keys` if there are none yet.
- `build.sh` builds a signed ROM. The flashable zip ends up in the tree root,
  and boot, vendor_boot and dtbo in `images/`.

Set `KEYS_DIR` to use keys from somewhere else. Keep a copy of your keys off
the build machine: a build signed with other keys can't be flashed over yours
without wiping data.

To update, pull this branch and run both scripts again:

```bash
git -C ~/redwood-setup pull
~/redwood-setup/setup.sh
~/redwood-setup/build.sh
```

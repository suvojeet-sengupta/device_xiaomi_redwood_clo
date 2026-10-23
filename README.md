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
  repos and clones the signing keys from GitHub into `~/keys`.
- `build.sh` builds a signed ROM. The flashable zip ends up in the tree root,
  and boot, vendor_boot and dtbo in `images/`.

`setup.sh` never makes keys. A build signed with other keys can't be flashed
over a phone running yours without wiping data, and its OTAs won't install,
so every build machine has to sign with the same keys. They come from
`KEYS_REPO` (default `suvojeet-sengupta/keys`); keep that repo private. To
clone a private repo, be logged in with `gh` or pass `GH_TOKEN`. If
`~/keys` (or `KEYS_DIR`) already holds keys that aren't the ones in that
repo, `setup.sh` stops instead of building with them.

To update, pull this branch and run both scripts again:

```bash
git -C ~/redwood-setup pull
~/redwood-setup/setup.sh
~/redwood-setup/build.sh
```

# OTA updates

Unofficial redwood builds update through ParanoidHub (Settings > System >
System update) like official ones. `ParanoidHubOverlayRedwood` points it at
`redwood.json` on the [`ota`](../../../tree/ota) branch of this repo, and the
`UnofficialOta` feature patch shows the maintainer on the update screen.

ParanoidHub offers a build when its `build_type` matches the phone's
`ro.aospa.build.variant` (`unofficial`) and its `datetime` is newer than the
running build. A/B installs go through update_engine, so the full signed zip
is all a release needs.

## Releasing a build

1. Build with `~/redwood-setup/build.sh`. It runs `make-feed.sh` at the end,
   which writes `redwood.json` next to the zip. To do it by hand:

   ```bash
   device/xiaomi/redwood/ota/make-feed.sh aospa-calcite-unofficial-redwood-<date>.zip
   ```

   Put the changes in `ota/changelog.txt` before building; it goes into the
   feed as the changelog ParanoidHub shows.
2. Upload the zip as an asset of a `redwood-<date>` release of this repo.
   GitHub takes assets up to 2 GiB; for a bigger zip, host it elsewhere and
   pass its direct download url as the second argument of `make-feed.sh`.
3. Replace `redwood.json` on the `ota` branch with the new one and push.
   Phones see it on their next check, or when you tap "Check for update".

To pull a broken build, push the previous `redwood.json` back. A feed with
an empty `updates` list offers nothing.

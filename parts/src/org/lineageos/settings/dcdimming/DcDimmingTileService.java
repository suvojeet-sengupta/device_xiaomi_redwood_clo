/*
 * SPDX-FileCopyrightText: 2026 Suvojeet Sengupta
 * SPDX-License-Identifier: Apache-2.0
 */

package org.lineageos.settings.dcdimming;

import android.content.ComponentName;
import android.content.Context;
import android.service.quicksettings.Tile;
import android.service.quicksettings.TileService;
import android.util.Log;

public class DcDimmingTileService extends TileService {

    private static final String TAG = "DcDimmingTile";

    @Override
    public void onStartListening() {
        super.onStartListening();
        updateTileUI();
    }

    @Override
    public void onClick() {
        super.onClick();
        if (!DcDimmingUtils.isSupported()) {
            updateTileUI();
            return;
        }

        DcDimmingUtils.setEnabled(this, !DcDimmingUtils.isEnabled(this));
        updateTileUI();
    }

    private void updateTileUI() {
        Tile tile = getQsTile();
        if (tile == null) {
            return;
        }

        if (!DcDimmingUtils.isSupported()) {
            tile.setState(Tile.STATE_UNAVAILABLE);
        } else {
            tile.setState(DcDimmingUtils.isEnabled(this)
                    ? Tile.STATE_ACTIVE : Tile.STATE_INACTIVE);
        }
        tile.updateTile();
    }

    public static void updateTile(Context context) {
        try {
            requestListeningState(context,
                    new ComponentName(context, DcDimmingTileService.class));
        } catch (Exception e) {
            Log.e(TAG, "Failed to refresh tile state", e);
        }
    }
}

/*
 * SPDX-FileCopyrightText: 2026 Suvojeet Sengupta
 * SPDX-License-Identifier: Apache-2.0
 */

package org.lineageos.settings.dcdimming;

import android.content.Context;
import android.content.SharedPreferences;
import android.util.Log;

import androidx.preference.PreferenceManager;

import org.lineageos.settings.utils.FileUtils;

public final class DcDimmingUtils {

    private static final String TAG = "DcDimmingUtils";

    public static final String KEY_DC_DIMMING = "dc_dimming";

    private static final String DC_DIMMING_NODE =
            "/sys/devices/platform/soc/soc:qcom,dsi-display-primary/dimlayer_exposure";

    private DcDimmingUtils() {
    }

    public static boolean isSupported() {
        return FileUtils.isFileReadable(DC_DIMMING_NODE)
                && FileUtils.isFileWritable(DC_DIMMING_NODE);
    }

    public static boolean isEnabled(Context context) {
        return getPreferences(context).getBoolean(KEY_DC_DIMMING, false);
    }

    public static void setEnabled(Context context, boolean enable) {
        getPreferences(context).edit().putBoolean(KEY_DC_DIMMING, enable).apply();
        writeNode(enable);
    }

    public static void restore(Context context) {
        if (isSupported() && isEnabled(context)) {
            writeNode(true);
        }
    }

    private static void writeNode(boolean enable) {
        if (!FileUtils.writeLine(DC_DIMMING_NODE, enable ? "1" : "0")) {
            Log.e(TAG, "Failed to " + (enable ? "enable" : "disable") + " DC dimming");
        }
    }

    private static SharedPreferences getPreferences(Context context) {
        return PreferenceManager.getDefaultSharedPreferences(context);
    }
}

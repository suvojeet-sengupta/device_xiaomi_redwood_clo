/*
 * Copyright (C) 2020 The LineageOS Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package org.lineageos.settings.refreshrate;

import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.UserHandle;
import android.view.Display;

import android.provider.Settings;
import androidx.preference.PreferenceManager;

public final class RefreshUtils {

    private static final String REFRESH_CONTROL = "refresh_control";
    private static final String REFRESH_SERVICE = "refresh_service";

    private static final String KEY_PEAK_REFRESH_RATE = "peak_refresh_rate";
    private static final String KEY_MIN_REFRESH_RATE = "min_refresh_rate";
    private Context mContext;

    protected static final int STATE_DEFAULT = 0;
    protected static final int STATE_MEDIUM = 1;
    protected static final int STATE_HIGH = 2;
    protected static final int STATE_100 = 3;
    protected static final int STATE_110 = 4;
    protected static final int STATE_EXTREME = 5;

    private static final float REFRESH_STATE_DEFAULT = 120f;
    private static final float[] STATE_RATE = { 0f, 60f, 90f, 100f, 110f, 120f };
    private static final int[] STATE_FIELD = { -1, 0, 1, 3, 4, 2 };
    private static final String[] FIELD_KEY = {
            "refresh.medium", "refresh.high=", "refresh.extreme=", "refresh.100=", "refresh.110="
    };

    private static boolean isAppInList = false;
    private static float defaultMaxRate;
    private static float defaultMinRate;

    private SharedPreferences mSharedPrefs;

    protected RefreshUtils(Context context) {
        mSharedPrefs = PreferenceManager.getDefaultSharedPreferences(context);
        mContext = context;
    }

    public static void initialize(Context context) {
        defaultMaxRate = Settings.System.getFloat(context.getContentResolver(), KEY_PEAK_REFRESH_RATE, REFRESH_STATE_DEFAULT);
        defaultMinRate = Settings.System.getFloat(context.getContentResolver(), KEY_MIN_REFRESH_RATE, REFRESH_STATE_DEFAULT);

        if (isServiceEnabled(context))
            startService(context);
        else
            setDefaultRefreshRate(context);
    }

    public static void startService(Context context) {
        context.startServiceAsUser(new Intent(context, RefreshService.class),
                UserHandle.CURRENT);
        PreferenceManager.getDefaultSharedPreferences(context).edit().putString(REFRESH_SERVICE, "true").apply();
    }

    protected static void stopService(Context context) {
        context.stopService(new Intent(context, RefreshService.class));
        PreferenceManager.getDefaultSharedPreferences(context).edit().putString(REFRESH_SERVICE, "false").apply();
    }

    protected static boolean isServiceEnabled(Context context) {
        return true;
    }

    private void writeValue(String profiles) {
        mSharedPrefs.edit().putString(REFRESH_CONTROL, profiles).apply();
    }

    private String[] getModes() {
        String value = mSharedPrefs.getString(REFRESH_CONTROL, null);
        String[] stored = (value == null || value.isEmpty()) ? new String[0] : value.split(":");
        String[] modes = new String[FIELD_KEY.length];
        for (int i = 0; i < modes.length; i++) {
            modes[i] = i < stored.length ? stored[i] : FIELD_KEY[i];
        }
        if (stored.length != modes.length) {
            writeValue(String.join(":", modes));
        }
        return modes;
    }

    protected void writePackage(String packageName, int mode) {
        String[] modes = getModes();
        for (int i = 0; i < modes.length; i++) {
            modes[i] = modes[i].replace(packageName + ",", "");
        }
        if (mode > STATE_DEFAULT && mode < STATE_FIELD.length) {
            modes[STATE_FIELD[mode]] += packageName + ",";
        }
        writeValue(String.join(":", modes));
    }

    protected int getStateForPackage(String packageName) {
        String[] modes = getModes();
        for (int state = STATE_MEDIUM; state < STATE_FIELD.length; state++) {
            if (modes[STATE_FIELD[state]].contains(packageName + ",")) {
                return state;
            }
        }
        return STATE_DEFAULT;
    }

    protected static void setDefaultRefreshRate(Context context) {
        Settings.System.putFloat(context.getContentResolver(), KEY_PEAK_REFRESH_RATE, defaultMaxRate);
        Settings.System.putFloat(context.getContentResolver(), KEY_MIN_REFRESH_RATE, defaultMinRate);
    }

    protected void setRefreshRate(String packageName) {
        if (!isAppInList) {
            defaultMaxRate = Settings.System.getFloat(mContext.getContentResolver(), KEY_PEAK_REFRESH_RATE, REFRESH_STATE_DEFAULT);
            defaultMinRate = Settings.System.getFloat(mContext.getContentResolver(), KEY_MIN_REFRESH_RATE, REFRESH_STATE_DEFAULT);
        }

        float minrate = defaultMinRate;
        float maxrate = defaultMaxRate;

        int state = getStateForPackage(packageName);
        isAppInList = state != STATE_DEFAULT;
        if (isAppInList) {
            maxrate = STATE_RATE[state];
            minrate = Math.min(minrate, maxrate);
        }
        Settings.System.putFloat(mContext.getContentResolver(), KEY_PEAK_REFRESH_RATE, maxrate);
        Settings.System.putFloat(mContext.getContentResolver(), KEY_MIN_REFRESH_RATE, minrate);
    }
}

/*
 * SPDX-FileCopyrightText: 2026 Suvojeet Sengupta
 * SPDX-License-Identifier: Apache-2.0
 */

package org.lineageos.settings.dcdimming;

import android.os.Bundle;
import android.view.MenuItem;

import com.android.settingslib.collapsingtoolbar.CollapsingToolbarBaseActivity;

public class DcDimmingActivity extends CollapsingToolbarBaseActivity {

    private static final String TAG_DC_DIMMING = "dc_dimming";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        getFragmentManager().beginTransaction().replace(
                com.android.settingslib.collapsingtoolbar.R.id.content_frame,
                new DcDimmingSettingsFragment(),
                TAG_DC_DIMMING
        ).commit();
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        if (item.getItemId() == android.R.id.home) {
            onBackPressed();
            return true;
        }
        return super.onOptionsItemSelected(item);
    }
}

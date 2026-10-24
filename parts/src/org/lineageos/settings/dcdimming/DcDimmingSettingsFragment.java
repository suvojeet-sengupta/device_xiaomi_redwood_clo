/*
 * SPDX-FileCopyrightText: 2026 Suvojeet Sengupta
 * SPDX-License-Identifier: Apache-2.0
 */

package org.lineageos.settings.dcdimming;

import android.os.Bundle;

import androidx.preference.Preference;
import androidx.preference.PreferenceFragment;
import androidx.preference.SwitchPreferenceCompat;

import org.lineageos.settings.R;

public class DcDimmingSettingsFragment extends PreferenceFragment
        implements Preference.OnPreferenceChangeListener {

    @Override
    public void onCreatePreferences(Bundle savedInstanceState, String rootKey) {
        setPreferencesFromResource(R.xml.dc_dimming_settings, rootKey);

        SwitchPreferenceCompat dcDimmingPreference =
                findPreference(DcDimmingUtils.KEY_DC_DIMMING);
        if (dcDimmingPreference == null) {
            return;
        }

        boolean supported = DcDimmingUtils.isSupported();
        dcDimmingPreference.setEnabled(supported);
        if (supported) {
            dcDimmingPreference.setOnPreferenceChangeListener(this);
        } else {
            dcDimmingPreference.setChecked(false);
            dcDimmingPreference.setSummary(R.string.dc_dimming_unavailable);
        }
    }

    @Override
    public boolean onPreferenceChange(Preference preference, Object newValue) {
        DcDimmingUtils.setEnabled(getActivity(), (Boolean) newValue);
        DcDimmingTileService.updateTile(getActivity());
        return true;
    }
}

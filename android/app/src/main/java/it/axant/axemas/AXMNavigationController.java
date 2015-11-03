package it.axant.axemas;


import android.app.Fragment;
import android.app.FragmentManager;
import android.app.FragmentTransaction;
import android.util.Log;

import org.json.JSONException;
import org.json.JSONObject;

public class AXMNavigationController {
    final private AXMActivity _activity;
    final private FragmentManager _fragmentManager;

    protected AXMNavigationController(AXMActivity activity) {
        super();
        this._activity = activity;
        this._fragmentManager = this._activity.getFragmentManager();
    }

    public FragmentManager getFragmentManager() { return this._fragmentManager; }

    public void pushFragment(final Fragment fragment, final String tag) {
        if (fragment == null) {
            Log.e("axemas", "Trying to Push NULL controller");
            return;
        }

        _activity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                FragmentManager fragmentManager = getFragmentManager();
                FragmentTransaction transaction = fragmentManager.beginTransaction();
                animateTransaction(transaction);

                JSONObject stackInfo = new JSONObject();
                int selectedTabIdx = _activity.getTabBarController().getSelectedTab();
                if (selectedTabIdx != -1) {
                    try {
                        stackInfo.put("tabIdx", selectedTabIdx);
                    } catch (JSONException e) {
                        Log.e("axemas", "Failed to save current tab index");
                        e.printStackTrace();
                    }
                }

                transaction.replace(R.id.currentSection, fragment, tag);
                transaction.addToBackStack(stackInfo.toString());

                transaction.commit();
            }
        });
    }

    public void popFragments(final int fragmentsToPop) {
        _activity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                FragmentManager fragmentManager = getFragmentManager();

                int fragmentsLeft = fragmentsToPop;
                while (fragmentsLeft > 0) {
                    if (fragmentManager.getBackStackEntryCount() <= 1)
                        break;

                    --fragmentsLeft;
                    fragmentManager.popBackStackImmediate();
                }

                String stackInfoString = fragmentManager.getBackStackEntryAt(fragmentManager.getBackStackEntryCount() - 1).getName();
                try {
                    JSONObject stackInfo = new JSONObject(stackInfoString);
                    _activity.getTabBarController().setSelectedTab(stackInfo.getInt("tabIdx"));
                } catch (JSONException e) {
                    Log.w("axemas", "Ignoring stackInfo: " + String.valueOf(stackInfoString));
                }
            }
        });
    }

    public void popFragmentsAndMaintain(final int maintainedFragmentsArg) {
        _activity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                FragmentManager fragmentManager = getFragmentManager();

                int maintainedFragments = Math.max(maintainedFragmentsArg, 0);
                while (fragmentManager.getBackStackEntryCount() > maintainedFragments) {
                    fragmentManager.popBackStackImmediate();
                }

                int stackTopIdx = fragmentManager.getBackStackEntryCount() - 1;
                if (stackTopIdx > 0) {
                    String stackInfoString = "";
                    try {
                        stackInfoString = fragmentManager.getBackStackEntryAt(stackTopIdx).getName();
                        JSONObject stackInfo = new JSONObject(stackInfoString);
                        _activity.getTabBarController().setSelectedTab(stackInfo.getInt("tabIdx"));
                    } catch (JSONException e) {
                        Log.w("axemas", "Ignoring stackInfo: " + String.valueOf(stackInfoString));
                    }
                }
            }
        });
    }

    private void animateTransaction(FragmentTransaction transaction) {
        transaction.setCustomAnimations(android.R.animator.fade_in, android.R.animator.fade_out,
                android.R.animator.fade_in, android.R.animator.fade_out);
    }
}

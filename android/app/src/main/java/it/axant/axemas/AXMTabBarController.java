package it.axant.axemas;


import android.graphics.Color;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageButton;
import android.widget.LinearLayout;

import org.json.JSONException;
import org.json.JSONObject;

public class AXMTabBarController {
    private JSONObject[] tabs;
    final private AXMActivity _activity;

    protected AXMTabBarController(AXMActivity activity) {
        super();
        this._activity = activity;
    }

    public int getSelectedTab() {
        LinearLayout tabBar = (LinearLayout)_activity.findViewById(R.id.tabs);
        if (tabBar != null) {
            for (int itemPos = 0; itemPos < tabBar.getChildCount(); itemPos++) {
                if (tabBar.getChildAt(itemPos).isSelected()) {
                    return itemPos;
                }
            }
        }

        return -1;
    }

    public void setSelectedTab(int idx) {
        LinearLayout tabBar = (LinearLayout)_activity.findViewById(R.id.tabs);
        if (tabBar != null) {
            for (int itemPos = 0; itemPos < tabBar.getChildCount(); itemPos++) {
                tabBar.getChildAt(itemPos).setSelected(false);
            }

            View tab = tabBar.getChildAt(idx);
            if (tab != null)
                tab.setSelected(true);
        }
    }

    protected void makeTabBar(JSONObject... tabs) {
        this.tabs = tabs;

        final LinearLayout tabbar = (LinearLayout)this._activity.findViewById(R.id.tabs);

        float scale = this._activity.getResources().getDisplayMetrics().density;
        int dpAsPixels = (int) (5 * scale + 0.5f);
        tabbar.setPadding(dpAsPixels, dpAsPixels, dpAsPixels, dpAsPixels);

        int currentTabIndex = -1;
        for (final JSONObject tab : tabs) {
            try {
                tab.put("index", ++currentTabIndex);
            } catch (JSONException e) {
                Log.w("axemas", "Unable to serialize tab index while creating TabBar");
            }

            ImageButton tabIcon = new ImageButton(this._activity);
            try {
                tabIcon.setImageResource(tab.getInt("icon"));
                tabIcon.setBackgroundColor(Color.TRANSPARENT);
                tabIcon.setLayoutParams(new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1.0f));
                tabIcon.setOnClickListener(new View.OnClickListener() {
                    @Override
                    public void onClick(View view) {
                        int tabIndex = tab.optInt("index", -1);
                        if (tabIndex >= 0) {
                            // Detect selecting already selected tab
                            if (getSelectedTab() == tabIndex)
                                return;
                        }

                        for (int itemPos = 0; itemPos < tabbar.getChildCount(); itemPos++) {
                            tabbar.getChildAt(itemPos).setSelected(false);
                        }
                        view.setSelected(true);
                        NavigationSectionsManager.goTo(_activity, tab);
                    }
                });
            } catch (JSONException e) {
                e.printStackTrace();
            }
            tabbar.addView(tabIcon);
        }

        tabbar.getChildAt(0).setSelected(true);
    }


    protected void onSaveInstanceState(Bundle outState) {
        if (this.tabs != null) {
            outState.putInt("selectedTab", getSelectedTab());

            String[] serializedTabs = new String[this.tabs.length];
            for(int i=0; i<this.tabs.length; ++i) {
                JSONObject tab = this.tabs[i];
                serializedTabs[i] = tab.toString();
            }
            outState.putStringArray("tabs", serializedTabs);
        }
    }

    protected void onRestoreInstanceState(Bundle savedInstanceState) {
        String[] serializedTabs = savedInstanceState.getStringArray("tabs");
        if (serializedTabs != null) {
            JSONObject[] tabs = new JSONObject[serializedTabs.length];
            for(int i=0; i<serializedTabs.length; ++i) {
                try {
                    JSONObject tab = new JSONObject(serializedTabs[i]);
                    tabs[i] = tab;
                }
                catch (JSONException e) {
                    // If unable to restore a tab throw away tabs
                    Log.e("axemas", "Unable to restore tabs");
                    return;
                }
            }

            this.makeTabBar(tabs);
            this.setSelectedTab(savedInstanceState.getInt("selectedTab"));
        }
    }
}

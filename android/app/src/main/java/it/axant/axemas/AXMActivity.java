package it.axant.axemas;

import android.app.ActionBar;
import android.app.Activity;
import android.app.AlertDialog;
import android.app.Fragment;
import android.app.FragmentManager;
import android.app.FragmentTransaction;
import android.app.ProgressDialog;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.res.Resources;
import android.graphics.Color;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;
import android.os.Bundle;
import android.os.Handler;
import android.util.Log;
import android.util.TypedValue;
import android.view.ContextThemeWrapper;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import android.widget.ImageButton;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;
import android.widget.TextView;
import android.widget.Toast;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;

import com.splunk.mint.Mint;

import it.axant.axemas.libs.AnimationLayout;


public class AXMActivity extends Activity implements SectionFragment.SectionFragmentActivity, AnimationLayout.Listener {
    private NetworkReceiver networkReceiver = new NetworkReceiver();
    private JSONObject[] tabs;
    private Class defaultController = null;
    private HashMap<String, Class> registeredControllers = null;
    private boolean backButtonEnabled = true;
    private boolean connectivityDialogIsShowing;
    private final IntentFilter connectivityFilter = new IntentFilter(ConnectivityManager.CONNECTIVITY_ACTION);
    private boolean monitoringAvailableConnection = true;
    private boolean connectionStatus = false;

    @Override
    public void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);

        // This was expected to be done automatically by super.onActivityResult
        // but probably due to the fact that we have two fragments it isn't properly forwarded.
        // So we manually forward it to the currentSection fragment.
        Fragment currentSection = getFragmentManager().findFragmentById(R.id.currentSection);
        if (currentSection != null)
            currentSection.onActivityResult(requestCode, resultCode, data);
        else
            Log.w("axemas", "onActivityResult without a fragment in place");
    }
    //-----------------------------------------------------

    // Sidebar -----------
    protected AnimationLayout animationLayout;

    @Override
    public void onSidebarOpened() {
        // do something after opening the sidebar
    }

    @Override
    public void onSidebarClosed() {
        // do something after closing the sidebar
    }

    public View enableFullSizeSidebar(int height) {
        this.getActionBar().hide();

        TypedValue tv = new TypedValue();
        this.getTheme().resolveAttribute(android.R.attr.actionBarSize, tv, true);
        int actionBarHeight = height == -1 ? getResources().getDimensionPixelSize(tv.resourceId) : height;

        RelativeLayout.LayoutParams params = new RelativeLayout.LayoutParams(
                FrameLayout.LayoutParams.WRAP_CONTENT,
                actionBarHeight
        );
        params.addRule(RelativeLayout.ALIGN_PARENT_TOP);
        View customBar = this.getActionBar().getCustomView();
        this.getActionBar().setCustomView(new View(this));

        RelativeLayout axemasLayout = ((RelativeLayout)findViewById(it.axant.axemas.R.id.animation_layout_content));
        axemasLayout.addView(customBar, params);

        View axemasSectionContainer = axemasLayout.findViewById(it.axant.axemas.R.id.currentSection);
        RelativeLayout.LayoutParams contentLayout = (RelativeLayout.LayoutParams)axemasSectionContainer.getLayoutParams();
        contentLayout.setMargins(0, actionBarHeight, 0, 0);
        axemasSectionContainer.setLayoutParams(contentLayout);
      
        return customBar;
    }
  
    public View enableFullSizeSidebar() {
        return this.enableFullSizeSidebar(-1);
    }
      
    @Override
    public boolean onContentTouchedWhenOpening() {
        // sidebar is going to be closed, do something with the data here
        animationLayout.closeSidebar();
        return false;
    }

    protected void toggleSidebar(boolean visible) {
        if (visible)
            animationLayout.openSidebar();
        else
            animationLayout.closeSidebar();
    }
  
    protected void toggleSidebar() {
        animationLayout.toggleSidebar();
    }
    // ------------------------

    // Action Bar -------
    private TextView actionBarTitle = null;
    private ImageButton actionBarButton = null;

    private void _replaceActionBar() {
        ActionBar mActionBar = getActionBar();
        mActionBar.setDisplayShowHomeEnabled(false);
        mActionBar.setDisplayShowTitleEnabled(false);

        View view = LayoutInflater.from(this).inflate(R.layout.axemas_action_bar, null);
        actionBarTitle = (TextView) view.findViewById(R.id.action_bar_title);
        actionBarTitle.setText("");

        actionBarButton = (ImageButton) view.findViewById(R.id.action_bar_button);
        actionBarButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                animationLayout.toggleSidebar();
            }
        });

        mActionBar.setCustomView(view);
        mActionBar.setDisplayShowCustomEnabled(true);
    }

    protected void setSideBarIcon(String resourceName) {
        Log.d("axemas-debug", "Setting ICON " + String.valueOf(resourceName) + " -> " + String.valueOf(actionBarButton));
        if (actionBarButton != null) {
            actionBarButton.setImageResource(getResources().getIdentifier(resourceName, "drawable", getPackageName()));
        }
    }

    protected void startCrashReporter(){
        try {
            String key = getResources()
                    .getString(getResources()
                            .getIdentifier("splunk_api_key", "string", getPackageName()));
            Mint.initAndStartSession(AXMActivity.this, key);
        }
        catch(Resources.NotFoundException e){
            e.printStackTrace();
        }
    }

    protected void setTitle(String title) {
        if (actionBarTitle != null)
            actionBarTitle.setText(title);
    }

    protected void sidebarButtonVisibility(boolean visible) {
        if (actionBarButton == null)
            return;
        actionBarButton.setVisibility(visible ? View.VISIBLE : View.GONE);
    }
    // ----------------------------


    @Override
    protected void onResume() {
        super.onResume();

        isActivityShowing = true;
        if(monitoringAvailableConnection)
            this.registerReceiver(networkReceiver, connectivityFilter);
    }

    @Override
    protected void onPause() {
        super.onPause();

        isActivityShowing = false;
        if(monitoringAvailableConnection)
            this.unregisterReceiver(networkReceiver);
    }
    //--------------------------------------

    // Progress dialog ---------------------
    private ProgressDialog progressDialog = null;

    protected void showProgressDialog() {
        if (progressDialog == null) {
            progressDialog = new ProgressDialog(this, R.style.ProgressDialogTheme);
            progressDialog.setCancelable(false);
            progressDialog.setProgressStyle(android.R.style.Widget_ProgressBar_Small);
        }
        if (!progressDialog.isShowing())
            progressDialog.show();
    }

    protected void hideProgressDialog() {
        if (progressDialog != null)
            progressDialog.cancel();
    }

    @Override
    protected void onStop() {
        //prevent memory leaks when closing with dialog opened
        hideProgressDialog();
        if (alertDialog != null)
            alertDialog.cancel();
        super.onStop();
    }
    //----------------------------------------

    // Alert dialog --------------------------
    private boolean isActivityShowing = false;
    private AlertDialog alertDialog = null;

    private void makeAndShowAlertDialog(AlertDialog.Builder builder) {
        if (isActivityShowing) {
            alertDialog = builder.create();
            alertDialog.show();
        }
    }

    protected void showDismissibleAlertDialog(String title, String message) {
        AlertDialog.Builder alertDialogBuilder = new AlertDialog.Builder(new ContextThemeWrapper(
                this, R.style.CustomAlertDialogStyle));
        alertDialogBuilder.setTitle(title);
        alertDialogBuilder
                .setMessage(message)
                .setCancelable(false)
                .setNegativeButton(getString(R.string.dialog_close_button), new DialogInterface.OnClickListener() {
                    public void onClick(DialogInterface dialog, int id) {
                        dialog.cancel();
                        hideProgressDialog(); // hide it when displaying an alert!
                    }
                });
        makeAndShowAlertDialog(alertDialogBuilder);
    }

    protected void showCustomAlertDialog(AlertDialog.Builder builder) {
        makeAndShowAlertDialog(builder);
    }
    //----------------------------------------

    // Fragment Stack ------------------------
    private void animateTransaction(FragmentTransaction transaction) {
        transaction.setCustomAnimations(android.R.animator.fade_in, android.R.animator.fade_out,
                android.R.animator.fade_in, android.R.animator.fade_out);
    }

    private void pushFragment(final Fragment fragment, final String tag) {
        if (fragment == null) {
            Log.e("axemas", "Trying to Push NULL controller");
            return;
        }

        this.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                FragmentManager fragmentManager = getFragmentManager();
                FragmentTransaction transaction = fragmentManager.beginTransaction();
                animateTransaction(transaction);

                JSONObject stackInfo = new JSONObject();
                int selectedTabIdx = getSelectedTab();
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

    private void popFragments(final int fragmentsToPop) {
        this.runOnUiThread(new Runnable() {
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
                    setSelectedTab(stackInfo.getInt("tabIdx"));
                } catch (JSONException e) {
                    Log.w("axemas", "Ignoring stackInfo: " + String.valueOf(stackInfoString));
                }
            }
        });
    }

    private void popFragmentsAndMaintain(final int maintainedFragmentsArg) {
        this.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                FragmentManager fragmentManager = getFragmentManager();

                int maintainedFragments = Math.max(maintainedFragmentsArg, 1);
                while (fragmentManager.getBackStackEntryCount() > maintainedFragments) {
                    fragmentManager.popBackStackImmediate();
                }

                int stackTopIdx = fragmentManager.getBackStackEntryCount() - 1;
                String stackInfoString = "";
                try {
                    stackInfoString = fragmentManager.getBackStackEntryAt(stackTopIdx).getName();
                    JSONObject stackInfo = new JSONObject(stackInfoString);
                    setSelectedTab(stackInfo.getInt("tabIdx"));
                } catch (JSONException e) {
                    Log.w("axemas", "Ignoring stackInfo: " + String.valueOf(stackInfoString));
                }
            }
        });
    }
    //----------------------------------------

    protected void enableBackButton(boolean toggle) {
        backButtonEnabled = toggle;
    }

    private boolean doubleBackToExitPressedOnce = false;

    public int getSelectedTab() {
        LinearLayout tabBar = (LinearLayout) findViewById(R.id.tabs);
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
        LinearLayout tabBar = (LinearLayout) findViewById(R.id.tabs);
        if (tabBar != null) {
            for (int itemPos = 0; itemPos < tabBar.getChildCount(); itemPos++) {
                tabBar.getChildAt(itemPos).setSelected(false);
            }

            View tab = tabBar.getChildAt(idx);
            if (tab != null)
                tab.setSelected(true);
        }
    }

    @Override
    public void onBackPressed() {
        if (backButtonEnabled) {
            if (animationLayout.isOpening()) {
                animationLayout.closeSidebar();
            } else {
                if (getFragmentManager().getBackStackEntryCount() > 1) {
                    this.popFragments(1);
                } else {
                    if (doubleBackToExitPressedOnce) {
                        this.finish();
                    }
                    this.doubleBackToExitPressedOnce = true;
                    Toast.makeText(this, getString(R.string.press_again_to_exit), Toast.LENGTH_SHORT).show();
                    new Handler().postDelayed(new Runnable() {
                        @Override
                        public void run() {
                            doubleBackToExitPressedOnce = false;
                        }
                    }, 2000);
                }
            }
        }
    }

    @Override
    protected void onSaveInstanceState(Bundle outState) {
        super.onSaveInstanceState(outState);

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

    @Override
    protected void onRestoreInstanceState(Bundle savedInstanceState) {
        Log.d("axemas", "Performing onRestoreInstanceState()");

        super.onRestoreInstanceState(savedInstanceState);

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

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        setContentView(R.layout.activity_with_sidebar_axm);
        _replaceActionBar();

        this.registeredControllers = new HashMap<String, Class>();
        animationLayout = (AnimationLayout) findViewById(R.id.animation_layout);   // this is retained just check it
        animationLayout.setListener(this);

        if(monitoringAvailableConnection)
            networkReceiver = new NetworkReceiver();
    }

    public void activityLoadContent(JSONObject dataObject) {
        loadContent(dataObject);
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
    }

    private void setupWithActions(JSONObject jsonData) throws JSONException {
        if (!jsonData.isNull("title"))
            setTitle(jsonData.getString("title"));
        else
            setTitle("");

        if (!jsonData.isNull("stackMaintainedElements")) {
            popMaintainingOnly(jsonData.getInt("stackMaintainedElements"));
        }
        if (!jsonData.isNull("stackPopElements")) {
            popOnly(jsonData.getInt("stackPopElements"));
        }
    }

    private void makeSideBar(String sidebarUrl) {
        SectionFragment sidebarFragment = SectionFragment.newInstance(sidebarUrl);
        FragmentTransaction sidebarTransaction = getFragmentManager().beginTransaction();
        sidebarTransaction.replace(R.id.sidebarSection, sidebarFragment, "sidebar_fragment");
        sidebarTransaction.commit();
    }

    private void makeTabBar(JSONObject... tabs) {
        this.tabs = tabs;

        final LinearLayout tabbar = (LinearLayout)findViewById(R.id.tabs);

        float scale = getResources().getDisplayMetrics().density;
        int dpAsPixels = (int) (5 * scale + 0.5f);
        tabbar.setPadding(dpAsPixels, dpAsPixels, dpAsPixels, dpAsPixels);

        int currentTabIndex = -1;
        for (final JSONObject tab : tabs) {
            try {
                tab.put("index", ++currentTabIndex);
            } catch (JSONException e) {
                Log.w("axemas", "Unable to serialize tab index while creating TabBar");
            }

            ImageButton tabIcon = new ImageButton(this);
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
                        NavigationSectionsManager.goTo(AXMActivity.this, tab);
                    }
                });
            } catch (JSONException e) {
                e.printStackTrace();
            }
            tabbar.addView(tabIcon);
        }

        tabbar.getChildAt(0).setSelected(true);
    }

    protected void makeApplicationRootController(JSONObject dataObject, JSONObject... tabs) {
        ArrayList<JSONObject> l = new ArrayList<JSONObject>();
        l.add(dataObject);
        l.addAll(Arrays.asList(tabs));
        JSONObject[] tabsArray = new JSONObject[l.size()];
        tabsArray = l.toArray(tabsArray);
        this.makeTabBar(tabsArray);
        makeApplicationRootController(dataObject);
    }

    protected void makeApplicationRootController(JSONObject dataObject, String sidebarUrl, JSONObject... tabs) {
        makeApplicationRootController(dataObject, tabs);
        makeSideBar(sidebarUrl);
    }

    protected void makeApplicationRootController(JSONObject dataObject, String sidebarUrl) {
        makeApplicationRootController(dataObject);
        makeSideBar(sidebarUrl);
    }

    protected void makeApplicationRootController(JSONObject dataObject) {
        loadContent(dataObject);
    }

    protected void loadContent(JSONObject dataObject) {
        SectionFragment sectionFragment = null;
        try {
            setupWithActions(dataObject);
            sectionFragment = SectionFragment.newInstance(dataObject);
            pushFragment(sectionFragment, "web_fragment");
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }

    protected void loadContent(Fragment fragment) {
        pushFragment(fragment, "native_fragment");
    }

    protected void makeApplicationRootController(Fragment fragment, String sidebarUrl) {
        pushFragment(fragment, "native_fragment");
        makeSideBar(sidebarUrl);
    }

    private void popOnly(int fragmentsToPop) {
        setTitle("");
        popFragments(fragmentsToPop);
    }

    private void popMaintainingOnly(int maintainedFragments) {
        setTitle("");
        popFragmentsAndMaintain(maintainedFragments);
    }

    protected void registerController(Class controllerClass, String route) {
        registeredControllers.put(route, controllerClass);
    }

    protected void registerDefaultController(Class controllerClass) {
        this.defaultController = controllerClass;
    }

    protected Class getDefaultRouteController() {
        return this.defaultController;
    }

    public Class getControllerForRoute(String route) {
        if (registeredControllers.containsKey(route))
            return registeredControllers.get(route);
        else
            return getDefaultRouteController();
    }

    public void setMonitoringAvailableConnection(Boolean value) {
        monitoringAvailableConnection = value;
    }

    public boolean isNetworkAvailable() {
        return this.connectionStatus;
    }

    public static boolean isNetworkAvailable(Context context) {
        ConnectivityManager connMgr =
                (ConnectivityManager) context.getSystemService(Context.CONNECTIVITY_SERVICE);
        NetworkInfo networkInfo = connMgr.getActiveNetworkInfo();
        return networkInfo != null && networkInfo.isConnected() && networkInfo.isAvailable();
    }


    private class NetworkReceiver extends BroadcastReceiver {
        private AlertDialog dialog = null;
        public void showConnectivityDialog(Context context) {
            if (dialog == null)
                dialog = new AlertDialog.Builder(context)
                        .setTitle(context.getString(R.string.dialog_no_connection_title))
                        .setMessage(context.getString(R.string.dialog_no_connection_text))
                        .setCancelable(false)
                        .create();
            dialog.show();
        }

        public void hideConnectivityDialog(Context context) {
            if (dialog != null) {
                NavigationSectionsManager.hideProgressDialog(context);
                dialog.hide();
                dialog = null;
            }
        }

        @Override
        public void onReceive(Context context, Intent intent) {
            ConnectivityManager connMgr =
                    (ConnectivityManager) context.getSystemService(Context.CONNECTIVITY_SERVICE);
            NetworkInfo networkInfo = connMgr.getActiveNetworkInfo();
            connectionStatus = networkInfo != null && networkInfo.isConnected() && networkInfo.isAvailable();
            if (connectionStatus) {
                //Connection is available, check if popUp is visible and dismiss
                if (connectivityDialogIsShowing) {
                    hideConnectivityDialog(context);
                    connectivityDialogIsShowing = false;
                }
            } else {
                //Connection not available, check if show popUP
                if (!connectivityDialogIsShowing) {
                    showConnectivityDialog(context);
                    connectivityDialogIsShowing = true;
                }
            }
        }
    }

}

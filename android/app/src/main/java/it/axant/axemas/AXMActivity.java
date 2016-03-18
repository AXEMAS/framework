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

import it.axant.axemas.libs.AnimationLayout;


public class AXMActivity extends Activity implements SectionFragment.SectionFragmentActivity {
    private NetworkReceiver networkReceiver = new NetworkReceiver();
    private Class defaultController = null;
    private HashMap<String, Class> registeredControllers = null;
    private boolean backButtonEnabled = true;
    private boolean connectivityDialogIsShowing;
    private final IntentFilter connectivityFilter = new IntentFilter(ConnectivityManager.CONNECTIVITY_ACTION);
    private boolean monitoringAvailableConnection = true;
    private boolean connectionStatus = false;
    private AXMNavigationController _navigationController = null;
    private AXMTabBarController _tabBarController = null;
    private AXMSidebarController _sidebarController = null;
    private boolean doubleBackToExitPressedOnce = false;

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


    // ------------------------

    // Action Bar -------
    private TextView actionBarTitle = null;
    private ImageButton actionBarBackButton = null;
    private ImageButton actionBarButtonRight = null;

    private View _replaceActionBar() {
        ActionBar mActionBar = getActionBar();
        mActionBar.setDisplayShowHomeEnabled(false);
        mActionBar.setDisplayShowTitleEnabled(false);

        View view = LayoutInflater.from(this).inflate(R.layout.axemas_action_bar, null);
        actionBarTitle = (TextView) view.findViewById(R.id.action_bar_title);
        actionBarTitle.setText("");

        actionBarBackButton = (ImageButton) view.findViewById(R.id.action_bar_back_button);
        actionBarBackButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                _navigationController.popFragments(1);
            }
        });

        actionBarButtonRight = (ImageButton) view.findViewById(R.id.action_bar_right_button);
        actionBarButtonRight.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                SectionFragment currentSectionFragment = NavigationSectionsManager.getActiveFragment(AXMActivity.this);
                currentSectionFragment.getRegisteredSectionController().actionbarRightButtonAction();
            }
        });

        mActionBar.setCustomView(view);
        mActionBar.setDisplayShowCustomEnabled(true);
        return view;
    }

    protected void setBackBarIcon(String resourceName) {
        Log.d("axemas-debug", "Setting actionBarButton ICON " + String.valueOf(resourceName) + " -> " + String.valueOf(actionBarBackButton));
        if (actionBarBackButton != null) {
            actionBarBackButton.setImageResource(getResources().getIdentifier(resourceName, "drawable", getPackageName()));
        }
    }

    protected void setRightBarIcon(String resourceName) {
        Log.d("axemas-debug", "Setting actionBarButtonRight ICON " + String.valueOf(resourceName) + " -> " + String.valueOf(actionBarButtonRight));
        if (actionBarButtonRight != null) {
            actionBarButtonRight.setImageResource(getResources().getIdentifier(resourceName, "drawable", getPackageName()));
        }
    }

    public void onSidebarOpened() {
        // do something after opening the sidebar
    }

    public void onSidebarClosed() {
        // do something after closing the sidebar
    }

    public boolean onContentTouchedWhenOpening() {
        // sidebar is going to be closed, do something with the data here
        return false;
    }

    protected void setTitle(String title) {
        if (actionBarTitle != null)
            actionBarTitle.setText(title);
    }

    protected void actionBarButtonBackVisibility(boolean visible) {
        if (actionBarBackButton == null)
            return;
        actionBarBackButton.setVisibility(visible ? View.VISIBLE : View.GONE);
    }

    protected void actionBarButtonRightVisibility(boolean visible) {
        if (actionBarButtonRight == null)
            return;
        actionBarButtonRight.setVisibility(visible ? View.VISIBLE : View.GONE);
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

    protected AXMNavigationController getNavigationController() {
        return _navigationController;
    }

    protected AXMTabBarController getTabBarController() {
        return _tabBarController;
    }

    protected  AXMSidebarController getSidebarController() {
        return _sidebarController;
    }

    protected void enableBackButton(boolean toggle) {
        backButtonEnabled = toggle;
    }

    @Override
    public void onBackPressed() {
        if (backButtonEnabled) {
            if (_sidebarController.isOpening()) {
                _sidebarController.toggleSidebar(false);
            } else {
                if (getFragmentManager().getBackStackEntryCount() > 1) {
                    _navigationController.popFragments(1);
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
        this._tabBarController.onSaveInstanceState(outState);
    }

    @Override
    protected void onRestoreInstanceState(Bundle savedInstanceState) {
        Log.d("axemas", "Performing onRestoreInstanceState()");

        super.onRestoreInstanceState(savedInstanceState);
        this._tabBarController.onRestoreInstanceState(savedInstanceState);
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        this._navigationController = new AXMNavigationController(this);
        this._tabBarController = new AXMTabBarController(this);

        setContentView(R.layout.activity_with_sidebar_axm);
        View actionBarView = _replaceActionBar();

        this._sidebarController = new AXMSidebarController(this,
                actionBarView.findViewById(R.id.action_bar_button));

        this.registeredControllers = new HashMap<String, Class>();

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
            this.setTitle("");
            _navigationController.popFragmentsAndMaintain(jsonData.getInt("stackMaintainedElements"));
        }
        if (!jsonData.isNull("stackPopElements")) {
            this.setTitle("");
            _navigationController.popFragments(jsonData.getInt("stackPopElements"));
        }
    }

    protected void makeApplicationRootController(JSONObject dataObject, JSONObject... tabs) {
        ArrayList<JSONObject> l = new ArrayList<JSONObject>();
        l.add(dataObject);
        l.addAll(Arrays.asList(tabs));
        JSONObject[] tabsArray = new JSONObject[l.size()];
        tabsArray = l.toArray(tabsArray);
        this._tabBarController.makeTabBar(tabsArray);
        makeApplicationRootController(dataObject);
    }

    protected void makeApplicationRootController(JSONObject dataObject, String sidebarUrl, JSONObject... tabs) {
        makeApplicationRootController(dataObject, tabs);
        _sidebarController.makeSideBar(sidebarUrl);
    }

    protected void makeApplicationRootController(JSONObject dataObject, String sidebarUrl) {
        makeApplicationRootController(dataObject);
        _sidebarController.makeSideBar(sidebarUrl);
    }

    protected void makeApplicationRootController(JSONObject dataObject) {
        loadContent(dataObject);
    }

    protected void loadContent(JSONObject dataObject) {
        SectionFragment sectionFragment = null;
        try {
            setupWithActions(dataObject);
            sectionFragment = SectionFragment.newInstance(dataObject);
            _navigationController.pushFragment(sectionFragment, "web_fragment");
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }

    protected void loadContent(Fragment fragment) {
        _navigationController.pushFragment(fragment, "native_fragment");
    }

    protected void loadContent(int fragmentsToPop) {
        _navigationController.popFragments(fragmentsToPop);
    }

    protected void makeApplicationRootController(Fragment fragment, String sidebarUrl) {
        _navigationController.pushFragment(fragment, "native_fragment");
        _sidebarController.makeSideBar(sidebarUrl);
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

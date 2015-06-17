package it.axant.axemas;


import android.app.AlertDialog;
import android.app.Fragment;
import android.content.Context;
import android.content.SharedPreferences;

import org.json.JSONObject;

public class NavigationSectionsManager {

    private final static String PREFERENCES = "AXEMAS";

    public static void registerController(Context context, Class controllerClass, String route) {
        ((AXMActivity) context).registerController(controllerClass, route);
    }

    public static void registerDefaultController(Context context, Class controllerClass) {
        ((AXMActivity) context).registerDefaultController(controllerClass);
    }

    public static void makeApplicationRootController(Context context, JSONObject data, String sidebarUrl) {
        ((AXMActivity) context).makeApplicationRootController(data, sidebarUrl);
    }

    public static void setSideBarIcon(Context context, String resourceName) {
        ((AXMActivity) context).setSideBarIcon(resourceName);
    }

    public static void makeApplicationRootController(Context context, Fragment fragment, String sidebarUrl) {
        ((AXMActivity) context).makeApplicationRootController(fragment, sidebarUrl);
    }

    public static void makeApplicationRootController(Context context, JSONObject data) {
        ((AXMActivity) context).makeApplicationRootController(data);
    }

    public static void makeApplicationRootController(Context context, JSONObject data, JSONObject... tabs) {
        ((AXMActivity) context).makeApplicationRootController(data, tabs);
    }

    public static void makeApplicationRootController(Context context, JSONObject data, String sidebarUrl, JSONObject... tabs) {
        ((AXMActivity) context).makeApplicationRootController(data, sidebarUrl, tabs);
    }

    public static void goTo(Context context, JSONObject data) {
        ((AXMActivity) context).loadContent(data);
    }

    public static void pushFragment(Context context, Fragment fragment) {
        ((AXMActivity) context).loadContent(fragment);
    }

    public static SectionFragment activeFragment(Context context) {
        return (SectionFragment)((AXMActivity) context).getFragmentManager().findFragmentByTag("web_fragment");
    }

    public static void sidebarButtonVisibility(Context context, boolean visible) {
        ((AXMActivity) context).sidebarButtonVisibility(visible);
    }

    public static void toggleSidebar(Context context, boolean visible) {
        ((AXMActivity) context).toggleSidebar(visible);
    }

    public static void showProgressDialog(Context context) {
        ((AXMActivity) context).showProgressDialog();
    }

    public static void hideProgressDialog(Context context) {
        ((AXMActivity) context).hideProgressDialog();
    }

    public static void showDismissibleAlertDialog(Context context, String title, String message) {
        ((AXMActivity) context).showDismissibleAlertDialog(title, message);
    }

    public static void showDismissibleAlertDialog(Context context, AlertDialog.Builder builder) {
        ((AXMActivity) context).showCustomAlertDialog(builder);
    }

    public static void enableBackButton(Context context, boolean toggle) {
        ((AXMActivity) context).enableBackButton(toggle);
    }

    public static void sidebarAnimationConfiguration(Context context, float alpha, int duration, String hexColor) {
        ((AXMActivity) context).animationLayout.setAnimationDetails(alpha, duration, hexColor);
    }

    public static void store(Context context, String key, String value){
        SharedPreferences sharedPreferences =
                context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE);
        SharedPreferences.Editor editor = sharedPreferences.edit();
        editor.putString(key, value);
        editor.commit();
    }

    public static String  getValueForKey(Context context, String key){
        SharedPreferences sharedPreferences =
                context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE);
        return sharedPreferences.getString(key, null);
    }

    public static void removeValue(Context context, String key){
        SharedPreferences sharedPreferences =
                context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE);
        SharedPreferences.Editor editor = sharedPreferences.edit();
        editor.remove(key);
        editor.commit();
    }

}

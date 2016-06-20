package it.axant.axemas;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.app.AlertDialog;
import android.app.Fragment;
import android.app.FragmentManager;
import android.content.DialogInterface;
import android.content.Intent;
import android.graphics.Bitmap;
import android.os.Build;
import android.os.Bundle;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.webkit.ConsoleMessage;
import android.webkit.WebChromeClient;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.FrameLayout;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.lang.Override;
import java.lang.reflect.Constructor;
import java.lang.reflect.InvocationTargetException;

import it.axant.axemas.libs.SharedStorage;


@SuppressLint("ValidFragment")
public class SectionFragment extends Fragment {
    public static final String FRAGMENT_TITLE = "fragmnet_title";
    private static final String URL_PARAM = "url";
    private static final String URL_EXTRA_PARAMETERS = "url_extra_parameters";
    private String fullUrl;
    private String url;
    private JavascriptBridge jsbridge = null;
    private AXMSectionController controller = null;
    private ViewGroup _rootView;
    private WebView webView;
    private Bundle _unRestoredStateBundle;
    private SectionFragmentActivity mListener;

    // retain values
    private String fragmentTitle = null;
    private String toggleSidebarIcon = null;
    private String actionbarRightIcon = null;

    private boolean webViewLoading = false;

    public static SectionFragment newInstance(JSONObject options) {
        String url = options.optString("url");
        String toggleSidebarIcon = options.optString("toggleSidebarIcon", null);
        String actionbarRightIcon = options.optString("actionbarRightIcon", null);

        SectionFragment fragment = new SectionFragment();

        //decouple url and parameters
        Bundle args = new Bundle();
        if (url.indexOf("?") != -1) {
            args.putString(URL_PARAM, url.substring(0, url.indexOf("?")));
            args.putString(URL_EXTRA_PARAMETERS, url.substring(url.indexOf("?"), url.length()));
        } else {
            args.putString(URL_PARAM, url);
            args.putString(URL_EXTRA_PARAMETERS, "");
        }

        args.putString("toggleSidebarIcon", toggleSidebarIcon);
        args.putString("actionbarRightIcon", actionbarRightIcon);

        fragment.setArguments(args);
        return fragment;
    }

    public static SectionFragment newInstance(String url) {
        JSONObject options = new JSONObject();
        try {
            options.put("url", url);
        } catch (JSONException e) {
            throw new RuntimeException("Invalid options to newInstance");
        }
        return newInstance(options);
    }

    @Deprecated
    public static SectionFragment newInstance(String url, String toggleSidebarIcon) {
        JSONObject options = new JSONObject();
        try {
            options.put("url", url);
            options.put("toggleSidebarIcon", toggleSidebarIcon);
        } catch (JSONException e) {
            throw new RuntimeException("Invalid options to newInstance");
        }
        return newInstance(options);
    }


    public SectionFragment() { }

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        Log.d("axemas-debug", "Creating Fragment " + String.valueOf(savedInstanceState));
        _unRestoredStateBundle = savedInstanceState;

        setRetainInstance(true);
        if (getArguments() != null) {
            Bundle arguments = getArguments();
            Log.d("axemas-debug", "Creating with Arguments... " + String.valueOf(arguments));

            url = arguments.getString(URL_PARAM);
            toggleSidebarIcon = arguments.getString("toggleSidebarIcon");
            actionbarRightIcon = arguments.getString("actionbarRightIcon");
            String extra_params = arguments.getString(URL_EXTRA_PARAMETERS);

            if (!url.contains("://"))
                fullUrl = "file:///android_asset/" + url + extra_params;
            else
                fullUrl = url + extra_params;
        }
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        _unRestoredStateBundle = null;

        FrameLayout V = new FrameLayout(getActivity());

        if (_rootView != null) {
            Log.d("axemas-debug", "Recovering rootView");
            ViewGroup parent = (ViewGroup)_rootView.getParent();
            if (parent != null)
                parent.removeView(_rootView);
            V.addView(_rootView);
            return V;
        }

        _rootView = new FrameLayout(getActivity());
        V.addView(_rootView);

        webView = new AXMWebView(getActivity());
        _rootView.addView(webView);

        this.jsbridge = new JavascriptBridge(webView);

        AXMActivity activity = (AXMActivity) this.getActivity();
        try {
            Class controllerClass = activity.getControllerForRoute(url);
            if (controllerClass != null) {
                Constructor c = controllerClass.getConstructor(SectionFragment.class);
                this.controller = (AXMSectionController) c.newInstance(this);
            }
        } catch (NoSuchMethodException e) {
            e.printStackTrace();
        } catch (InvocationTargetException e) {
            e.printStackTrace();
        } catch (java.lang.InstantiationException e) {
            e.printStackTrace();
        } catch (IllegalAccessException e) {
            e.printStackTrace();
        }

        this.webViewLoading = false;

        Log.d("axemas", "Controller " + this.controller + " for " + url);
        webView.setWebChromeClient(new SectionChromeClient());
        webView.setWebViewClient(new SectionWebClient(this.jsbridge, this.controller));
        webView.getSettings().setCacheMode(WebSettings.LOAD_NO_CACHE);
        webView.getSettings().setJavaScriptEnabled(true);
        webView.getSettings().setDomStorageEnabled(true);
        webView.getSettings().setDatabaseEnabled(true);
        webView.getSettings().setDatabasePath("/data/data/" + getActivity().getPackageName() + "/databases/");
        if (android.os.Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
            Log.d("axemas", "Enabling Hardware Accelerated WebView");
            webView.setLayerType(View.LAYER_TYPE_HARDWARE, null);
        } else {
            Log.d("axemas", "Fallback to Software WebView");
            webView.setLayerType(View.LAYER_TYPE_SOFTWARE, null);
        }


        webView.addJavascriptInterface(this.jsbridge, "AndroidNativeJS");

        this.jsbridge.registerHandler("showProgressHUD", new JavascriptBridge.Handler() {
            @Override
            public void call(Object data, JavascriptBridge.Callback callback) {
                Log.d("axemas", "showing progress HUD");
                if (getActivity() != null)
                    ((AXMActivity) getActivity()).showProgressDialog();
                callback.call();
            }
        });

        this.jsbridge.registerHandler("hideProgressHUD", new JavascriptBridge.Handler() {
            @Override
            public void call(Object data, JavascriptBridge.Callback callback) {
                Log.d("axemas", "hiding progress HUD");
                if (getActivity() != null)
                    ((AXMActivity) getActivity()).hideProgressDialog();
                callback.call();
            }
        });

        this.jsbridge.registerHandler("goto", new JavascriptBridge.Handler() {
            @Override
            public void call(Object data, JavascriptBridge.Callback callback) {
                JSONObject jsonData = (JSONObject) data;
                Log.d("axemas", jsonData.toString());
                if (mListener != null)
                    mListener.activityLoadContent(jsonData);
                callback.call();
            }
        });

        this.jsbridge.registerHandler("gotoFromSidebar", new JavascriptBridge.Handler() {
            @Override
            public void call(Object data, JavascriptBridge.Callback callback) {
                JSONObject jsonData = (JSONObject) data;
                Log.d("axemas", jsonData.toString());
                if (mListener != null)
                    mListener.activityLoadContent(jsonData);
                if (getActivity() != null)
                    ((AXMActivity) getActivity()).getSidebarController().toggleSidebar(false);
                callback.call();
            }
        });

        this.jsbridge.registerHandler("platformDetails", new JavascriptBridge.Handler() {
            @Override
            public void call(Object data, JavascriptBridge.Callback callback) {
                JSONObject obj = new JSONObject();
                try {
                    obj.put("model", android.os.Build.MODEL);
                    obj.put("systemName", "Android");
                    obj.put("systemVersion", Build.VERSION.RELEASE);
                } catch (JSONException e) {
                    e.printStackTrace();
                }
                callback.call(obj);
            }
        });


        this.jsbridge.registerHandler("storeData", new JavascriptBridge.Handler() {
            @Override
            public void call(Object data, JavascriptBridge.Callback callback) {
                JSONObject jsonData = (JSONObject) data;
                Log.d("axemas", "storeData: "+jsonData.toString());
                try {
                    SharedStorage.store((AXMActivity) getActivity(), jsonData.getString("key"),
																	 jsonData.getString("value"));
                } catch (JSONException e) {
                    e.printStackTrace();
                }
            }
        });

        this.jsbridge.registerHandler("fetchData", new JavascriptBridge.Handler() {
            @Override
            public void call(Object data, JavascriptBridge.Callback callback) {
				JSONObject jsonData = (JSONObject) data;
                String key = "";
                try {
                    key = jsonData.getString("key");
                } catch (JSONException e) {
                    e.printStackTrace();
                }
                JSONObject obj = new JSONObject();
                Log.d("axemas", "fetchData: " + key);
                AXMActivity mainAxmActivity = (AXMActivity) getActivity();
                if(mainAxmActivity != null) {
                    try {
                        obj.put(key, SharedStorage.getValueForKey(mainAxmActivity, key));
                    } catch (JSONException e) {
                        e.printStackTrace();
                    }
                }
                callback.call(obj);
            }
        });

        this.jsbridge.registerHandler("removeData", new JavascriptBridge.Handler() {
            @Override
            public void call(Object data, JavascriptBridge.Callback callback) {
				JSONObject jsonData = (JSONObject) data;
                String key = "";
                try {
                    key = jsonData.getString("key");
                } catch (JSONException e) {
                    e.printStackTrace();
                }
                Log.d("axemas", "removeData: " + key);
                SharedStorage.removeValue((AXMActivity) getActivity(), key);
            }
        });

        this.jsbridge.registerHandler("log", new JavascriptBridge.Handler() {
            @Override
            public void call(Object data, JavascriptBridge.Callback callback) {
                JSONObject jsonData = (JSONObject) data;
                try {
                    Log.d(jsonData.getString("tag"), jsonData.getString("message"));
                } catch (JSONException e) {
                    e.printStackTrace();
                }
            }
        });

        this.jsbridge.registerHandler("dialog", new JavascriptBridge.Handler() {
            void addDialogButton(AlertDialog.Builder builder, JSONArray buttons,
                                 final int buttonIdx,
                                 final JavascriptBridge.Callback callback) {
                if (buttons == null)
                    return;

                DialogInterface.OnClickListener listener = new DialogInterface.OnClickListener() {
                    @Override
                    public void onClick(DialogInterface dialogInterface, int i) {
                        JSONObject data = new JSONObject();
                        try {
                            data.put("button", buttonIdx);
                            dialogInterface.dismiss();
                            if (getActivity() != null && getActivity() instanceof AXMActivity)
                                ((AXMActivity) getActivity()).hideProgressDialog();
                        } catch (Exception e) {
                            Log.d("axemas", "Failed to create dialog button response");
                            e.printStackTrace();
                        }
                        callback.call(data);
                    }
                };

                String buttonName = buttons.optString(buttonIdx, "");
                if ((buttonName != null) && (!buttonName.equals(""))) {
                    if (buttonIdx == 0 && buttons.length() >= 1)
                        builder.setNegativeButton(buttonName, listener);
                    else if (buttonIdx == 1 && buttons.length() > 2)
                        builder.setNeutralButton(buttonName, listener);
                    else if (buttonIdx == 1 && buttons.length() == 2)
                        builder.setPositiveButton(buttonName, listener);
                    else if (buttonIdx == 2 && buttons.length() > 2)
                        builder.setPositiveButton(buttonName, listener);

                }
            }

            @Override
            public void call(Object data, final JavascriptBridge.Callback callback) {
                JSONObject args = (JSONObject) data;
                String title = args.optString("title", "");
                String message = args.optString("message", "");
                JSONArray buttons = args.optJSONArray("buttons");

                if (mListener != null) { //activity may not be showing
                    AlertDialog.Builder builder = new AlertDialog.Builder((Activity) mListener);
                    builder.setTitle(title);
                    builder.setMessage(message);

                    addDialogButton(builder, buttons, 0, callback);
                    addDialogButton(builder, buttons, 1, callback);
                    addDialogButton(builder, buttons, 2, callback);

                    builder.show();
                }
            }
        });


        if (this.controller != null) {
            this.controller.sectionFragmentOnCreateView(inflater, container, savedInstanceState);
            this.controller.sectionOnViewCreate(_rootView);
        }

        Log.d("axemas-debug", "Fragment " + String.valueOf(this) + " with state: " + String.valueOf(savedInstanceState));
        if (savedInstanceState != null) {
            fragmentTitle = savedInstanceState.getString(FRAGMENT_TITLE);
            webViewLoading = savedInstanceState.getBoolean("webViewLoading");
            toggleSidebarIcon = savedInstanceState.getString("toggleSidebarIcon");
            actionbarRightIcon = savedInstanceState.getString("actionbarRightIcon");
            webView.restoreState(savedInstanceState);
        }

        return V;
    }

    public WebView getWebView() {
        return this.webView;
    }

    public AXMSectionController getRegisteredSectionController() { return this.controller; }

    @Override
    public void onActivityResult(int requestCode, int resultCode, Intent data) {
        Log.d("axemas",
              "Fragment onActivityResult -> " +
              " requestCode: " + String.valueOf(requestCode) +
              " resultCode: " + String.valueOf(resultCode)
        );
        super.onActivityResult(requestCode, resultCode, data);
        this.controller.sectionFragmentOnActivityResult(requestCode, resultCode, data);
    }

    @Override
    public void onAttach(Activity activity) {
        super.onAttach(activity);

        Log.d("axemas-debug", String.format("Attaching Fragment %s...", this));

        try {
            mListener = (SectionFragmentActivity) activity;
        } catch (ClassCastException e) {
            throw new ClassCastException(activity.toString()
                    + " must implement OnFragmentInteractionListener");
        }
    }

    @Override
    public void onResume() {
        super.onResume();
        this.webView.onResume();

        Log.d("axemas-debug", "Resuming " + String.valueOf(getActivity()) + " from " + String.valueOf(this) + " for " + String.valueOf(webView));

        if (!webViewLoading) {
            Log.d("axemas-debug", String.format("Reloading WebView content: %s", this));
            webView.loadUrl(fullUrl);
        }

        AXMActivity axmActivity = ((AXMActivity) getActivity());

        String fragmentRole = getTag();
        if (fragmentRole == null || !fragmentRole.equals("sidebar_fragment")) {
            // We only recover title and sidebar icon if are are not the sidebar itself.
            if (fragmentTitle != null)
                axmActivity.setTitle(fragmentTitle);

            //Back functionality
            FragmentManager fragmentManager = getFragmentManager();
            if(fragmentManager.getBackStackEntryCount() > 1) {
                axmActivity.setBackBarIcon("back");
                axmActivity.actionBarButtonBackVisibility(true);
            }


            AXMSidebarController sidebarController = axmActivity.getSidebarController();
            if (toggleSidebarIcon == null)
                sidebarController.setSidebarButtonVisibility(false);
            else {
                sidebarController.setSideBarButtonIcon(toggleSidebarIcon);
                sidebarController.setSidebarButtonVisibility(true);
            }


            if (actionbarRightIcon == null)
                axmActivity.actionBarButtonRightVisibility(false);
            else {
                axmActivity.setRightBarIcon(actionbarRightIcon);
                axmActivity.actionBarButtonRightVisibility(true);
            }

        }

        if (this.controller != null)
            this.controller.sectionFragmentWillResume();
    }

    @Override
    public void onSaveInstanceState(Bundle outState) {
        Log.d("axemas-debug", "Save Fragment State through Activity -> " + String.valueOf(this));

        if (_unRestoredStateBundle != null) {
            // If we didn't restore the previously saved bundle (onCreateView not called)
            // we just reuse it.
            outState.putAll(_unRestoredStateBundle);
        }
        else {
            webView.saveState(outState);
            outState.putString(FRAGMENT_TITLE, fragmentTitle);
            outState.putBoolean("webViewLoading", webViewLoading);
            outState.putString("toggleSidebarIcon", toggleSidebarIcon);
            outState.putString("actionbarRightIcon", actionbarRightIcon);
        }

        super.onSaveInstanceState(outState);

        if (this.controller != null)
            this.controller.sectionFragmentOnSaveInstanceState(outState);
    }

    @Override
    public void onPause() {
        super.onPause();

        Log.d("axemas-debug", "Pausing Fragment " + String.valueOf(this));

        if (this.controller != null)
            this.controller.sectionFragmentWillPause();

        this.webView.onPause();
    }

    @Override
    public void onDetach() {
        super.onDetach();
        Log.d("axemas-debug", String.format("Detaching Fragment %s...", this));
        mListener = null;
        if (this.webView != null) {
            this.webView.destroy();
            this.webView = null;
        }
    }

    @Override
    public void onDestroyView() {
        super.onDestroyView();
        Log.d("axemas-debug", String.format("DestroyView Fragment %s...", this));
    }

    public void showProgressDialog() {
        AXMActivity activity = (AXMActivity)getActivity();
        Log.d("axemas", "showProgressDialog: " + String.valueOf(activity));
        if (activity != null)
            activity.showProgressDialog();
    }

    public void hideProgressDialog() {
        AXMActivity activity = (AXMActivity)getActivity();
        Log.d("axemas", "hideProgressDialog: " + String.valueOf(activity));
        if (activity != null)
            activity.hideProgressDialog();
    }

    public JavascriptBridge getJSBridge() {
        return this.jsbridge;
    }

    public interface SectionFragmentActivity {
        public void activityLoadContent(JSONObject dataObject);
    }


    private class SectionWebClient extends WebViewClient {
        private JavascriptBridge bridge;
        private AXMSectionController controller;

        SectionWebClient(JavascriptBridge bridge, AXMSectionController controller) {
            this.bridge = bridge;
            this.controller = controller;
        }

        @Override
        public void onPageStarted(WebView view, String url, Bitmap favicon) {
            super.onPageStarted(view, url, favicon);

            showProgressDialog();
            if (this.controller != null && getActivity() != null)
                this.controller.sectionWillLoad();

            Log.d("axemas-debug", String.format("Loading %s (%b) -> %s", SectionFragment.this, SectionFragment.this.isAdded(), url));
            SectionFragment.this.webViewLoading = true;
        }

        @Override
        public boolean shouldOverrideUrlLoading(WebView view, String url) {
            return false;
        }

        @Override
        public void onPageFinished(WebView view, String url) {
            super.onPageFinished(view, url);

            hideProgressDialog();
            webView.refreshDrawableState();
            webView.postInvalidate();

            if (this.controller != null)
                this.controller.sectionDidLoad();

            if (view != null && view.getTitle() != null && !view.getTitle().contains(".html"))
                if (getActivity() != null) {
                    fragmentTitle = view.getTitle();
                    ((AXMActivity) getActivity()).setTitle(fragmentTitle);
                }

            JSONObject data = new JSONObject();
            try {
                data.put("url", url);
            } catch (JSONException e) {
                e.printStackTrace();
                Log.e("axemas", "Unable to encode url in ready event");
            }

            this.bridge.callJS("ready", data, new JavascriptBridge.AndroidCallback() {
                public void call(JSONObject data) {
                    Log.d("axemas", "Page handled ready event with: " + data.toString());
                }
            });
        }
    }

    private class SectionChromeClient extends WebChromeClient {
        @Override
        public boolean onConsoleMessage(ConsoleMessage cm) {
            Log.i("axemas", cm.sourceId() + ":" + cm.lineNumber() + " -> " + cm.message());
            return true;
        }

        @Override
        public void onProgressChanged (WebView view, int newProgress) {
            Log.d("axemas-debug", "Loading %" + String.valueOf(newProgress));
        }
    }

    private class AXMWebView extends WebView {
        AXMWebView(android.content.Context context) {
            super(context);
        }

        @Override
        public boolean onTouchEvent(MotionEvent ev) {
            if (controller == null)
                return super.onTouchEvent(ev);
            if (controller.isInsideWebView(ev)) {
                return super.onTouchEvent(ev);
            }
            return false;
        }
    }
}

package it.axant.axemas;

import android.app.Activity;
import android.util.Log;
import android.webkit.JavascriptInterface;
import android.webkit.WebView;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.HashMap;
import java.util.regex.Pattern;


public class JavascriptBridge {
    private HashMap<String, BaseHandler> registeredHandlers;
    private HashMap<String, Callback> registeredCallbacks;
    private int uniqueCallbackId;
    private WebView webView;

    static public interface Callback {
        public void call(JSONObject data);
        public void call();
    }

    static public abstract class AndroidCallback implements Callback {
        public void call() { this.call(new JSONObject()); }
        public abstract void call(JSONObject data);
    }

    static public abstract class BaseHandler {
        public abstract void call(JavascriptBridge bridge, Object data, Callback callback);
    }

    static public abstract class Handler extends BaseHandler {
        public void call(JavascriptBridge bridge, Object data, Callback callback) {
            this.call(data, callback);
        }
        public abstract void call(Object data, Callback callback);
    }

    JavascriptBridge(WebView webview) {
        this.webView = webview;
        this.registeredHandlers = new HashMap<String, BaseHandler>();
        this.registeredCallbacks = new HashMap<String, Callback>();
    }

    @JavascriptInterface
    public String toString() { return "AndroidJavascriptBridge"; }

    @JavascriptInterface
    public void callAndroid(String handlerName, String data) {
        Log.d("axemas", "calling native handler "+handlerName+" with: "+data);
        Object args = null;
        String callbackId = null;

        try {
            JSONObject parsedData = new JSONObject(data);
            args = parsedData.opt("data");
            try {
                callbackId = parsedData.getString("callbackId");
            }
            catch (JSONException e) {
                callbackId = null;
            }
        }
        catch (JSONException e) {
            e.printStackTrace();
            this.sendError("Invalid message when calling native method");
            return;
        }

        // Parse handler name
        String[] namespaces = handlerName.split(Pattern.quote("."), 2);

        String target = "";
        if(namespaces.length > 1) {
            target = namespaces[0];
            handlerName = namespaces[1];
            Log.d("axemas", "Composit namespace with: target: " + target + " , handlerName: " + handlerName);
        }

        Activity currentActivity = (Activity)webView.getContext();
        JavascriptBridge targetbridge = this;
        if (target.length() > 0 && !target.equals("self")) {
            SectionFragment targetFragment = NavigationSectionsManager.getFragment(currentActivity, target);
            if (targetFragment != null)
                targetbridge = targetFragment.getJSBridge();
        }

        final BaseHandler handler = targetbridge.registeredHandlers.get(handlerName);
        if (handler == null) {
            this.sendError("Calling unregistered Handler");
            return;
        }

        final Object handlerArgs = args;
        final String handlerCallbackId = callbackId;
        final JavascriptBridge bridge = targetbridge;
        currentActivity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                handler.call(bridge, handlerArgs, new JavascriptCallback(bridge, handlerCallbackId));
            }
        });
    }

    public void sendError(String message) {
        Log.e("axemas", message);
        final String javascript = "console.log(\"" + message + "\")";
        this.runJavascript(javascript);
    }

    public void callJS(String handlerName, JSONObject data, AndroidCallback callback) {
        String callbackId = "null";
        if (callback != null) {
            callbackId = this.generateCallbackId();
            this.registeredCallbacks.put(callbackId, callback);
        }

        if (data == null)
            data = new JSONObject();

        String jsMessage = "WebViewJavascriptBridge._callJSHandler(\""+handlerName+"\", "+data.toString()+", \""+callbackId+"\");";
        this.runJavascript(jsMessage);
    }

    public void callJS(String handlerName, JSONObject data) {
        this.callJS(handlerName, data, null);
    }

    public void callJS(String handlerName) {
        this.callJS(handlerName, null, null);
    }

    @JavascriptInterface
    public void callAndroidCallback(String callbackId, String encodedData) {
        Log.d("axemas", "Calling Callback "+callbackId+" with data: "+encodedData);
        JSONObject data;
        try {
            data = new JSONObject(encodedData);
        }
        catch(JSONException e) {
            data = new JSONObject();
        }

        Callback callback = null;
        if (callbackId != null) {
            callback = this.registeredCallbacks.get(callbackId);
            this.registeredCallbacks.remove(callbackId);
        }

        if (callback != null)
            callback.call(data);
    }

    public void registerHandler(String handlerName, BaseHandler handler) {
        registeredHandlers.put(handlerName, handler);
    }

    private String generateCallbackId() {
        return "android_cb_" + (this.uniqueCallbackId++);
    }

    private void runJavascript(final String javascript) {
        final WebView webView = this.webView;
        Activity currentActivity = (Activity)webView.getContext();
        currentActivity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                Log.d("axemas", "Running JS: "+javascript);
                webView.loadUrl("javascript:"+javascript);
            }
        });
    }

    private class JavascriptCallback implements Callback {
        private JavascriptBridge bridge;
        private String callbackId;

        JavascriptCallback(JavascriptBridge bridge, String callbackId) {
            this.bridge = bridge;
            this.callbackId = callbackId;
        }

        public void call() {
            this.call(new JSONObject());
        }

        public void call(JSONObject data) {
            if (this.callbackId != null) {
                String javascript = "WebViewJavascriptBridge._callJSCallback(\"" + this.callbackId + "\", "+data.toString()+");";
                this.bridge.runJavascript(javascript);
            }
        }
    }

}

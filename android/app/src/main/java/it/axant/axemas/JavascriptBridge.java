package it.axant.axemas;

import android.app.Activity;
import android.util.Log;
import android.webkit.JavascriptInterface;
import android.webkit.WebView;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.HashMap;


public class JavascriptBridge {
    private HashMap<String, Handler> registeredHandlers;
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

    static public abstract class Handler {
        public abstract void call(Object data, Callback callback);
    }

    JavascriptBridge(WebView webview) {
        this.webView = webview;
        this.registeredHandlers = new HashMap<String, Handler>();
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

        final Handler handler = registeredHandlers.get(handlerName);
        if (handler == null) {
            this.sendError("Calling unregistered Handler");
            return;
        }

        final JavascriptBridge bridge = this;
        final Object handlerArgs = args;
        final String handlerCallbackId = callbackId;
        Activity currentActivity = (Activity)webView.getContext();
        currentActivity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                handler.call(handlerArgs, new JavascriptCallback(bridge, handlerCallbackId));
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
        String jsMessage = "WebViewJavascriptBridge._callJSHandler(\""+handlerName+"\", "+data.toString()+", \""+callbackId+"\");";
        this.runJavascript(jsMessage);
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

    public void registerHandler(String handlerName, Handler handler) {
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
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Windows.UI.Core;
using Windows.UI.Xaml.Controls;

namespace axemas.Common
{
    using AXMHandler = Action<JavaScriptBridge, JObject, JavaScriptBridge.JavascriptCallback>;
    using AXMCallback = Action<JObject>;
    using StringDict = Dictionary<String, String>;

    public class JavaScriptBridge
    {
        private WeakReference<WebView> webView;
        private Dictionary<string, AXMHandler> registeredHandlers;
        private Dictionary<string, AXMCallback> registeredCallbacks;
        private int uniqueCallbackId;
        private CoreDispatcher uiDispatcher;

        internal JavaScriptBridge(WebView webview, CoreDispatcher uiCoreDispatcher)
        {
            this.uniqueCallbackId = 0;
            this.webView = new WeakReference<WebView>(webview);
            this.registeredCallbacks = new Dictionary<String, AXMCallback>();
            this.registeredHandlers = new Dictionary<string, AXMHandler>();
            this.uiDispatcher = uiCoreDispatcher;
        }

        internal WebView getWebView()
        {
            WebView webView = null;
            this.webView.TryGetTarget(out webView);
            return webView;
        }

        public void registerHandler(string handlerName, AXMHandler handler)
        {
            this.registeredHandlers.Add(handlerName, handler);
        }

        public void callJS(string handlerName, JObject data = null, AXMCallback callback = null)
        {
            string callbackId = "";
            if (callback != null) {
                callbackId = this.generateCallbackId(); 
                this.registeredCallbacks[callbackId] = callback; 
            } 
 
            if (data == null) 
                data = new JObject();

            this.getWebView().InvokeScriptAsync("__axemas_WebViewJavascriptBridge_callJSHandler", 
                new string[] { handlerName, data.ToString(), callbackId});
        }

        private string generateCallbackId()
        {
            return "windows_cb_" + (this.uniqueCallbackId++);
        }

        internal void OnScriptNotify(object sender, NotifyEventArgs e)
        {
            JObject call = JsonConvert.DeserializeObject<JObject>(e.Value);
            Debug.WriteLine("OnScriptNotify: " + call);

            string messageType = call.Value<string>("type");

            JObject jdata = null;
            try {
                call.Value<string>("data");
                jdata = new JObject();
            }
            catch(InvalidCastException)
            {
                jdata = call.Value<JObject>("data");
            }

            if (messageType == "CallHandler") {
                string target = "self";
                string handlerName = call.Value<string>("handlerName");

                // handlerName might be target.handlerName which means to call it on another view
                string[] targetAndHandler = handlerName.Split(".".ToCharArray(), 2);
                if (targetAndHandler != null && targetAndHandler.Length > 1) {
                    target = targetAndHandler[0];
                    handlerName = targetAndHandler[1];
                }


                JavaScriptBridge targetbridge = this;
                if (!target.Equals("self")) {
                    Controls.SectionViewPage sectionViewPage = NavigationSectionManager.Instance.getSectionViewPage(target);
                    if (sectionViewPage != null) {
                        targetbridge = sectionViewPage.getJSBridge();
                    }
                }

                targetbridge.callNativeHandler(handlerName, jdata, call.Value<string>("callbackId"));
            }
            else if (messageType == "CallCallback")
                this.callNativeCallback(call.Value<string>("callbackId"), jdata);
        }

        private void callNativeCallback(string callbackId, JObject data)
        {
            Debug.WriteLine("Calling Callback " + callbackId + " with data: " + data);
            if (callbackId != null) {
                try {
                    var callback = this.registeredCallbacks[callbackId];
                    this.registeredCallbacks.Remove(callbackId);
                    callback(data);
                }
                catch (KeyNotFoundException) { }
            }
        }

        private void callNativeHandler(string handlerName, JObject data, string callbackId)
        {
            AXMHandler handler = null;
            if (!this.registeredHandlers.ContainsKey(handlerName)) {
                Debug.WriteLine("Calling unregistered handler: " + handlerName);
                return;
            }

            try {
                handler = this.registeredHandlers[handlerName];
            }
            catch(KeyNotFoundException) {
                Debug.WriteLine("Calling unregistered handler: " + handlerName);
                return;
            }

            this.uiDispatcher.RunAsync(CoreDispatcherPriority.Normal, () => {
                handler(this, data, new JavascriptCallback(this, callbackId));
            });

        }

        public class JavascriptCallback
        {
            private WeakReference<JavaScriptBridge> bridge;
            private string callbackId;

            internal JavascriptCallback(JavaScriptBridge bridge, string callbackId)
            {
                this.callbackId = callbackId;
                this.bridge = new WeakReference<JavaScriptBridge>(bridge);
            }

            public void call()
            {
                this.call(new JObject());
            }

            public void call(StringDict data)
            {
                this.call(JObject.FromObject(data));
            }

            public void call(JObject data)
            {
                JavaScriptBridge jsbridge;
                this.bridge.TryGetTarget(out jsbridge);

                if (this.callbackId != null && jsbridge != null) {
                    jsbridge.getWebView().InvokeScriptAsync("__axemas_WebViewJavascriptBridge_callJSCallback", 
                        new string[] { this.callbackId, data.ToString() });
                }
            }
        }
    }
}

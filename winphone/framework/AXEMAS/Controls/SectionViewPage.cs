using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices.WindowsRuntime;
using axemas.Controls;
using Windows.Foundation;
using Windows.Foundation.Collections;
using Windows.UI.Xaml;
using Windows.UI.Xaml.Controls;
using Windows.UI.Xaml.Controls.Primitives;
using Windows.UI.Xaml.Data;
using Windows.UI.Xaml.Input;
using Windows.UI.Xaml.Media;
using Windows.UI.Xaml.Navigation;
using System.Diagnostics;
using Windows.UI.Core;
using Windows.UI.Popups;
using axemas.Common;
using Windows.ApplicationModel;
using Newtonsoft.Json;
using Windows.Web;
using Windows.Storage.Streams;
using System.Threading.Tasks;
using Windows.Storage;
using Newtonsoft.Json.Linq;
using Windows.ApplicationModel.Resources;

namespace axemas.Controls
{
    public class SectionViewPage : ViewPage
    {
        protected WebView webView;
        internal ProgressRing progressRing;
        private JavaScriptBridge jsbridge;
        private bool isPrimary;
        private AXMSectionController _controller = null;
        private bool alreadyInitialized;
        private static StreamUriWinRTResolver LocalFilesUriResolver = new StreamUriWinRTResolver();

        public AXMSectionController controller
        {
            get {
                return this._controller;
            }
        }

        public SectionViewPage()
            : this(true)
        {

        }

#if DEBUG
        ~SectionViewPage()
        {
            Debug.WriteLine("Destroying " + this.webView.GetHashCode());
        }
#endif

        public JavaScriptBridge getJSBridge()
        {
            return this.jsbridge;
        }

        public SectionViewPage(bool primary)
            : base()
        {
            this.alreadyInitialized = false;
            this.isPrimary = primary;
            this.Content = new Grid();
            this.webView = new WebView();
            this.jsbridge = new JavaScriptBridge(this.webView, Windows.UI.Core.CoreWindow.GetForCurrentThread().Dispatcher);
            this.progressRing = new ProgressRing();

            Grid grid = this.Content as Grid;
            Grid.SetColumn(this.webView, 1);
            Grid.SetRow(this.webView, 1);
            grid.Children.Add(this.webView);
            grid.Children.Add(this.progressRing);

            this.NavigationCacheMode = NavigationCacheMode.Disabled;
            this.initBultinHandlers();
        }

        private void initBultinHandlers()
        {
            this.jsbridge.registerHandler("goto", (JavaScriptBridge jsbridge, JObject data, JavaScriptBridge.JavascriptCallback cb) => {
                Debug.WriteLine("Goto: " + data);
                NavigationSectionManager.Instance.goTo(data, closeSidebar: false);
            });

            this.jsbridge.registerHandler("gotoFromSidebar", (JavaScriptBridge jsbridge, JObject data, JavaScriptBridge.JavascriptCallback cb) => {
                Debug.WriteLine("Goto: " + data);
                NavigationSectionManager.Instance.goTo(data, closeSidebar: true);
            });

            this.jsbridge.registerHandler("dialog", (JavaScriptBridge jsbridge, JObject data, JavaScriptBridge.JavascriptCallback cb) => {
                string message = data.Value<string>("message") ?? "";
                string title = data.Value<string>("title") ?? "";
                JArray buttons = new JArray();
                
                if (data.Value<JArray>("buttons") != null)
                    buttons = data.Value<JArray>("buttons"); 

                MessageDialog dialog = new MessageDialog(message, title);

                int idx = 0;
                foreach (string button in buttons)
                {
                    dialog.Commands.Add(new UICommand(button, new UICommandInvokedHandler((IUICommand command) => {
                        if (cb != null)
                        {
                            cb.call(JObject.FromObject(new Dictionary<string, int>()
                            {
                                ["button"] = (int)command.Id
                            }));
                        }
                    }), idx));
                    idx++;
                }
                dialog.ShowAsync();
            });

            this.jsbridge.registerHandler("showProgressHUD", (JavaScriptBridge jsbridge, JObject data, JavaScriptBridge.JavascriptCallback cb) => {
                NavigationSectionManager.Instance.showProgressDialog();
            });

            this.jsbridge.registerHandler("hideProgressHUD", (JavaScriptBridge jsbridge, JObject data, JavaScriptBridge.JavascriptCallback cb) => {
                NavigationSectionManager.Instance.hideProgressDialog();
            });

            this.jsbridge.registerHandler("storeData", (JavaScriptBridge jsbridge, JObject data, JavaScriptBridge.JavascriptCallback cb) => {
                string key = data.Value<string>("key");
                string value = data.Value<string>("value");
                NavigationSectionManager.Instance.store(key, value);
                if (cb != null) {
                    cb.call();
                }
            });

            this.jsbridge.registerHandler("fetchData", (JavaScriptBridge jsbridge, JObject data, JavaScriptBridge.JavascriptCallback cb) => {
                string key = data.Value<string>("key");
                string value = NavigationSectionManager.Instance.getValueForKey(key);
                if (cb != null)
                {
                    cb.call(JObject.FromObject(new Dictionary<string, string>()
                    {
                        [key] = value
                    }));
                }
            });

            this.jsbridge.registerHandler("removeData", (JavaScriptBridge jsbridge, JObject data, JavaScriptBridge.JavascriptCallback cb) => {
                string key = data.Value<string>("key");
                NavigationSectionManager.Instance.removeValue(key);
            });

            this.jsbridge.registerHandler("callJS", (JavaScriptBridge jsbridge, JObject data, JavaScriptBridge.JavascriptCallback cb) => {
                string handlerName = data.Value<string>("handler");
                JObject callData = data.Value<JObject>("data");
                jsbridge.callJS(handlerName, callData);
            });
        }

        static internal string BuildNavigationData<T>(T data)
        {
            return JsonConvert.SerializeObject(data);
        }

        static internal void Navigate(Frame rootFrame, Type pageType, JObject data)
        {
            rootFrame.Navigate(pageType, BuildNavigationData(data));
        }

        public void loadUrl(String url)
        {
            if (url.StartsWith("http://"))
                this.webView.Source = new Uri(url);
            else {
                Uri uri = this.webView.BuildLocalStreamUri("AXEMAS", url);
                this.webView.NavigateToLocalStreamUri(uri, LocalFilesUriResolver);
            }
        }

        internal void initializeSection(JObject data)
        {
            if (this.alreadyInitialized)
                return;

            this.webView.NavigationStarting += this.sectionWillLoad;
            this.webView.NavigationCompleted += this.sectionDidLoad;
            //this.webView.ManipulationStarting += this.OnTapped;
            this.webView.ScriptNotify += this.jsbridge.OnScriptNotify;

            Debug.WriteLine("Initialize Section " + data);
            string url = data["url"].Value<string>();

            Type controllerClass = NavigationSectionManager.Instance.getControllerTypeForUrl(url);
            Debug.WriteLine("SectionController: " + controllerClass);
            if (controllerClass != null)
            {
                AXMSectionController controller = (AXMSectionController)Activator.CreateInstance(controllerClass);
                controller.bindToSection(this);
                this._controller = controller;
            }

            if (this.controller != null) this.controller.sectionOnViewCreate(this.Content);
            this.alreadyInitialized = true;

            Debug.WriteLine("Navigating " + this.webView.GetHashCode() + " to " + url);
            this.loadUrl(url);
            this.OnResume(this, data);
        }

        protected override void OnNavigatedTo(NavigationEventArgs e)
        {
            base.OnNavigatedTo(e);

            var data = JsonConvert.DeserializeObject<JObject>(e.Parameter as String);
            this.initializeSection(data);
        }

        protected override void OnNavigatedFrom(NavigationEventArgs e)
        {
            //this.webView.ManipulationStarting -= this.OnTapped;
            this.webView.ScriptNotify -= this.jsbridge.OnScriptNotify;

            base.OnNavigatedFrom(e);
            this.OnPause(this, null);
        }

        protected void OnPause(object sender, SuspendingEventArgs e)
        {
            Debug.WriteLine("SectionPausing");
            if (this.controller != null) this.controller.sectionViewPageWillPause();
        }

        protected void OnResume(object sender, JObject data)
        {
            Debug.WriteLine("SectionResuming");
            if (this.controller != null) this.controller.sectionViewPageWillResume();
        }

        protected void sectionWillLoad(WebView webview, WebViewNavigationStartingEventArgs e)
        {
            this.webView.NavigationStarting -= this.sectionWillLoad;

            Debug.WriteLine("sectionWillLoad -> " + webView.Source);
            this.progressRing.IsActive = true;
            if (this.controller != null) this.controller.sectionWillLoad();
        }

        protected void sectionDidLoad(WebView webview, WebViewNavigationCompletedEventArgs e)
        {
            this.webView.NavigationCompleted -= this.sectionDidLoad;

            Debug.WriteLine("sectionDidLoad -> " + webView.Source + " @ " + this.controller);
            this.progressRing.IsActive = false;
            if (this.controller != null) this.controller.sectionDidLoad();

            if (isPrimary) {
                String title = this.webView.DocumentTitle;
                UIElement topBar = NavigationSectionManager.Instance.getTopBarUIElement();

                if ((topBar != null) && (topBar is TextBlock))
                {
                    TextBlock topBarText = topBar as TextBlock;
                    if (title != "" && title != null)
                    {
                        String localizedTitle = new ResourceLoader().GetString(title);
                        if (localizedTitle != null && localizedTitle != "")
                            title = localizedTitle;
                    }
                    topBarText.Text = " " + title;
                }
            }
            this.getJSBridge().callJS("ready", new JObject {
                { "url",  webView.Source}
            });
        }

        protected void OnTapped(object sender, ManipulationStartingRoutedEventArgs e)
        {
            // Currently not supported by WebView, here for future evolutions...
            Debug.WriteLine("ManipulationStarting!!!");
        }
    }
}

public sealed class StreamUriWinRTResolver : IUriToStreamResolver
{
    static private Dictionary<string, IRandomAccessStream> ContentCache = new Dictionary<string, IRandomAccessStream>();
    static private object CacheLock = new object();

    public IAsyncOperation<IInputStream> UriToStreamAsync(Uri uri)
    {
        if (uri == null) {
            throw new Exception("Empty URL to load");
        }
        string path = uri.AbsolutePath;

        // Because of the signature of the this method, it can't use await, so we 
        // call into a seperate helper method that can use the C# await pattern.
        return GetContent(path).AsAsyncOperation();
    }

    private async Task<IInputStream> GetContent(string path)
    {
        bool pathAlreadyCached = false;
        IRandomAccessStream stream;

        lock (CacheLock) {
            pathAlreadyCached = ContentCache.TryGetValue(path, out stream);
        }

        if (pathAlreadyCached) {
            Debug.WriteLine("Cached: " + path);
            return stream.CloneStream();
        }
        else {
            try
            {
                Debug.WriteLine("Loading: " + path);
                Uri localUri = new Uri("ms-appx://" + path);
                StorageFile f = await StorageFile.GetFileFromApplicationUriAsync(localUri);
                stream = await f.OpenAsync(FileAccessMode.Read);

                lock(CacheLock) {
                    ContentCache[path] = stream;
                }

                return stream.CloneStream();
            }
            catch (FileNotFoundException e)
            {
                Debug.WriteLine("Failed to load " + path + " ERROR: " + e.ToString());
                throw new Exception("Invalid path: " + e.ToString());
            }
        }
    }
}

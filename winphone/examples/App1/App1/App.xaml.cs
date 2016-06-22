using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices.WindowsRuntime;
using Windows.ApplicationModel;
using Windows.ApplicationModel.Activation;
using Windows.Foundation;
using Windows.Foundation.Collections;
using Windows.UI.Xaml;
using Windows.UI.Xaml.Controls;
using Windows.UI.Xaml.Controls.Primitives;
using Windows.UI.Xaml.Data;
using Windows.UI.Xaml.Input;
using Windows.UI.Xaml.Media;
using Windows.UI.Xaml.Media.Animation;
using Windows.UI.Xaml.Navigation;
using axemas;
using axemas.Controls;
using Windows.UI.Popups;
using Newtonsoft.Json.Linq;
using System.Diagnostics;

// The Blank Application template is documented at http://go.microsoft.com/fwlink/?LinkId=391641


namespace App1
{
    public sealed partial class App : AxemasApplication
    {
        public App()
        {
            this.InitializeComponent();
        }
        
        protected override void OnLaunched(LaunchActivatedEventArgs e)
        {
            base.OnLaunched(e);

            NavigationSectionManager.Instance.registerDefaultController(typeof(TestDefaultController));

            NavigationSectionManager.Instance.registerController(typeof(TestController), "www/index.html");

            NavigationSectionManager.Instance.makeApplicationRootController( 
                data: new Dictionary<string, string> {
                    {"url", "www/index.html"}
                }, 
                sideBarData: new Dictionary<string, string> {
                    {"url", "www/sidebar.html" }
                }
            );
        }

        protected override void OnAppReady(object sender, EventArgs e)
        {
            base.OnAppReady(sender, e);
            NavigationSectionManager.Instance.getSidebarController().setSidebarButtonIcon("ms-appx:///Assets/StoreLogo.scale-240.png");
        }

    }

    public class TestController : AXMSectionController {
        public override void sectionDidLoad()
        {
            //await (new MessageDialog("Ciao")).ShowAsync();

            this.section.getJSBridge().registerHandler("open-sidebar-from-native", (JObject data, axemas.Common.JavaScriptBridge.JavascriptCallback cb) => {
                NavigationSectionManager.Instance.getSidebarController().toggleSidebar(true);
                cb.call(new Dictionary<string, string> {
                    ["test"] = "val",
                    ["test2"] = "val2"
                });
            });

            this.section.getJSBridge().registerHandler("send-device-name-from-native-to-js", (JObject data, axemas.Common.JavaScriptBridge.JavascriptCallback cb) => {
                this.section.getJSBridge().callJS("display-device-model", JObject.FromObject(new Dictionary<string, string>() {
                    ["name"] = (new Windows.Security.ExchangeActiveSyncProvisioning.EasClientDeviceInformation()).FriendlyName,
                    ["other"] = "...."
                }), (JObject cbdata) => {
                    Debug.WriteLine(cbdata.ToString());
                });
            });
        }
    }

    public class TestDefaultController : AXMSectionController
    {
        public override void sectionDidLoad()
        {
            //await (new MessageDialog("Default")).ShowAsync();
        }
    }
}

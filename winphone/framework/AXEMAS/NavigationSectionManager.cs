using System;
using axemas;
using System.Collections.Generic;
using Windows.UI.Xaml.Controls;

namespace axemas
{
    using Newtonsoft.Json;
    using Newtonsoft.Json.Linq;
    using System.Diagnostics;
    using Windows.UI.Popups;
    using Windows.UI.Xaml;
    using Windows.UI.Xaml.Navigation;
    using StringDict = Dictionary<String, String>;
    using TypeDict = Dictionary<String, Type>;

    /* NavigationSection manager is in charge of managing navigation stack,
       SideBar and NavBar. For the SideBar itself the management is demanded
       to the SideBarController */
    public class NavigationSectionManager
    {
        private Type defaultController = null;
        private TypeDict registeredControllers = new TypeDict();
        private static NavigationSectionManager instance;

        private NavigationSectionManager() { }

        public static NavigationSectionManager Instance
        {
            get
            {
                if (instance == null)
                {
                    instance = new NavigationSectionManager();
                }
                return instance;
            }
        }

        internal Type getControllerTypeForUrl(String url)
        {
            url = url.Split('?')[0];
            if (!this.registeredControllers.ContainsKey(url))
                return this.defaultController;


            try {
                return this.registeredControllers[url];
            }
            catch (KeyNotFoundException) {
                return this.defaultController;
            }
        }

        public AxemasApplication getApplication()
        {
            return Application.Current as AxemasApplication;
        }

        /* Retrieves the application sidebar management object. */
        public SideBarController getSidebarController()
        {
            var app = getApplication();
            return app.sideBarController;
        }

        public AXMNavigationController getActiveNavigationController()
        {
            var app = getApplication();
            return app.navigationController;
        }

        public UIElement getTopBarUIElement()
        {
            var app = getApplication();
            return app.AppContainer.TopBarPanel;
        }

        /* Initializes the AXEMAS application with a given root page and sidebar. */
        public void makeApplicationRootController(StringDict data, StringDict sideBarData = null, Type mainPage = null)
        {
            var app = getApplication();

            if (mainPage == null)
                mainPage = typeof(Controls.SectionViewPage);

            if (sideBarData != null)
            {
                JObject JOsideBarData = (JObject)JToken.FromObject(sideBarData);
                getSidebarController().createWebViewSidebar(JOsideBarData);
            }
            JObject JOdata = (JObject)JToken.FromObject(data);
            Controls.SectionViewPage.Navigate(app.RootFrame, mainPage, JOdata);
        }

        internal int getBackStackDepth()
        {
            AxemasApplication app = Application.Current as AxemasApplication;
            return app.RootFrame.BackStackDepth + 1;  // First element doesn't count on the backstack
        }

        public void goTo(JObject data, bool closeSidebar = false)
        {
            //Debug.WriteLine("GOTO: " + JsonConvert.SerializeObject(data, Formatting.Indented));
            AxemasApplication app = Application.Current as AxemasApplication;

            int stackPopElements = -1;
            if (data["stackPopElements"] != null)
                stackPopElements = data["stackPopElements"].Value<int>();

            int stackMaintainedElements = -1;
            if (data["stackMaintainedElements"] != null)
                stackMaintainedElements = Math.Max(data["stackMaintainedElements"].Value<int>(), 0);

            if (stackPopElements >= getBackStackDepth()) {
                // Special case, popping more than available means keeping 0
                stackPopElements = -1;
                stackMaintainedElements = 0;
            }

            if (stackPopElements > 0) {
                while (stackPopElements-- > 0) {
                    if (app.RootFrame.CanGoBack)
                        app.RootFrame.GoBack();
                    else
                        break;
                }
            }

            bool navigate = data.Value<string>("url") != null;
            if (stackMaintainedElements == 0) {
                if (!navigate)
                {
                    throw new ArgumentException("Is not possibile to maintain 0 elements if no navigation page is provided");
                }
                
                // 0 Maintaned elements is special case as we cannot pop the last view.
                // so we insert the new one at the begin of the stack instead of navigating to it.
                navigate = false;
                stackMaintainedElements = 1;
                app.RootFrame.BackStack.Insert(
                    0,
                    new PageStackEntry(typeof(Controls.SectionViewPage), Controls.SectionViewPage.BuildNavigationData(data), null)
                );
            }

            if (stackMaintainedElements > 0) {
                while (getBackStackDepth() > stackMaintainedElements) {
                    if (app.RootFrame.CanGoBack)
                        app.RootFrame.GoBack();
                    else
                        break;
                }
            }

            if (navigate)
                Controls.SectionViewPage.Navigate(app.RootFrame, typeof(Controls.SectionViewPage), data);

            if (closeSidebar) 
                getSidebarController().toggleSidebar(false);
        }

        public void registerController(Type controllerClass, String route)
        {
            this.registeredControllers[route] = controllerClass;
        }

        public void registerDefaultController(Type controllerClass)
        {
            this.defaultController = controllerClass;
        }

        public Controls.SectionViewPage getActiveSectionViewPage()
        {
            return getApplication().RootFrame.Content as Controls.SectionViewPage;
        }

        public void store(String key, String value)
        {
            var localSettings = Windows.Storage.ApplicationData.Current.LocalSettings;
            localSettings.Values[key] = value;
        }

        public string getValueForKey(string key)
        {
            var localSettings = Windows.Storage.ApplicationData.Current.LocalSettings;
            return localSettings.Values[key] as string;
        }

        public void removeValue(string key)
        {
            var localSettings = Windows.Storage.ApplicationData.Current.LocalSettings;
            localSettings.Values.Remove(key);
        }

        public void showProgressDialog()
        {
            getActiveSectionViewPage().progressRing.IsActive = true;
        }

        public void hideProgressDialog()
        {
            getActiveSectionViewPage().progressRing.IsActive = false;
        }

        public async void showDismissibleAlertDialog(String title, String message)
        {
            var dialog = new MessageDialog(message, title);
            var res = await dialog.ShowAsync();
        }
    }


}
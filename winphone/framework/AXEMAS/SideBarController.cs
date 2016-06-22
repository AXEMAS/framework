using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Windows.UI.Xaml;
using Windows.UI.Xaml.Controls;
using Windows.UI.Xaml.Media.Imaging;

namespace axemas
{
    public class SideBarController
    {
        private WeakReference appref;

        internal SideBarController(AxemasApplication app)
        {
            appref = new WeakReference(app);
        }

        internal AxemasApplication getApp()
        {
            return (AxemasApplication)appref.Target;
        }

        public void toggleSidebar(bool visible)
        {
            if (visible)
                getApp().AppContainer.OpenMenu();
            else
                getApp().AppContainer.CloseMenu();
        }

        public void toggleSidebar()
        {
            toggleSidebar(!getApp().AppContainer.GetMenuIsOpened());
        }

        internal void createWebViewSidebar(JObject data)
        {
            Controls.SectionViewPage sideBarSectionViewPage = new Controls.SectionViewPage(false);
            getApp().AppContainer.MenuPanel = sideBarSectionViewPage;

            sideBarSectionViewPage.initializeSection(data);
        }

        public bool isOpening()
        {
            return getApp().AppContainer.GetMenuIsOpened();
        }

        public void setSidebarButtonIcon(string resourceName)
        {
            if (resourceName == null || resourceName.Length == 0)
                return;

            if (getApp().AppContainer.menuButton == null)
                return;

            Border menuButton = getApp().AppContainer.menuButton;
            Image sidebarButtonImage = menuButton.Child as Image;
            sidebarButtonImage.Source = new BitmapImage(new Uri(resourceName));
        }

        public void setSidebarButtonVisibility(bool visible)
        {
            if (getApp().AppContainer.menuButton == null)
                return;

            if (visible)
                getApp().AppContainer.menuButton.Visibility = Windows.UI.Xaml.Visibility.Visible;
            else
                getApp().AppContainer.menuButton.Visibility = Windows.UI.Xaml.Visibility.Collapsed;
        }

        AXMSectionController getSidebarSectionController()
        {
            Controls.SectionViewPage sideBarSectionViewPage = getApp().AppContainer.MenuPanel as Controls.SectionViewPage;
            return sideBarSectionViewPage.controller;
        }
    }
}

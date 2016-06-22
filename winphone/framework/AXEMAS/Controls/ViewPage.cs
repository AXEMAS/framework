using System;
using System.Threading.Tasks;
using axemas.Common;
using Windows.UI.ViewManagement;
using Windows.UI.Xaml;
using Windows.UI.Xaml.Controls;
using Windows.UI.Xaml.Navigation;
using System.Diagnostics;

namespace axemas.Controls
{
    public class ViewPage : Page
    {
        public UIElement MenuContent
        {
            get { return (UIElement)GetValue(MenuContentProperty); }
            set { SetValue(MenuContentProperty, value); }
        }

        public static readonly DependencyProperty MenuContentProperty =
            DependencyProperty.Register("MenuContent", typeof(UIElement), typeof(ViewPage), new PropertyMetadata(null));

        public UIElement TopBarContent
        {
            get { return (UIElement)GetValue(TopBarContentProperty); }
            set { SetValue(TopBarContentProperty, value); }
        }

        public static readonly DependencyProperty TopBarContentProperty =
            DependencyProperty.Register("TopBarContent", typeof(UIElement), typeof(ViewPage), new PropertyMetadata(null));

        private NavigationHelper navigationHelper;
        private ObservableDictionary defaultViewModel = new ObservableDictionary();

        public ViewPage()
            : base()
        {
            navigationHelper = new NavigationHelper(this);
            this.NavigationCacheMode = NavigationCacheMode.Disabled;
        }

        public NavigationHelper NavigationHelper
        {
            get { return this.navigationHelper; }
        }

        public ObservableDictionary DefaultViewModel
        {
            get { return this.defaultViewModel; }
        }

        protected override void OnNavigatedTo(NavigationEventArgs e)
        {
            try {
                GC.Collect();
                GC.WaitForPendingFinalizers();
            }
            catch (Exception exc) {
                Debug.WriteLine("Error while forcing memory collection: " + exc);
            }

            this.navigationHelper.OnNavigatedTo(e);
            base.OnNavigatedTo(e);
        }

        protected override void OnNavigatedFrom(NavigationEventArgs e)
        {
            this.navigationHelper.OnNavigatedFrom(e);
            base.OnNavigatedFrom(e);
        }

        /*private void ViewPage_Loaded(object sender, RoutedEventArgs e)
        {
            var statusBar = StatusBar.GetForCurrentView();
            if (statusBar != null)
                statusBar.ProgressIndicator.Text = "loading...";
        }

        protected async Task ChangeTrayLoaderVisibility(bool show)
        {
            var statusBar = StatusBar.GetForCurrentView();
            if (statusBar == null)
                return;

            if (show)
                await statusBar.ProgressIndicator.ShowAsync();
            else
                await statusBar.ProgressIndicator.HideAsync();
        }*/
    }
}

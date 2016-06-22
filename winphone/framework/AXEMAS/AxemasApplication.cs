using axemas.Common;
using axemas.Controls;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Windows.ApplicationModel;
using Windows.ApplicationModel.Activation;
using Windows.Networking.Connectivity;
using Windows.UI.Core;
using Windows.UI.Popups;
using Windows.UI.ViewManagement;
using Windows.UI.Xaml;
using Windows.UI.Xaml.Controls;
using Windows.UI.Xaml.Media;
using Windows.UI.Xaml.Media.Animation;
using Windows.UI.Xaml.Navigation;

namespace axemas
{
    /* All Windows applications using AXEMAS **must** inherit from this class
       and override the **OnLaunched** method to create the application structure
       through the NavigationSectionManager */
    public class AxemasApplication : Application
    {
        public FrameContainer AppContainer { get; set; }
        public Frame RootFrame { get; set; }
        internal SideBarController sideBarController { get; }
        internal AXMNavigationController navigationController { get; }
        private TransitionCollection transitions;
        internal ProgressRingWithText connectivityAlert;
        private CoreDispatcher _uiDispatcher;

        public AxemasApplication()
        {
            this.Suspending += this.InternalOnSuspending;
            this.Resuming += this.InternalOnResuming;

            this.sideBarController = new SideBarController(this);
            this.navigationController = new AXMNavigationController(this);
        }

        /* Called when the application is started, before UI is available */
        protected override void OnLaunched(LaunchActivatedEventArgs e)
        {
#if DEBUG
            if (System.Diagnostics.Debugger.IsAttached)
            {
                this.DebugSettings.EnableFrameRateCounter = true;
            }
#endif
            ApplicationView.TerminateAppOnFinalViewClose = false;

            Debug.WriteLine("OnLaunched");

            FrameContainer appContainer = Window.Current.Content as FrameContainer;
            Frame rootFrame = null;

            if (appContainer != null)
            {
                AppContainer = appContainer;
                rootFrame = appContainer.Content as Frame;
                RootFrame = rootFrame;
            }


            if (appContainer == null)
            {
                appContainer = new FrameContainer();
                appContainer.onApplyTemplate += this.OnAppReady;
                rootFrame = new Frame() { Background = null };
                RootFrame = rootFrame;
                appContainer.Content = rootFrame;
                AppContainer = appContainer;

                // FIXME: Never change this, values higher than 0 cause system to reuse pages
                // which leads to handler being registered twice and other problems.
                rootFrame.CacheSize = 0;

                SuspensionManager.RegisterFrame(rootFrame, "AXEMASROOTFRAME");

                if (e.PreviousExecutionState == ApplicationExecutionState.Terminated)
                {
                    this.OnAppStarting(this, null);
                }

                Window.Current.Content = appContainer;
            }

            if (rootFrame.Content == null)
            {
                if (rootFrame.ContentTransitions != null)
                {
                    this.transitions = new TransitionCollection();
                    foreach (var c in rootFrame.ContentTransitions)
                    {
                        this.transitions.Add(c);
                    }
                }

                rootFrame.ContentTransitions = null;
                rootFrame.Navigated += this.OnAppFirstNavigated;
            }

            // Workaround for global font setting
            RootFrame.FontFamily = new FontFamily("Segoe WP");

            _uiDispatcher = Windows.UI.Core.CoreWindow.GetForCurrentThread().Dispatcher;

            this.connectivityAlert = new ProgressRingWithText();
            NetworkInformation.NetworkStatusChanged += new NetworkStatusChangedEventHandler(Connection_NetworkStatusChanged);


            Window.Current.Activate();
        }

        public bool ExistsConnection()
        {
            return IsConnected;
        }

        public bool IsConnected
        {
            get
            {
                var profile = NetworkInformation.GetInternetConnectionProfile();
                var isConnected = (profile != null
                    && profile.GetNetworkConnectivityLevel() ==
                    NetworkConnectivityLevel.InternetAccess);
                return isConnected;
            }
        }

        private async void Connection_NetworkStatusChanged(object sender)
        {
             await _uiDispatcher.RunAsync(CoreDispatcherPriority.Normal, () =>
            {
                this.updateConnectivityAlert();
            });
        }

        /* Called when the first application ViewPage is opened, before it's available */
        protected virtual void OnAppFirstNavigated(object sender, NavigationEventArgs e)
        {
            var rootFrame = sender as Frame;
            rootFrame.ContentTransitions = this.transitions ?? new TransitionCollection() { new NavigationThemeTransition() };
            rootFrame.Navigated -= this.OnAppFirstNavigated;
        }

        private void updateConnectivityAlert()
        {
            if (ExistsConnection())
                this.connectivityAlert.hide();
            else
                this.connectivityAlert.show("The application requires a working internet connection, the following dialog will disappear when connection is available");
        }

        /* Called when the Application is ready and the view constructed */
        protected virtual void OnAppReady(object sender, EventArgs e)
        {
            AppContainer.onApplyTemplate -= this.OnAppReady;
            AppContainer.mainGrid.Children.Add(this.connectivityAlert);
            this.updateConnectivityAlert();
        }

        /* Called when the application is suspended in background, save application state here! */
        protected virtual void OnAppSuspending(object sender, SuspendingEventArgs e)
        {
            
        }

        /* Called when the application is restarted, Load previous application state here! */
        protected virtual void OnAppStarting(object sender, EventArgs e)
        {
            Debug.WriteLine("Starting App");
        }

        private async void InternalOnSuspending(object sender, SuspendingEventArgs e)
        {
            Debug.WriteLine("Application is Suspending...");

            var deferral = e.SuspendingOperation.GetDeferral();

            await SuspensionManager.SaveAsync();
            this.OnAppSuspending(sender, e);

            deferral.Complete();
        }

        private async void InternalOnResuming(object sender, object e)
        {
            Debug.WriteLine("Application is Resuming...");
            await SuspensionManager.RestoreAsync();
        }
    }
}

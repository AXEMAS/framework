using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace axemas
{
    public class AXMNavigationController
    {
        private WeakReference appref;

        internal AXMNavigationController(AxemasApplication app)
        {
            appref = new WeakReference(app);
        }

        internal AxemasApplication getApp()
        {
            return (AxemasApplication)appref.Target;
        }

        public void pushViewPage(Type viewPage, JObject data)
        {
            Controls.SectionViewPage.Navigate(getApp().RootFrame, viewPage, data);

        }

        public void popFragments(int fragmentsToPop)
        {
            JObject data = JObject.FromObject(new Dictionary<string, int>()
            {
                ["stackPopElements"] = (int)fragmentsToPop
            });
            NavigationSectionManager.Instance.goTo(data);
        }

        public void popFragmentsAndMaintain(int maintainedFragmentsArg)
        {
            JObject data = JObject.FromObject(new Dictionary<string, int>()
            {
                ["stackMaintainedElements"] = (int)maintainedFragmentsArg
            });
            NavigationSectionManager.Instance.goTo(data);
        }
    }
}

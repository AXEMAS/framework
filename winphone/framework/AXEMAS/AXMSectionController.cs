using axemas.Controls;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Windows.UI.Xaml;

namespace axemas
{
    public class AXMSectionController {

        private WeakReference _section;
        protected SectionViewPage section {
            get {
                return _section != null ? _section.Target as SectionViewPage : null;
            }
        }

        public AXMSectionController()
        {
            this._section = null;
        }

        internal void bindToSection(SectionViewPage section)
        {
            this._section = new WeakReference(section);
        }

        public virtual void sectionDidLoad()
        {
            // web page finished loading
        }

        public virtual void sectionWillLoad()
        {
            // web page has not yet started to load
        }

        public virtual void sectionOnViewCreate(UIElement Content)
        {
            // axemas viewPage got created
        }

        public virtual void sectionViewPageWillPause() { }
        public virtual void sectionViewPageWillResume() { }
    }
}

package it.axant.axemas;


import android.content.Intent;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.MotionEvent;
import android.view.ViewGroup;
import java.lang.ref.WeakReference;

public class AXMSectionController {
    private WeakReference<SectionFragment> section;

    public AXMSectionController(SectionFragment section) {
        this.section = new WeakReference<SectionFragment>(section);
    }

    protected SectionFragment getSection() {
        return this.section.get();
    }

    public void sectionDidLoad() {
        // web page finished loading
    }

    public void sectionWillLoad() {
        // web page has not yet started to load
    }

    public void sectionOnViewCreate(ViewGroup view) {
        // axemas view/fragment got created
    }

    public boolean isInsideWebView(MotionEvent ev) {
        return true;
    }

    /*
    The following methods are specific to Android as they follow the android excluside lifecycle.
     */
    public void sectionFragmentWillPause() { }
    public void sectionFragmentWillResume() { }
    public void sectionFragmentOnSaveInstanceState(Bundle outState) { }
    public void sectionFragmentOnCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) { }
    public void sectionFragmentOnActivityResult(int requestCode, int resultCode, Intent data) { }
    public void actionbarRightButtonAction() {}
}

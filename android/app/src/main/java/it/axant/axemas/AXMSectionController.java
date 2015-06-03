package it.axant.axemas;


import android.content.Intent;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.MotionEvent;
import android.view.ViewGroup;

public class AXMSectionController {
    protected SectionFragment section;

    public AXMSectionController(SectionFragment section) {
        this.section = section;
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
}

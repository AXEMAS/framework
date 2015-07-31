package it.axant.axemas;

import android.app.FragmentTransaction;
import android.content.Context;
import android.util.Log;
import android.util.TypedValue;
import android.view.View;
import android.widget.FrameLayout;
import android.widget.ImageButton;
import android.widget.RelativeLayout;

import it.axant.axemas.libs.AnimationLayout;

public class AXMSidebarController {
    final private AXMActivity _activity;
    final private AnimationLayout _animationLayout;
    final private View _sidebarButton;

    protected AXMSidebarController(AXMActivity activity, View sidebarButton) {
        super();
        this._activity = activity;
        this._animationLayout = (AnimationLayout)activity.findViewById(R.id.animation_layout);
        _animationLayout.setListener(this.new SidebarEventListener());
        this._sidebarButton = sidebarButton;

        if (_sidebarButton != null) {
            _sidebarButton.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View view) {
                    _animationLayout.toggleSidebar();
                }
            });
        }
    }

    public void setSidebarButtonVisibility(boolean visible) {
        if (_sidebarButton == null)
            return;
        _sidebarButton.setVisibility(visible ? View.VISIBLE : View.GONE);
    }

    public void setSideBarButtonIcon(String resourceName) {
        Log.d("axemas-debug", "Setting actionBarButton ICON " + String.valueOf(resourceName) + " -> " + String.valueOf(_sidebarButton));
        if (_sidebarButton != null && ImageButton.class.isInstance(_sidebarButton)) {
            ((ImageButton)_sidebarButton).setImageResource(
                    _activity.getResources().getIdentifier(resourceName, "drawable",
                            _activity.getPackageName())
            );
        }
    }

    public void setSidebarAnimationConfiguration(float alpha, int duration, String hexColor) {
        _animationLayout.setAnimationDetails(alpha, duration, hexColor);
    }

    protected View enableFullSizeSidebar(int height) {
        _activity.getActionBar().hide();

        TypedValue tv = new TypedValue();
        _activity.getTheme().resolveAttribute(android.R.attr.actionBarSize, tv, true);
        int actionBarHeight = height == -1 ? _activity.getResources().getDimensionPixelSize(tv.resourceId) : height;

        RelativeLayout.LayoutParams params = new RelativeLayout.LayoutParams(
                FrameLayout.LayoutParams.WRAP_CONTENT,
                actionBarHeight
        );
        params.addRule(RelativeLayout.ALIGN_PARENT_TOP);
        View customBar = _activity.getActionBar().getCustomView();
        _activity.getActionBar().setCustomView(new View(_activity));

        RelativeLayout axemasLayout = ((RelativeLayout)_activity.findViewById(it.axant.axemas.R.id.animation_layout_content));
        axemasLayout.addView(customBar, params);

        View axemasSectionContainer = axemasLayout.findViewById(it.axant.axemas.R.id.currentSection);
        RelativeLayout.LayoutParams contentLayout = (RelativeLayout.LayoutParams)axemasSectionContainer.getLayoutParams();
        contentLayout.setMargins(0, actionBarHeight, 0, 0);
        axemasSectionContainer.setLayoutParams(contentLayout);

        return customBar;
    }

    public View enableFullSizeSidebar() {
        return this.enableFullSizeSidebar(-1);
    }

    public boolean isOpening() {
        return _animationLayout.isOpening();
    }

    public void toggleSidebar(boolean visible) {
        if (visible)
            _animationLayout.openSidebar();
        else
            _animationLayout.closeSidebar();
    }

    public void toggleSidebar() {
        _animationLayout.toggleSidebar();
    }

    public AXMSectionController getSidebarSectionController() {
        SectionFragment sidebarFragment = (SectionFragment)_activity.getFragmentManager().findFragmentByTag("sidebar_fragment");
        return (AXMSectionController)sidebarFragment.getRegisteredSectionController();
    }

    protected void makeSideBar(String sidebarUrl) {
        SectionFragment sidebarFragment = SectionFragment.newInstance(sidebarUrl);
        FragmentTransaction sidebarTransaction = _activity.getFragmentManager().beginTransaction();
        sidebarTransaction.replace(R.id.sidebarSection, sidebarFragment, "sidebar_fragment");
        sidebarTransaction.commit();
    }

    private class SidebarEventListener implements AnimationLayout.Listener {
        @Override
        public boolean onContentTouchedWhenOpening() {
            // sidebar is going to be closed, do something with the data here
            boolean value = _activity.onContentTouchedWhenOpening();
            if (!value)
                _animationLayout.closeSidebar();
            return value;
        }

        @Override
        public void onSidebarOpened() {
            _activity.onSidebarOpened();
        }

        @Override
        public void onSidebarClosed() {
            _activity.onSidebarClosed();
        }

    }
}

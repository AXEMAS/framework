package it.axant.axemas.libs;

import android.content.Context;
import android.graphics.Color;
import android.util.AttributeSet;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.view.animation.AlphaAnimation;
import android.view.animation.Animation;
import android.view.animation.TranslateAnimation;

import it.axant.axemas.R;

public class AnimationLayout extends ViewGroup {

    private int duration = 250;
    private float someAplha = 0.0f;
    private final static float NO_ALPHA = 0f;

    protected boolean mPlaceLeft = true;
    protected boolean mOpened;
    protected View mSidebar;
    protected View mContent;
    protected View transparencyLayer;
    protected int mSidebarWidth = 150; /* assign default value. It will be overwrite
                                          in onMeasure by Layout xml resource. */

    protected Animation mAnimation;
    protected AlphaAnimation alphaAnimation;
    protected OpenListener    mOpenListener;
    protected CloseListener   mCloseListener;
    protected Listener mListener;

    protected boolean mPressed = false;

    public AnimationLayout(Context context) {
        this(context, null);
    }

    public AnimationLayout(Context context, AttributeSet attrs) {
        super(context, attrs);
    }

    @Override
    public void onFinishInflate() {
        super.onFinishInflate();
        mSidebar = findViewById(R.id.animation_layout_sidebar);
        mContent = findViewById(R.id.animation_layout_content);
        transparencyLayer = findViewById(R.id.transparency_layer);

        if (mSidebar == null)
            throw new NullPointerException("no view id = animation_sidebar");

        if (mContent == null)
            throw new NullPointerException("no view id = animation_content");

        if( transparencyLayer == null)
            throw  new NullPointerException("no view id = transparency_layer");

        mOpenListener = new OpenListener(mSidebar, mContent);
        mCloseListener = new CloseListener(mSidebar, mContent);
        mSidebar.setVisibility(View.INVISIBLE);
    }


    public void setAnimationDetails(float alpha, int duration, String hexColor){
        this.duration = duration;
        this.someAplha = alpha;
        transparencyLayer.setBackgroundColor(Color.parseColor(hexColor));

    }

    @Override
    public void onLayout(boolean changed, int l, int t, int r, int b) {
        /* the title bar assign top padding, drop it */
        int sidebarLeft = l;
        if (!mPlaceLeft) {
            sidebarLeft = r - mSidebarWidth;
        }
        mSidebar.layout(sidebarLeft,
                0,
                sidebarLeft + mSidebarWidth,
                0 + mSidebar.getMeasuredHeight());

        if (mOpened) {
            if (mPlaceLeft) {
                mContent.layout(l + mSidebarWidth, 0, r + mSidebarWidth, b);
            } else  {
                mContent.layout(l - mSidebarWidth, 0, r - mSidebarWidth, b);
            }
        } else {
            mContent.layout(l, 0, r, b);
        }
    }

    @Override
    public void onMeasure(int w, int h) {
        super.onMeasure(w, h);
        super.measureChildren(w, h);
        mSidebarWidth = mSidebar.getMeasuredWidth();
    }

    @Override
    protected void measureChild(View child, int parentWSpec, int parentHSpec) {
        /* the max width of Sidebar is 90% of Parent */
        if (child == mSidebar) {
            int mode = MeasureSpec.getMode(parentWSpec);
            int width = (int)(getMeasuredWidth()  * 0.75 );
            super.measureChild(child, MeasureSpec.makeMeasureSpec(width, mode), parentHSpec);
        } else {
            super.measureChild(child, parentWSpec, parentHSpec);
        }
    }

    @Override
    public boolean onInterceptTouchEvent(MotionEvent ev) {
        if (!isOpening()) {
            return false;
        }

        int action = ev.getAction();

        if (action != MotionEvent.ACTION_UP
                && action != MotionEvent.ACTION_DOWN) {
            return false;
        }

        /* if user press and release both on Content while
         * sidebar is opening, call listener. otherwise, pass
         * the event to child. */
        int x = (int)ev.getX();
        int y = (int)ev.getY();
        if (mContent.getLeft() < x
                && mContent.getRight() > x
                && mContent.getTop() < y
                && mContent.getBottom() > y) {
            if (action == MotionEvent.ACTION_DOWN) {
                mPressed = true;
            }

            if (mPressed
                    && action == MotionEvent.ACTION_UP
                    && mListener != null) {
                mPressed = false;
                return mListener.onContentTouchedWhenOpening();
            }
        } else {
            mPressed = false;
        }

        return false;
    }

    public void setListener(Listener l) {
        mListener = l;
    }

    /* to see if the Sidebar is visible */
    public boolean isOpening() {
        return mOpened;
    }

    public void toggleSidebar() {
        if (mContent.getAnimation() != null) {
            return;
        }

        if (mOpened) {
            /* opened, make close animation*/
            if (mPlaceLeft) {
                mAnimation = new TranslateAnimation(0, -mSidebarWidth, 0, 0);
            } else {
                mAnimation = new TranslateAnimation(0, mSidebarWidth, 0, 0);
            }
            mAnimation.setAnimationListener(mCloseListener);

            alphaAnimation = new AlphaAnimation(someAplha, NO_ALPHA);
            transparencyLayer.setClickable(false);

        } else {
            /* not opened, make open animation */
            if (mPlaceLeft) {
                mAnimation = new TranslateAnimation(0, mSidebarWidth, 0, 0);
            } else {
                mAnimation = new TranslateAnimation(0, -mSidebarWidth, 0, 0);
            }
            mAnimation.setAnimationListener(mOpenListener);

            alphaAnimation = new AlphaAnimation(NO_ALPHA, someAplha);
            transparencyLayer.setClickable(true);
        }
        mAnimation.setDuration(duration);
        mAnimation.setFillAfter(true);
        mAnimation.setFillEnabled(true);

        alphaAnimation.setDuration(duration);
        alphaAnimation.setFillAfter(true);
        alphaAnimation.setFillEnabled(true);
        alphaAnimation.setAnimationListener(new Animation.AnimationListener() {
            @Override
            public void onAnimationStart(Animation animation) {
                if(!mOpened)
                   transparencyLayer.setAlpha(someAplha);
            }

            @Override
            public void onAnimationEnd(Animation animation) {

            }

            @Override
            public void onAnimationRepeat(Animation animation) {
            }
        });

        mContent.startAnimation(mAnimation);
        transparencyLayer.startAnimation(alphaAnimation);

    }

    public void openSidebar() {
        if (!mOpened) {
            toggleSidebar();
        }
    }

    public void closeSidebar() {
        if (mOpened) {
            toggleSidebar();
        }
    }

    class OpenListener implements Animation.AnimationListener {
        View iSidebar;
        View iContent;

        OpenListener(View sidebar, View content) {
            iSidebar = sidebar;
            iContent = content;
        }

        public void onAnimationRepeat(Animation animation) {
        }

        public void onAnimationStart(Animation animation) {
            iSidebar.setVisibility(View.VISIBLE);
        }

        public void onAnimationEnd(Animation animation) {
            iContent.clearAnimation();
            mOpened = !mOpened;
            requestLayout();
            if (mListener != null) {
                mListener.onSidebarOpened();
            }
        }
    }

    class CloseListener implements Animation.AnimationListener {
        View iSidebar;
        View iContent;

        CloseListener(View sidebar, View content) {
            iSidebar = sidebar;
            iContent = content;
        }

        public void onAnimationRepeat(Animation animation) {
        }
        public void onAnimationStart(Animation animation) {
        }

        public void onAnimationEnd(Animation animation) {
            iContent.clearAnimation();
            iSidebar.setVisibility(View.INVISIBLE);
            mOpened = !mOpened;
            requestLayout();
            if (mListener != null) {
                mListener.onSidebarClosed();
            }
        }
    }

    public interface Listener {
        public void onSidebarOpened();
        public void onSidebarClosed();
        public boolean onContentTouchedWhenOpening();
    }
}

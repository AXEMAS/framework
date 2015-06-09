; $(function() {
    "use strict";

    $('#section-link').on('singletap', function() {
        //all parameters except *url* are optional
        axemas.goto({'url':'www/section.html',
                     'title':'Section'
                     /* 'stackMaintainedElements': 1000, */
                     /* 'stackPopElements':0, */
                     /* 'toggleSidebarIcon': 'slide_icon' */
                    });
    });


    $('#js-call-native-link').on('singletap', function() {
        axemas.call('open-sidebar-from-native');
    });


    $('#native-call-js-link').on('singletap', function() {
        axemas.call('send-device-name-from-native-to-js');
    });


    $('#native-section-link').on('singletap', function() {
        axemas.call('push-native-section');
    });


    $('#scroll-top-link').on('singletap', function() {
        $('html, body').animate({scrollTop : 0},800);
    });


    // Registered method to be called from Native

    axemas.register("display-device-model", function(payload){
        axemas.dialog('Native response', "Some information on the device:\n- "
                        + payload.name +"\n- "+ payload.other, ['Close']);
    });




});
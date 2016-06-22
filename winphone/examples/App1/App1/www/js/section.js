; $(function() {
    "use strict";

    $('button').on('singletap', function() {
        //all parameters except *url* are optional
        axemas.goto({'url':'www/section.html',
                     'title':'Section'
                    });
    });
});

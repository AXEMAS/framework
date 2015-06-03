Android AXEMAS library
======================

This library project is used to build the axemas.aar used inside the Android application.


How to use
----------

After modifiying the library please inside this project's root folder::

./gradlew clean assemble

You will find the ``app-release.aar`` inside the ``app/build/outputs/aar/`` folder. Copy this file
inside the ``axemas-android`` project in the ``libs`` folder.
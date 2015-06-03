==============
AXEMAS Library
==============

``AXEMAS`` base library
 
for AXEMAS online docs: https://rawgit.com/AXEMAS/doc/master/build/html/index.html
 
 
- Android library project
- iOS library project
- HTML library project

When you are done modifing the library please remember to update the debug projects and the release repository
with the following commands.


Debug Projects Update
---------------------

To update the ``Android`` and the ``iOS`` demo projects use the following command 
(examples folder must be in the same parent folder or will be cloned inside ../examples)::

    ./update_debug

Il will delete all the old files in the iOS and Android projects and copy the new library files;
native binraies and HTML.
If you want to release demo apps remember to make necessary fixes, up version and push everything


Release Repository Update
-------------------------

Same as for the Debug Project Update, this will update the repository that the ``gearbox axemas-setup``
command needs to clone in order to quickstart a new project::

    ./update_release

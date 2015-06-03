===================
AXANT Objects
===================

AXO, or AXant Objects is an ObjectiveC utility library with a bunch of ready made classes for iPhone development.

It's target is speeding up common patterns in mobile applications by providing ready made objects configured for that specific purpouse. The objects provided by the library enfatize simplicity and robustness over flexibility, so while they are usually not highly configurable they provide a clear functionality available through a single line of code.

AXO
========================

The AXO class provides a bunch of class methods, it acts more as a collection of utilities than an actual object.

**attributize** function makes the object able to store arbitrary attributes, this makes possible to add properties to the object without having to subclass::

    [AXO attributize: obj];
    [obj set:@"propName" toValue:proValue];
    [obj get:@"propName"];

**escapeStringForRequest** escapes a string to be used as an URL GET parameter::

    NSString *escaped = [AXO escapeStringForRequest:@"àèìòù"];

**alertWithTitle:body:** displays an alert box with just an OK button::

    [AXO alertWithTitle:@"Failed" body:@"Unable to retrieve address"];

**alertWithTitle:body delegate:** displays an alert box with just an OK button and set a delegate::

    [AXO alertWithTitle:@"Failed" body:@"Unable to retrieve address" delegate: yourDelegate];

**alertWithTitle:body button delegate:** displays an alert box with custom button and set a delegate::

    NSDictionary *btn = @{
                                    @"cancelButtonTitle": @"Cancel",
                                    @"otherButtonTitles": [NSArray arrayWithObjects:@"Button1",@"Button2",nil]
                                    };
    [AXO alertWithTitle:@"Title" body:@"Some Text" button:btn delegate: yourDelegate];

**decodeBase64** given a base64 string decodes it to the binary representation::

    NSData *data = [AXO decodeBase64:@"iVBORw0KGgoAAAANSU"];

**embeddedImageNamed:fromPool:** loads an `UIImage` from a pool of embedded images.
The pool is a `NSDictionary` of images stores as base64 strings, when loading
from a retina display the same image named @2x is looked for::

    UIImage *img = [AXO embeddedImageNamed:@"blackButton" romPool:EmbeddedImages];

**isNull:** checks if a given object is nil or NSNull.
Always use this when checking entries loaded from a JSON encoded response.

**triggerNotification:withObject:** raises a notification on the main thread::

    [AXO triggerNotification:@"TriggerReloadChat" withObject:nil];

AXOScheduledActivity
========================

Runs an activity in background.
This permits to run the activity both once or repeated every X seconds, when running repeatedly the activity provides a guard to avoid running the action multiple times when it takes longer than the scheduled frame.
It is also possible to enabled a spinner which will appear during the execution of the acitity to prevent the user from doing other actions.
The AXOScheduledActivity is attributized by AXO so it is possible to call get: and set:toValue: to store additional properties.
A completion callback is available to notify activity completion.

EXAMPLE::

    self.fetchShopsActivity = [AXOScheduledActivity new];
    [self.fetchShopsActivity enableSpinner];
    [self.fetchShopsActivity registerAction:^(AXOScheduledActivity *activity) {
        [self performSearch];
    }];
    [self.fetchShopsActivity registerOnComplete:^(AXOScheduledActivity *activity) {
        [self.shopsList reloadData];
    }];
    [self.fetchShopsActivity fireAndForget];
    //OR [self.fetchShopsActivity schedule:10] to run it every 10 seconds.

AXOChoicePicker
========================

Given a list of options it opens a dialog to select one of the options.
It also supports closing the dialog without choosing any option, in such a case the previously selected option is recovered. By default no option is selected::

    NSArray *regions = @[@"Calabria", @"Sicilia", @"Sardegna"];
    self.regionPicker = [[AXOChoicePicker alloc] initWithTitle:@"Regione"
                                                       options:regions
                                                      onSelect:^(NSString *selectedEntry) {
                                                          [self onRegionSelect:selectedEntry];
                                                      }];
    [self.regionPicker show];

it is possible to update the options after the creation of the picker by using the `setOptionsList:` method, when the list of options is updated the currectly selected option gets lost. The selected option is available by `selectedOption` property.

AXOButtonFactory
========================

The button factory provides a way to create better looking buttons than the standard buttons provided by iOS.
It uses a bunch of embedded images to provide good looking buttons.

To create a button simply use::

    UIButton *btn = [AXOButtonFactory buttonWithLook:@"darkBlackButton"];

To patch an existing button use::

    [AXOButtonFactory patchButton:btn withLook:@"darkBlackButton"];

To replace a *UINavigationBar* button with an image button use (keeps actions of the existing button, so you can set it up from StoryBoard)::

    [AXOButtonFactory replaceNavigationButton:self.navigationItem.rightBarButtonItem
                                    withImage:[UIImage imageNamed:@"Navbar-Btn-Notifiche"]];

AXOImageTools
========================

Provides utilities to handle images and colors. Requires **SDWebImage.frameworks** to be added to the project dependencies.

To load a *UITableViewCell* image asynchronously from an *NSURL* and resize it to the same size of the placeholder use::

    [AXOImageTools asyncDownloadImageForCell:cell
                             withPlaceHolder:[UIImage imageNamed:@"placeholder"]
                                     fromUrl:imageUrl];

To scale an **UIImage** use::

    UIImage *scaledImage = [AXOImageTools scaleImage:image toSize:imageSize];

To scale an **UIImage** keeping aspect ratio::

    UIImage *scaledImage = [AXOImageTools scaleImageKeepAspect:image toSize:imageSize];

To create a **UIColor** from RGB integers::

    UIColor *color = [AXOImageTools RGBcolorWithRed:225 green:240 blue:213 alpha:1.0];


DataRepository
=======================

The **DataRepository** provides a super easy access to CoreData handling concurrency and exposing a simple atomic API to perform edits.
When using the DataRepository you should never modify the *NSManageObjects* but instead use the DataRepository methods.
DataRepository will automatically cast values to the correct type when setting them and will ignore values not existing into the entity.
To start using DataRepository you just need to create a **DataRepository.xcdatamodeld** inside your application bundle and declare the entities you will need.
*Keep in mind to always add a String* **uid** *field inside every declared entry* it will be automatically generated when not provided and used to retrieve entries by id.

Insert a single Entry::

    [[DataRepository shared] insertEntities:@"Notification"
                                   withData:@{@"text":@"Hello World",
                                              @"read":@NO,
                                              @"created_at":@"2001-10-11 11:30:27"}];

Fetching Entities by Query::

    self.notifications = [[DataRepository shared] fetchEntities:@"Notification"
                                                      withQuery:nil
                                                  withArguments:nil
                                                      sortingBy:@[@[@"created_at", @NO]]];

Get a single Entity by ID::

    [[DataRepository shared] get:@"Notification" byId:@"12"];

Updating an Entity by ID::

    [[DataRepository shared] updateEntity:@"Notification" byId:[notification valueForKey:@"uid"]
                                 withData:@{@"read": @YES}];

Fetch and Modify multiple entries::

    self.notifications = [[DataRepository shared] fetchAndModifyEntities:@"Notification"
                                                               withQuery:@"seen != YES"
                                                           withArguments:nil
                                                               sortingBy:@[@[@"created_at", @NO]]
                                                                 setData:@{@"seen":@YES}];

Delete an Entity by ID::

    [[DataRepository shared] deleteEntity:@"Notification" byId:[entry valueForKey:@"uid"]];

Insert multiple entities from a NSDictionary NSArray (like data returned by an API)::

    [[DataRepository shared] insertEntities:@"Notification"
                                   withData:[resp objectForKey:@"notifications"]];

MTNotification
==========================

Permits to post notifications to the *default* ``NSNotificationCenter`` without
having to care about threading issues::

    [MTNotification triggerNotification:@"event-name" withObject:@{@"data": @"value"}];

Location Master
==========================

Location Master is an easier to use alternative to LocationManager, it tries to
satisfy most use cases for both background and foreground usage and relies on the
``MTNotification`` instead of delegates to notify when newer positions are available.

To use the Location Master you need to add ``NSLocationAlwaysUsageDescription`` key to
your application ``.plist``.

Then create the ``LocationMaster`` inside your ``didFinishLaunchingWithOptions`` delegate
method and set the required precision constraints::

    self.locationMaster = [[LocationMaster alloc] init];
    [self.locationMaster setLocationAge:15.0
                          withPrecision:kCLLocationAccuracyHundredMeters];    
    [self.locationMaster start];

To start receiving new locations register for ``LocationMasterGotNewLocation`` notification
on the ``NSNotificationCenter defaultCenter``. The LocationMaster will automatically
provide a location when the user moves enough, to force retrieving the current location send
a ``LocationMasterRequestNewLocation`` through ``MTNotification`` and you will receive
the current user location.

When you don't need new locations just call ``stop`` method on the LocationMaster.

**NOTE:** You can leave the LocationMaster active as long as you need as it will only
monitor signification location changes to avoid draining battery. Note that it works
even when in background so it can be used also for background applications.           

For example to show the current user location on a map on realtime you can use::

    - (void)viewDidAppear:(BOOL)animated {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(gotNewLocation:)
                                                     name:LocationMasterGotNewLocation
                                                   object:nil];
    }

    - (IBAction)updateLocation:(id)sender {
        [MTNotifications triggerNotification:LocationMasterRequestNewLocation withObject:nil];
    }

    - (void)gotNewLocation:(NSNotification*)locationInfo {    
        CLLocationCoordinate2D def;
        def.latitude = [locationInfo.object[@"latitude"] doubleValue];
        def.longitude = [locationInfo.object[@"longitude"] doubleValue];
        
        AddressAnnotation *addAnnotation = [[AddressAnnotation alloc] initWithCoordinate:def];
        [self.map addAnnotation:addAnnotation];
        
        MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(def, 3000, 3000);
        [self.map setRegion:region animated:YES];
    }


Reusable Controllers
==========================

To use AXO Controllers inside your project, make sure you **drag AXOResources.bundle** 
from AXO *Products* into your project *Copy Bundle Resources* in target *Build Phases*.

WebViewController
--------------------

Makes possible to quickly open web urls inside an iOS application as a native
controller instead of using the system browser::

    UIViewController *webview = [WebViewController controllerWithUrl:@"http://www.google.com"];
    [self.navigationController pushViewController:webview animated:YES];


GalleryViewController
-----------------------

Simple matrix image showcase, with configurable thumbs size and padding. On tap will display the
zoomable/scrollable full size image::

    GalleryViewController *galleryViewController = [GalleryViewController controllerWithImagesPredicate:^NSArray*{
        return self.galleryImages;
    }];
    [self.navigationController pushViewController:galleryViewController animated:YES];

The array returned by the predicate block could contain UIMageView objects or image remote urls.

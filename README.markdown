InterfaCSS
==========
> The simple, powerful and reusable way of giving your iOS application style, using CSS. 

InterfaCSS emerged out of frustration with the shortcomings of the available Interface Building tools, one of the most important being the constant need to repeat yourself when it comes to styling of user interface elements. There had to be a better way. 

And out of that notion sprung the foundation of InterfaCSS, which after a spending a longish time fermenting and maturing and whatnot, finally is taking shape. One area where particularly much fermentation has been going on is in the stylesheet parsing department, even though the choice of a CSS-like syntax was made quite early. A few parser implementations have come and gone, but the one that finally stuck is [Parcoa](https://github.com/brotchie/Parcoa).


What InterfaCSS does
--------------------

* Let's you style user interface elements in a simple and reusable fashion, using a [syntax](#StylesheetFormat) that is based on CSS, and augmented with some Sass/Less-like features. 
* Enables you to build an application without using nib/xib files and without writing lots of tedious UI setup code.
* Let's you control almost every aspect your UI objects, such as fonts, colors, images, transform, insets, offsets, position, size and much, much more.
* Provides an easy way to setup you view hierarchy though a view builder class (`ISSViewBuilder`) or through the use of a view definition file ([XML](https://github.com/tolo/InterfaCSS/wiki/View-Definition-File-Reference)).
* Enables you to load an auto-refreshable stylesheet from a URL, which will speed up and simplify UI development considerably.
* InterfaCSS is completely free of dodgy Objective-C runtime manipulations (such as method swizzling and whatnot), something that may or may not make you sleep better at night.



Getting started
---------------

###Install
You can add InterfaCSS to your project in two ways: 

* The simplest way is to use [CocoaPods](http://cocoapods.org/).

* Download the source and add the files in the `InterfaCSS` directory to your project. Note that [Parcoa](https://github.com/brotchie/Parcoa) is a required dependency.


###Sample code
Checking out the sample code is a good way to get a feel for how InterfaCSS is used in an app. To run the sample code, do this: 

* Run `pod install` in the `Samples/SimpleSample directory.
* Open `SimpleSample.xcworkspace`.
* Build and run.


###Setup InterfaCSS in your app

* Load a stylesheet, like this: `[[InterfaCSS interfaCSS] loadStyleSheetFromMainBundleFile:@"myDazzlingStyles.css"];`. A good place to do this is in your app delegate, when your app is first launched.

* Set up your view hierarchy and set some initial styles classes on your views. This you can do in a few different ways: 
    * By using [`ISSViewBuilder`](InterfaCSS/UI/ISSViewBuilder.h) to create your view hiearchy, like this: `self.view = [ISSViewBuilder rootViewWithStyle:@"myFancyStyleClass" ....` 
    * By using a view definition file, you set the style classes of the elements in the definiton file and load it like this: `self.view = [ISSViewBuilder loadViewHierarchyFromMainBundleFile:@"views.xml" withFileOwner:self];` 
    * Create your view hierarchy manually/using a .nib and then apply styles using the methods defined in [`UIView+InterfaCSS.h`](InterfaCSS/UI/UIView+InterfaCSS.h). 
    
* Update styles as you go
    * At any time you can add or remove style classes using the methods provided in the category [`UIView+InterfaCSS.h`](InterfaCSS/UI/UIView+InterfaCSS.h).
    * Whenever the styles of a view are changed, InterfaCSS will re-apply styles automatically. However in other cases, for instance if a view is thrown around in the view hierarchy (i.e. moved to a new super view), you will have to manually tell InterfaCSS to re-apply styles. You can do this by invoking the method `applyStyling` in [`UIView+InterfaCSS.h`](InterfaCSS/UI/UIView+InterfaCSS.h).

* To make development simpler and faster, try using an auto-refreshable stylesheet (in addition to your standard stylesheets) loaded from a URL (web server, cloud service or file in the local file system for instance). This will let you play around with the styles while you're running the application, which can really be a time and frustration saver, particularly when you're running on a device. Note though that this feature is only intended for use during development. This is how you do it: `[[InterfaCSS interfaCSS] loadRefreshableStyleSheetFromURL:[NSURL URLWithString:@"..."]];`




<a name="StylesheetFormat">Stylesheet format</a>
------------------------------------------------

InterfaCSS does not try to impose some artificial mapping layer between the stylesheet format and iOS - the names of stylesheet properties are the same as the actual UI object properties they set (except that case is not important and you may insert dashes anywhere you fancy). That being said, there are some areas in which InterfaCSS tries to make life easier, but more on that below.

The format of the stylesheet files used by InterfaCSS is in structure essentially the same as standard CSS used for the web - what differs is basically the properties you can use and the supported [selectors](http://www.w3.org/TR/CSS21/selector.html).

This is what InterfaCSS supports: 

* Type, style class, descendant and wildcard selectors are supported (more may come).
* Multiple selectors / selector chains may be specified for each declaration block.
* Supported type selectors are most of the typical UIKit view (and view related) classes, such as `UIView` etc (case insensitive, 'UI' is optional)
* If multiple declarations match, the last one wins. This rule also applies to stylesheets, i.e the stylesheet added last may override declarations in previously added stylesheets.

Furthermore, InterfaCSS also supports some Sass/Less-like features:

* Nested declarations - i.e. nest declaration blocks within declaration blocks.
* Variables(constants) - basically reusable property values. 
* Color functions.

 
For a complete reference to the supported properties etc, see [**here**](https://github.com/tolo/InterfaCSS/wiki/Stylesheet-Property-Reference).

Below is an example of how a stylesheet file for InterfaCSS could look like:

    /* Variables: */
    @stdFont1: HelveticaNeue-Medium 14;
    @stdColor1: rgb(0, 0, 255);

    UILabel {
        minimumScaleFactor: 0.75;
        adjustsFontSizeToFitWidth: YES;
        autoresizingMask: none;
        textAlignment: left;
    }

    .mainView {
        autoresizingMask: width height;
        backgroundColor: stdColor1;

        .mainTitleLabel, .mainSubtitleLabel {
            textColor: desaturate(magenta, 25%);
        }

        .mainTitleLabel {
            frame: rect(15, 30, 160, 30);
            textColor: #ffffff;
            font: @stdFont1;
            anchorPoint: point(0, 0);
            transform: rotate(5);
        }

        .simpleSampleMainButton {
            bounds: size(160, 40);
            center: parent(0, 10);
            titleColor(highlighted): magenta;
        }
        
        .mainTable {
            frame: parent(100, 10, 10, 10);
            clipsToBounds: YES;
            cornerRadius: 6;
            borderColor: darkGray;
            borderWidth: 1;
            
            UITableViewCell * {
                textColor: #4f4f4f;
            }
            
            .cellLabel1 {
                frame: rect(5, 2, 120, 21);
                font: @stdFont1;
            }

            .cellLabel2 {
                frame: size(auto, auto).left(50%).right(3%);
                font: HelveticaNeue-UltraLight 36;
                textAlignment: right;
            }
        }
    } 

    // Landscape orientation adjustment for tableview:
    .landscape .mainTable {
        frame: parent(80, 10, 10, 10);
    }



Project status
--------------

The current version (as of 2014-02-19) is 0.8. This basically means that most of the basic stuff is in place, and it's just that last 20% of polish that is missing before a first stable version can be announced.

This is what must happen before version 1.0:

* Finalize basic feature set and public API.
* Better unit test coverage.
* Better documentation
* Parser performance enhancements (some work has already been done here, but more can be done)

And of couse - all feedback is most welcome!


þetta er ágætis byrjun.


License
--------------

MIT license - see [here](LICENSE).

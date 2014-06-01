InterfaCSS
==========
> The simple, powerful and reusable way of giving your iOS application style, using CSS.

InterfaCSS emerged out of frustration with the shortcomings of the available Interface Building tools, one of the most important being the constant need to repeat yourself when it comes to styling of user interface elements. There had to be a better way.

And out of that notion sprung the foundation of InterfaCSS, which after a spending a longish time fermenting finally is here to make your iOS-user-interface-coding-life a little bit easier. So go ahead, create yourself some fantastic [styles](#StylesheetFormat) and some amazing [layouts](#Layout), and you'll never look back!


What InterfaCSS does
--------------------

* Lets you style UI elements in a simple and reusable fashion, using a [syntax](#StylesheetFormat) that is based on CSS, and augmented with some Sass/Less-like features.
* Enables you to build an application without using nib/xib files and without writing lots of tedious UI setup code.
* Lets you control almost every aspect your UI elements, such as fonts, colors, images, transform, insets, offsets, position, size and much, much more.
* Provides an easy way to setup you view hierarchy though a view builder class (`ISSViewBuilder`) or through the use of a view definition file ([XML](https://github.com/tolo/InterfaCSS/wiki/View-Definition-File-Reference)).
* Enables you to load an auto-refreshable stylesheet from a URL, which will speed up and simplify UI development considerably.

InterfaCSS is also:

* Completely free of dodgy Objective-C runtime manipulations (such as method swizzling and whatnot), something that may or may not make you sleep better at night.
* Using a CSS parser built upon the amazing parser combinator framework [Parcoa](https://github.com/brotchie/Parcoa).



Getting started
---------------

###Install
You can add InterfaCSS to your project in two ways:

* The simplest way is to use [CocoaPods](http://cocoapods.org/).

* Download the source and add the files in the `InterfaCSS` directory to your project. Note that [Parcoa](https://github.com/brotchie/Parcoa) is a required dependency.


###Sample code
Checking out the sample code is a good way to get a feel for how InterfaCSS is used in an app. To run the sample code, do this:

* Run `pod install` in the `Samples/SimpleSample` directory.
* Open `SimpleSample.xcworkspace`.
* Build and run.


###Setup InterfaCSS in your app

* Load a stylesheet, like this: `[[InterfaCSS interfaCSS] loadStyleSheetFromMainBundleFile:@"myDazzlingStyles.css"];`. A good place to do this is in your app delegate, when your app is first launched.

* Set up your view hierarchy and set some initial styles classes on your views. This you can do in a few different ways:
    * By using [`ISSViewBuilder`](InterfaCSS/UI/ISSViewBuilder.h) to create your view hiearchy, like this: `self.view = [ISSViewBuilder rootViewWithStyle:@"myFancyStyleClass" ....`
    * By using a view definition file, you set the style classes of the elements in the definiton file and load it like this:
    `self.view = ` `[ISSViewBuilder loadViewHierarchyFromMainBundleFile:@"views.xml" withFileOwner:self];`
    * Create your view hierarchy manually/using a .nib and then apply styles using the methods defined in [`UIView+InterfaCSS.h`](InterfaCSS/UI/UIView+InterfaCSS.h), for instance:
        * `self.view.styleClassISS = @"groovyStyle";`
        * `[self.view addStyleClassISS:@"groovyStyle"];`
    * Or if you still feel the need to use Interface Builder to setup your views, you can still specify one or more style classes for each UI element in the *Identity Inspector* under *User Defined Runtime Attributes* - just set the **Key Path** to `styleClassISS`, the **Type** to `String` and the **Value** to whatever style class(es) you want to use (multiple style classes are separated by a space).

* Update styles as you go
    * At any time you can add or remove style classes using the methods provided in the category [`UIView+InterfaCSS.h`](InterfaCSS/UI/UIView+InterfaCSS.h).
    * Whenever the styles of a view are changed, InterfaCSS will re-apply styles automatically. However in other cases, for instance if a view is thrown around in the view hierarchy (i.e. moved to a new super view), you will have to manually tell InterfaCSS to re-apply styles. You can do this by invoking the method `applyStylingISS` in [`UIView+InterfaCSS.h`](InterfaCSS/UI/UIView+InterfaCSS.h).

* If you get stuck and starting feel the urge to break something, consider doing this first:
    * Try using `-[InterfaCSS logMatchingStyleDeclarationsForUIElement:]` to log the active style declarations for your view, and see if they are whay you expect them to be.
    * Enable more verbose logging by invoking `[NSObject iss_setLogLevel:ISS_LOG_LEVEL_TRACE];` defined in [`NSObject+ISSLogSupport.h`](InterfaCSS/Util/NSObject+ISSLogSupport.h)


###Setup automatic css reload during development

To make development simpler and faster, try using an auto-refreshable stylesheet (in addition to your standard stylesheets) loaded from a URL (file in the local file system, web server or cloud service for instance). This will let you play around with the styles while you're running the application, which can really be a time and frustration saver, particularly when you're running on a device. Note though that this feature is only intended for use during development. This is how you do it (in your app delegate for instance):

```objective-c
#if DEBUG == 1
    /* For local (simulator) use, you can for instance load the actual css file used in your project as an auto-refreshable stylesheet: */
    [[InterfaCSS interfaCSS] loadRefreshableStyleSheetFromURL:[NSURL URLWithString:@"file://Users/username/myCoolXcodeProject/myDazzlingStyles.css"]];
    /* Or if you want to be able to run on a device, you can for instance simply upload the file to your cloud provider of choice: */
    [[InterfaCSS interfaCSS] loadRefreshableStyleSheetFromURL:[NSURL URLWithString:@"http://www.mygroovycloudprovider.com/myDazzlingStyles.css"]];
#endif
```


<a name="StylesheetFormat">Stylesheet format</a>
------------------------------------------------

InterfaCSS does not try to impose some artificial mapping layer between the stylesheet format and iOS - the names of stylesheet properties are the same as the actual UI object properties they set (except that case is not important and you may insert dashes anywhere you fancy). That being said, there are some areas in which InterfaCSS tries to make life easier, but more on that below.

The format of the stylesheet files used by InterfaCSS is in structure essentially the same as standard CSS used for the web - what differs is basically the properties you can use and the supported [selectors](http://www.w3.org/TR/selectors).

This is what InterfaCSS supports:

* Type, style class and wildcard selectors are supported.
* Descendant (whitespace), child (`>`), adjacent sibling (`+`) and general sibling (`~`) selector combinators.
* Pseudo classes:
    * [Structural pseudo classes](http://www.w3.org/TR/selectors/#structural-pseudos)
    * Enabled/disabled (for `UIControl` and others)
    * Interface orientation (`landscape`, `landscapeLeft`, `landscapeRight`, `portrait`, `portraitUpright`, `portraitUpSideDown`)
* Multiple selectors / selector chains may be specified for each declaration block.
* Supported type selectors are most of the typical UIKit view (and view related) classes, such as `UIView` etc (case insensitive, 'UI' is optional)
* If multiple declarations match, the last one wins. This rule also applies to stylesheets, i.e the stylesheet added last may override declarations in previously added stylesheets.
* Setting nested properties on certain nested views, i.e. for instance `titleLabel.font`. These are the nested views that are supported at the moment:
`imageView`, `contentView`, `backgroundView`, `selectedBackgroundView`, `multipleSelectionBackgroundView`, `titleLabel`, `textLabel`, `detailTextLabel`, `inputView`, `inputAccessoryView`,
`tableHeaderView`, `tableFooterView` and `backgroundView`.

Furthermore, InterfaCSS also supports some Sass/Less-like features:

* Nested declarations - i.e. nest declaration blocks within declaration blocks.
* Variables(constants) - basically reusable property values.
* Color functions.


For a complete reference to the supported properties etc, see [**here**](https://github.com/tolo/InterfaCSS/wiki/Stylesheet-Property-Reference).

Below is an example of how a stylesheet file for InterfaCSS could look like:

```css
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
        transform: rotate(5);   // Rotate 5 degrees
    }

    .simpleSampleMainButton {
        bounds: size(160, 40);
        center: parent(0, 10);  // Offset from parent center
        titleColor(highlighted): magenta;
    }

    .mainTable {
        frame: parent(100, 10, 10, 10);   // Parent bounds inset using UIEdgeInsetsInsetRect
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
            frame: size(auto, auto).left(50%).right(3%);   // Frame using parent-relative sizing & insets
            font: HelveticaNeue-UltraLight 36;
            textAlignment: right;
        }
    }

    // Landscape orientation adjustment for tableview:  
    .mainTable:landscape {
        frame: parent(80, 10, 10, 10);  // Parent bounds inset using UIEdgeInsetsInsetRect
    }
}
```

<a name="Layout">Layout</a>
------
In the layout department, InterfaCSS can help you in these ways:

* Make it easier to create the view hierarcy through the use of the builder methods defined in [`ISSViewBuilder`](InterfaCSS/UI/ISSViewBuilder.h) or by using an XML-based [view definition file](https://github.com/tolo/InterfaCSS/wiki/View-Definition-File-Reference).
* Make positioning and sizing of views easier, by making it possible to use parent relative values when setting frame, bounds and center properties in the stylesheet.

### Create the view hierarcy

#### Using ISSViewBuilder view builder methods
ISSViewBuilder lets you programmatically create a view heirarchy in a quick and convenient way, that also makes it very easy to understand the layout of the view tree. You can easily assign created view to properties (see examples below) and you may optionally specify multiple style classes for each view (separated by space or comma).

Example of using ISSViewBuilder in the `loadView method of a view controller:

```objective-c
- (void) loadView {
    self.view = [ISSViewBuilder rootViewWithStyle:@"mainView" andSubViews:^{
        return @[
            self.mainTitleLabel = [ISSViewBuilder labelWithStyle:@"mainLabel stdLabel"],
            [ISSViewBuilder labelWithStyle:@"subLabel stdLabel"],
            [ISSViewBuilder viewWithStyle:@"contentView" andSubViews:^{
                return @[
                    [ISSViewBuilder labelWithStyle:@"contentTitleLabel"],
                    [ISSViewBuilder labelWithStyle:@"contentSubtitleLabel"]
                ];
            }]
        ];
    }];
}
```

You can also use a shorthand style by defining the macro `ISS_VIEW_BUILDER_SHORTHAND_ENABLED`:

```objective-c
self.view = [ISSBuildRoot:@"mainView" beginSubViews
        self.mainTitleLabel = [ISSBuildLabel:@"mainLabel stdLabel"],
        [ISSBuildLabel:@"subLabel stdLabel"],
        [ISSBuildView:@"contentView" beginSubViews
            [ISSBuildLabel:@"contentTitleLabel"],
            [ISSBuildLabel:@"contentSubtitleLabel"]
        endSubViews]
endSubViews];
```

#### Using a view definition file
Another way of creating a view hiearchy is by using an XML-based view definition file. This way also have the benefit of making the view hierarchy very easy to understand, and just like the programmatic way, you can specify multiple style classes in the `class` attribute and you can assign views to properties by using the `property` attribute ("fileOwner" is first attempted, then superview).

Using a view definition file, you also have the option of creating prototype views (use the `prototype` attribute), which can be useful for table view cells for instance.

Example of loading a view hierarchy from a view definition file in the `loadView` method of a view controller:

```objective-c
- (void) loadView {
    self.view = [ISSViewBuilder loadViewHierarchyFromMainBundleFile:@"views.xml" withFileOwner:self];
}
```


### Positioning and sizing
Besides setting fixed values for `frame`, `bounds` and `center` properties, you also have the option of using parent (or window) relative values. These relative values are evaluated during styling of a view, which means that you may have to manually apply styling when the parent view frame changes, unless you are using using a `ISSRootView` as the root view of the a view hierarchy.

####[Rect](https://github.com/tolo/InterfaCSS/wiki/Stylesheet-Property-Reference#CGRect) (frame / bounds)
A relative rect value can be created in these ways:

* `parent` - the bounds of the superview
* `parent(xInset, yInset)` - the bounds of the superview, with the specified insets applied (using `CGRectInset`)
* `size(width, height)` - sets the size using absolute point values or parent relative values. Relative values can either be percentage values like `50%` or the keyword `auto`. The auto keyword is only useful if insets are specified along with the size, for instance: `size(50%, auto).left(5%).right(50)`. When auto is used, InterfaCSS makes sure that the sum of width/height and insets always adds up to the width/height of the parent.


####[Point](https://github.com/tolo/InterfaCSS/wiki/Stylesheet-Property-Reference#CGPoint) (center):
* `parent` - the center point in the superview
* `parent(xOffset, yOffset)` - the center point in the superview, offset with the specifed offsets.


Project status
--------------

The latest released version is currently 0.9.1 (0.9.2 is soon to be released). This basically means that most of the basic stuff is in place, and it's just that last 10% of polish that is missing before a first stable version can be announced.

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

<img src="https://raw.githubusercontent.com/tolo/InterfaCSS/master/Resources/InterfaCSS-title-logo.png" alt="InterfaCSS" title="InterfaCSS" width="432">


[![Build Status](https://travis-ci.org/tolo/InterfaCSS.svg?branch=master)](https://travis-ci.org/tolo/InterfaCSS)


Everyone loves a beautifully designed app with a consistent UI, and getting there shouldn't take a huge effort. What if there was a way you could style your app in a concise and powerful way, without constantly having to repeat yourself. What if things could be more like on the web?



## Welcome to InterfaCSS



### Simple yet powerful styling
InterfaCSS uses an easy to understand styling [syntax](#stylesheet-format) that is based on *CSS*, and augmented with some *Sass/Less*-like features, such as *nested declarations* and *constants*. Property names are what you expect them to be - i.e. the same as in UIKit, and you can set things like *fonts, colors, images, transform, insets, offsets, rects, enums* and much, much [**more**](https://github.com/tolo/InterfaCSS/wiki/Stylesheet-Property-Reference).



### InterfaCSS can get you [DRY](http://en.wikipedia.org/wiki/Don't_repeat_yourself)
We all hate to duplicate code, so why should styling be any different? Sure, `UIAppearance` can help you in a *(very)* limited way, but would you still want to write (and read) things like this:

```objective-c
[[UIButton appearanceWhenContainedIn:UITableViewCell.class, nil] setTitleColor:
    [UIColor colorWithRed:255 green:109 blue:16 alpha:1] forState:UIControlStateSelected];
```

when you instead can write it like this:

```css
UITableViewCell UIButton {
    titleColor(selected): #ff6d10;
}
```

And what if you actually want to have more than *one* type of button in your table view cells?

```css
UITableViewCell .mySpecialButton {
    titleColor(selected): red;
}
```



### Consice and clean setup of view hierarchy
Using a [view builder](#layout), setting up the UI in your view controllers is a breeze - gone are the days of writing tedious UI setup code or fiddling with unwieldy xib-files (but you can still use them just fine with InterfaCSS if you want of course).



### *Hot deployment* of your stylesheets
Load an auto-refreshable stylesheet from a (file/web) URL, and watch how the UI updates itself before your very eyes, without having to wait for those frustrating `compile`/`deploy`/`launch`/`returnToWhereYouWere`-cycles.


### InterfaCSS is also ...

* Completely free of dodgy Objective-C runtime manipulations (such as method swizzling and whatnot), something that may or may not make you sleep better at night.  

* Using a CSS parser based upon the amazing parser combinator framework [Parcoa](https://github.com/brotchie/Parcoa).



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

* Load a stylesheet, like this: `[[InterfaCSS interfaCSS] loadStyleSheetFromMainBundleFile:@"myDazzlingStyles.css"];`. A good place to do this is in your app delegate, when your app is first launched, but if you have a lot of stylesheets it's better to defer loading of the stylesheets to when you actually need them (`loadView` of a particular view controller might be a better place in this case).

* Set up your view hierarchy and set some initial styles classes on your views. This you can do in a few different ways:

    * Create your view hierarchy manually or using a nib/storyboard, and then apply styles using the methods defined in [`UIView+InterfaCSS.h`](InterfaCSS/UI/UIView+InterfaCSS.h), for instance:
        * `self.view.styleClassISS = @"groovyStyle";`
        * `[self.view addStyleClassISS:@"anEvenMoreGroovyStyle"];`

    * Use [`ISSViewBuilder`](InterfaCSS/UI/ISSViewBuilder.h) to create your view hierarchy in a concise fashion, like this: `self.view = [ISSViewBuilder labelWithStyle:@"myFancyStyleClass" ....`

    * If you feel more at home in Interface Builder, you can specify one or more style classes for each UI element in the *Identity Inspector* under *User Defined Runtime Attributes* - just set the **Key Path** to `styleClassISS`, the **Type** to `String` and the **Value** to whatever style class(es) you want to use (multiple style classes are separated by a space).

    * Using a [view definition file](#using-a-view-definition-file), you can set the style classes of the elements in the definition file and load it like this:
        `self.view = [ISSViewBuilder loadViewHierarchyFromMainBundleFile:@"views.xml" withFileOwner:self];`

* Update styles as you go:
    * At any time you can add or remove style classes using the methods provided in the category [`UIView+InterfaCSS.h`](InterfaCSS/UI/UIView+InterfaCSS.h).

    * Whenever the styles of a view are changed, InterfaCSS will re-apply styles automatically. However in other cases, for instance if a view is thrown around in the view hierarchy (i.e. moved to a new super view), you will have to manually tell InterfaCSS to re-apply styles. You can do this by invoking the method `applyStylingISS` in [`UIView+InterfaCSS.h`](InterfaCSS/UI/UIView+InterfaCSS.h). You can also use an `ISSRootView` as the root of a view (sub) tree - this class makes sure that styling is applied whenever the view moves to a new super view, window or if the `frame` property is changed is changed (you can create one using the method `[ISSViewBuilder rootViewWithStyle:]` for instance).

* If you get stuck and starting feel the urge to break something, consider doing this first:
    * Try using `-[InterfaCSS logMatchingStyleDeclarationsForUIElement:]` to log the active style declarations for your view, and see if they are whay you expect them to be.

    * Enable more verbose logging by invoking `[NSObject iss_setLogLevel:ISS_LOG_LEVEL_TRACE];` defined in [`NSObject+ISSLogSupport.h`](InterfaCSS/Util/NSObject+ISSLogSupport.h)


###Setup automatic css reload during development

To make development simpler and faster, try using an auto-refreshable stylesheet (in addition to your standard stylesheets) loaded from a URL (file in the local file system, web server or cloud service for instance). This will let you play around with the styles while you're running the application, which can really be a time and frustration saver, particularly when you're running on a device. Note though that this feature is only intended for use during development. Checkout the snippet below for an example on how you add refreshable stylesheets (in your app delegate for instance). Also, checkout the properties `stylesheetAutoRefreshInterval` and `processRefreshableStylesheetsLast` in `InterfaCSS`, for more control over how refreshable stylesheets are managed.

```objective-c
#if DEBUG == 1
    /* For local (simulator) use, you can for instance load the actual css file used in your project as an auto-refreshable stylesheet: */
    [[InterfaCSS interfaCSS] loadRefreshableStyleSheetFromURL:
        [NSURL URLWithString:@"file://Users/username/myCoolXcodeProject/myDazzlingStyles.css"]];
    /* Or if you want to be able to run on a device, you can for instance simply upload the file to your cloud provider of choice: */
    [[InterfaCSS interfaCSS] loadRefreshableStyleSheetFromURL:
        [NSURL URLWithString:@"http://www.mygroovycloudprovider.com/myDazzlingStyles.css"]];
#endif
```



### Beyond the basics

If you need more control over how/when styling is applied, have a look at these properties and methods in [`UIView+InterfaCSS.h`](InterfaCSS/UI/UIView+InterfaCSS.h):

 * [`willApplyStylingBlockISS`](InterfaCSS/UI/UIView+InterfaCSS.h#L31) - specify a block to be run before styling.
 * [`didApplyStylingBlockISS`](InterfaCSS/UI/UIView+InterfaCSS.h#L36) - specify a block to be run after styling.
 * [`disableStylingISS`](InterfaCSS/UI/UIView+InterfaCSS.h#L123) - disable styling entirely of view.
 * [`enableStylingISS`](InterfaCSS/UI/UIView+InterfaCSS.h#L128) - re-enable styling of view.
 * [`applyStylingOnceISS`](InterfaCSS/UI/UIView+InterfaCSS.h#L103) - apply styling only once for the view (then disable styling).
 * [`disableStylingForPropertyISS:`](InterfaCSS/UI/UIView+InterfaCSS.h#L143) - disable styling of a specific property in a view.
 * [`enableStylingForPropertyISS:`](InterfaCSS/UI/UIView+InterfaCSS.h#L148) - re-enable styling of property.
 * [`customStylingIdentityISS`](InterfaCSS/UI/UIView+InterfaCSS.h#L143) - specify a custom styling identity to increase performance.

There is also support for registering custom styleable properties, via the class [`ISSPropertyRegistry`](InterfaCSS/Model/ISSPropertyRegistry.h), accessible 
through the property `propertyRegistry` in [`InterfaCSS`](InterfaCSS/InterfaCSS.h).


Stylesheet format
-----------------

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
* Support properties that are bound to a certain `UIControlState` (for instance): `titleColor(highlighted): red;`
* Support for locking a property to its current value (through the `current` keyword / value).
* Support for expressing a range of different [value types](https://github.com/tolo/InterfaCSS/wiki/Stylesheet-Property-Reference#PropertyValueTypes), such as fonts, colors, images, transform, insets, offsets, rects, enums, [attributed strings](https://github.com/tolo/InterfaCSS/wiki/Stylesheet-Property-Reference#NSAttributedString) etc.

Furthermore, InterfaCSS also supports some Sass/Less-like features:

* Nested declarations - i.e. nest declaration blocks within declaration blocks.
* Variables(constants) - basically reusable property values.
* Color functions.


For a complete reference to the supported properties etc, see the [**Stylesheet Property Reference**](https://github.com/tolo/InterfaCSS/wiki/Stylesheet-Property-Reference).

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
        backgroundImage: red; // Using color as image
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

Layout
------
In the layout department, InterfaCSS can help you in these ways:

* Make it easier to create the view hierarchy through the use of the builder methods defined in [`ISSViewBuilder`](InterfaCSS/UI/ISSViewBuilder.h) or by using an XML-based [view definition file](https://github.com/tolo/InterfaCSS/wiki/View-Definition-File-Reference).
* Make positioning and sizing of views easier, by making it possible to use parent relative values when setting frame, bounds and center properties in the stylesheet.

### Create the view hierarchy

#### Using ISSViewBuilder view builder methods
ISSViewBuilder lets you programmatically create a view hierarchy in a quick and convenient way, that also makes it very easy to understand the layout of the view tree. You can easily assign created view to properties (see examples below) and you may optionally specify multiple style classes for each view (separated by space or comma).

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

The pattern of the shorthand is basically this: `[ISSBuildXXX:...` = `[ISSViewBuilder XXXWithStyle:...`, and you can create all the views supported by ISSViewBuilder using this shorthand (that is: `ISSBuildRoot`, `ISSBuildView`, `ISSBuildCollectionView`, `ISSBuildImageView`, `ISSBuildScrollView`, `ISSBuildTableView`, `ISSBuildWebView`, `ISSBuildActivityIndicator`, `ISSBuildButton`, `ISSBuildLabel`, `ISSBuildProgressView`, `ISSBuildSlider`, `ISSBuildStepper`, `ISSBuildSwitch`, `ISSBuildTextField`, `ISSBuildTextView`, `ISSBuildTableViewCell`).

Furthermore, you can also use the `beginSubViews` and `endSubViews` macros to make adding of subviews cleaner, as shown above.


#### Using a view definition file
Another way of creating a view hierarchy is by using an XML-based [view definition file](https://github.com/tolo/InterfaCSS/wiki/View-Definition-File-Reference). This way also have the benefit of making the view hierarchy very easy to understand, and just like the programmatic way, you can specify multiple style classes in the `class` attribute and you can assign views to properties by using the `property` attribute (`fileOwner` is first attempted, then superview).

Using a view definition file, you also have the option of creating prototype views (use the `prototype` attribute), which can be useful for table view cells for instance.

Example of loading a view hierarchy from a view definition file in the `loadView` method of a view controller:

```objective-c
- (void) loadView {
    self.view = [ISSViewBuilder loadViewHierarchyFromMainBundleFile:@"views.xml" withFileOwner:self];
}
```


### Positioning and sizing
Besides setting fixed values for `frame`, `bounds` and `center` properties, you also have the option of using parent (or window) relative values. These relative values are evaluated during styling of a view, which means that you may have to manually apply styling when the parent view frame changes, unless you are using using a `ISSRootView` as the root view of a view hierarchy.

####[Rect](https://github.com/tolo/InterfaCSS/wiki/Stylesheet-Property-Reference#CGRect) (frame / bounds)
A relative rect value can be created in these ways:

* `parent` - the bounds of the superview
* `parent(xInset, yInset)` - the bounds of the superview, with the specified insets applied (using `CGRectInset`)
* `size(width, height)` - sets the size using absolute point values or parent relative values. Relative values can either be percentage values like `50%` or the keyword `auto`. The auto keyword is only useful if insets are specified along with the size, for instance: `size(auto, 50%).left(5%).right(50)`. When auto is used, InterfaCSS makes sure that the sum of width/height and insets always adds up to the width/height of the parent.


####[Point](https://github.com/tolo/InterfaCSS/wiki/Stylesheet-Property-Reference#CGPoint) (center):
* `parent` - the center point in the superview
* `parent(xOffset, yOffset)` - the center point in the superview, offset with the specifed offsets.


Project background and status
-----------------------------

### Background

InterfaCSS emerged out of frustration with the shortcomings of the available Interface Building tools, one of the most important being the constant need to repeat yourself when it comes to styling of user interface elements. There had to be a better way.

And out of that notion sprung the foundation of InterfaCSS, which after a spending a longish time fermenting in dark corners of various applications, finally has made a public appearance. During it's evolution into an open source project, other similar projects have popped up, although InterfaCSS still differs from most of them:

* Property names are what you expect them to be and the list of supported properties is extensive
* Powerful CSS support (selector chains, selector combinators, pseudo classes, nested declarations)
* You're not only getting help with styling, but with layout as well


### Status

The latest released version is currently 0.9.12. This basically means that most of the basic stuff is in place, and it's just that final polish that is missing before a first stable version can be announced.

This is what must happen before version 1.0:

* Finalize basic feature set and public API.
* Better unit test coverage.
* Better documentation.
* Parser performance enhancements (some work has already been done here, but more can be done).

And of course - all feedback is most welcome!



*"þetta er ágætis byrjun."*



License
--------------

MIT license - see [here](LICENSE).

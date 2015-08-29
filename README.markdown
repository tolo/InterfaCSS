<img src="https://raw.githubusercontent.com/tolo/InterfaCSS/master/Resources/InterfaCSS-title-logo.png" alt="InterfaCSS" title="InterfaCSS" width="432">


[![Build Status](https://travis-ci.org/tolo/InterfaCSS.svg?branch=master)](https://travis-ci.org/tolo/InterfaCSS)


> Everyone loves a beautifully designed app with a consistent UI, and getting there shouldn't take a huge effort. What if there was a way you could style and layout your app in a concise and powerful way, without constantly having to repeat yourself. What if things could be more like on the web?



## Welcome to InterfaCSS



### Simple yet powerful styling
InterfaCSS uses an easy to understand styling [***syntax***](https://github.com/tolo/InterfaCSS/wiki/Stylesheet-format) that is based on the the familiar ***CSS*** styling language used on the web (augmented with some *Sass/Less*-like features, such as *nested declarations* and *variables*), which means that you (and your designer) will probably feel right at home. InterfaCSS supports a rich selector syntax (*type*, *class* and *element id* selectors, *selector combinators*, *pseudo classes*, etc) and property names are what you expect them to be - i.e. the same as in `UIKit`, and you can set things like *fonts, colors, images, transform, insets, offsets, rects, enums* and much, much [***more***](https://github.com/tolo/InterfaCSS/wiki/Stylesheet-Property-Reference).

```css
#helloWorldButton {
  attributedText: "Hello " (foregroundColor: yellow), "World" (foregroundColor: #0000ff);
  backgroundColor: "patternImageAsColor.png";
  borderWidth: 3;
  borderColor: fadeout(magenta, 75%);
  cornerRadius: @numberVariable;
  clipsToBounds: YES;
  layout: size(100, 21), left(parent + 10), top(guide.top + 100);
  transform: rotate(15);
}
```


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

/* Or maybe like this, if you wanted to be even more specific: */
BraveNewViewController UITableViewCell UIButton.mySpecialButton {
    titleColor(selected): #ff6d10;
}
```


### Flexible layouts, the easy way
InterfaCSS lets you define ***[layouts](https://github.com/tolo/InterfaCSS/wiki/Using-InterfaCSS#layout-of-views)*** based on values that depend on the position and size of other elements. Layouts are expressed directly in the stylesheet file, and the format is very easy to understand.

```css
#view1 {
    layout: size(25, 25), left(parent.leftMargin), top(parent.topMargin);
}

#view2 {
    layout: size(view1, view1), left(view1.right + 10), top(view1.top);
}
```

In addition, using a ***[view builder](https://github.com/tolo/InterfaCSS/wiki/Using-InterfaCSS#creating-a-view-hierarchy)***, setting up the UI in your view controllers is a breeze - gone are the days of writing tedious UI setup code or fiddling with unwieldy xib-files (but you can still use them just fine with InterfaCSS if you want of course) - simply define your UI in an XML file or do it in code, by using [`ISSViewBuilder`](InterfaCSS/UI/ISSViewBuilder.h).

*XML:*
```xml
<view id="rootView">
    <view id="view1"/>
    <view id="view2" layout="size(view1, view1), left(view1.right + 10), top(view1.top)"/> <!-- It's possible to define layouts here as well -->
</view>
```

*In code (Swift):*
```Swift
self.view = ISSViewBuilder.rootViewWithId("rootView", withOwner: self, andSubViews: {
    return [
        ISSViewBuilder.viewWithId("view1"),
        ISSViewBuilder.viewWithId("view2"),
    ];
})
```

### Style as you go

Styling isn't something you just do at startup of course - you can easily modify the styling any time by using methods defined in the category [`UIView+InterfaCSS.h`](InterfaCSS/UI/UIView+InterfaCSS.h), for example:

```objective-c
self.view.styleClassISS = @"groovyStyle anotherGroovyStyle"; // Supports multiple style classes separated by whitespace - TIP: This property is also IBInspectable
```
```objective-c
self.view.elementIdISS = @"groovyElement"; // To uniquely style a specific element
```
```objective-c
[self.view addStyleClassISS:@"anEvenMoreGroovyStyle"];
[self.view removeStyleClassISS:@"anEvenMoreGroovyStyle"];
```

Read more about how styling is applied on the ***[Using InterfaCSS](https://github.com/tolo/InterfaCSS/wiki/Using-InterfaCSS)*** wiki page.


### Stylesheets

For larger apps, it's usually a good idea to split up the styles on different stylesheet files - perhaps you want one for variables, one for common styles, and several stylesheets for different parts of the application for instance. You can also attach a *scope* when loading stylesheet (*version 1.1*), to make sure the styles it in are only processed for views under a particular view controller (for instance).

```objective-c
ISSStyleSheetScope* scope = [ISSStyleSheetScope scopeWithViewControllerClass:BraveNewViewController.class];
[[InterfaCSS interfaCSS] loadStyleSheetFromMainBundleFile:@"stylesForOnePartOfTheApp.css" withScope:scope];
```

#### *Hot deployment* of your stylesheets (for development)
To make development simpler and faster, try using an auto-refreshable stylesheet (in addition to your standard stylesheets) - load an auto-refreshable stylesheet from a (file/web) URL, launch your app on a device or in the sim, and watch how the UI updates itself before your very eyes, without having to wait for those frustrating `compile`/`deploy`/`launch`/`returnToWhereYouWere`-cycles. Note though that this feature is only intended for use during development. Checkout the snippet below for an example on how you add refreshable stylesheets (in your app delegate for instance). Also, checkout the properties `stylesheetAutoRefreshInterval` and `processRefreshableStylesheetsLast` in `InterfaCSS`, for more control over how refreshable stylesheets are managed.

```objective-c
/* For local (simulator) use, you can for instance load the actual css file used in your project as an auto-refreshable stylesheet: */
[[InterfaCSS interfaCSS] loadRefreshableStyleSheetFromLocalFile:@"/Users/username/myCoolXcodeProject/myDazzlingStyles.css"];
/* Or if you want to be able to run on a device, you can for instance simply upload the file to your cloud provider of choice: */
[[InterfaCSS interfaCSS] loadRefreshableStyleSheetFromURL:
   [NSURL URLWithString:@"http://www.mygroovycloudprovider.com/user/directory/mymyDazzlingStyles.css"]];
```



##Getting started

###Install
You can add InterfaCSS to your project in two ways:

* The simplest way is to use [CocoaPods](http://cocoapods.org/).

* Download the source and add the files in the `InterfaCSS` directory to your project. Note that [Parcoa](https://github.com/brotchie/Parcoa) is a required dependency.


###Sample code
Checking out the sample code is a good way to get a feel for how InterfaCSS is used in an app. To run the sample code, do like this:

* Run `pod install` in the `Samples/SimpleSample` directory.
* Open `SimpleSample.xcworkspace`.
* Build and run.


###Setup InterfaCSS in your app

* Load a stylesheet, like this: `[[InterfaCSS interfaCSS] loadStyleSheetFromMainBundleFile:@"myDazzlingStyles.css"];`. A good place to do this is in your **app delegate**, when your app is first launched, but if you have a lot of stylesheets it's better to defer loading of the stylesheets to when you actually need them (`loadView` of a particular view controller might be a better place in this case).

* Start adding styles. As with most new things, it's best to start small. For instance, don't start with adding crazily complex selectors like `UIView + UITableView:nthoftype(5n+1) UITableViewCell:odd .class1 > .class2:landscape`.

* Set up your view hierarchy and set some initial styles classes on your views. Check out the ***[Using InterfaCSS](https://github.com/tolo/InterfaCSS/wiki/Using-InterfaCSS)*** page on the wiki for more details.

* Update styles as you go - use the methods provided in [`UIView+InterfaCSS.h`](InterfaCSS/UI/UIView+InterfaCSS.h) and [`UIView+InterfaCSS.h`](InterfaCSS/UI/UIView+InterfaCSS.h) to control the styling of your views.

* If you get stuck and starting feel the urge to break something, consider doing this first:
    * Try using `-[InterfaCSS logMatchingStyleDeclarationsForUIElement:]` to log the active style declarations for your view, and see if they are whay you expect them to be.

    * Enable more verbose logging by invoking `[NSObject iss_setLogLevel:ISS_LOG_LEVEL_TRACE];` defined in [`NSObject+ISSLogSupport.h`](InterfaCSS/Util/NSObject+ISSLogSupport.h)



##Project status and background

### Status

With the release of 1.0, InterfaCSS had finally reached the point where the most important stuff was there, and version 1.1 added a bunch of new handy features and fixes, to make InterfaCSS even more complete. But the work with refining the feature set, improving documentation and perfecting unit tests will of course continue.

And of course - all feedback is most welcome!

*"Við munum gera betur næst, þetta er ágætis byrjun"*  


### Background

InterfaCSS emerged out of frustration with the shortcomings of the available Interface Building tools, one of the most important being the constant need to repeat yourself when it comes to styling of user interface elements. There had to be a better way.

And out of that notion sprung the foundation of InterfaCSS, which after a spending a longish time fermenting in dark corners of various applications, finally has made a public appearance. During it's evolution into an open source project, other similar projects have popped up, although InterfaCSS still differs from most of them:

* Property names are what you expect them to be and the list of supported properties is extensive
* Powerful stylesheet syntax (selector chains, selector combinators, pseudo classes, nested declarations) that is based on the familiar CSS language used for the web
* InterfaCSS is not just for styling - it helps you with view setup and layout as well




## Apps using InterfaCSS

* [PlayMyQ HD - Music Player • Remote Control • Jukebox](https://itunes.apple.com/app/playmyq-hd-music-player-remote/id432506056?mt=8)
* [PlayMyQ - Music Player • Remote Control • Jukebox](https://itunes.apple.com/app/playmyq-music-player-remote/id432505283?mt=8)


## License

MIT license - see [here](LICENSE).

<img src="https://raw.githubusercontent.com/tolo/InterfaCSS/master/Resources/InterfaCSS-title-logo.png" alt="InterfaCSS" title="InterfaCSS" width="432">

[![Build Status](https://travis-ci.org/tolo/InterfaCSS.svg?branch=develop)](https://travis-ci.org/tolo/InterfaCSS)


> Everyone loves a beautifully designed app with a consistent UI, and getting there shouldn't take a huge effort. What if there was a way to do ***styling***, ***theming*** and ***layout*** in a concise and powerful way, without constantly having to repeat yourself. What if things could be more like the web?


<img src="https://raw.githubusercontent.com/tolo/InterfaCSS/develop/Resources/InterfaCSS-flexbox-hot-reload.gif" alt="XML Flexbox Hot Reload Demo" title="XML Flexbox Hot Reload Demo" width="720">


## Welcome to InterfaCSS 2 - CSS-based Styling and Layout for iOS

### What is InterfaCSS
:art: Powerful styling, in a familiar format  
:triangular_ruler: Complex layouts made easy, with great readability and maintainability  
:volcano: Hot reload of stylesheets and layouts to speed up development  
:first_quarter_moon: Multiple stylesheet support, which makes theming easier  

### Simple yet powerful styling with CSS
InterfaCSS uses an easy to understand styling [***syntax***](https://github.com/tolo/InterfaCSS/wiki/Stylesheet-format) that is based on the the familiar ***CSS*** styling language 
used on the web (augmented with some *Sass/Less*-like features, such as *nested declarations* and *variables*), which means that you (and your designer) will probably feel right at home. 
InterfaCSS supports a rich selector syntax (*type*, *class* and *element id* selectors, *selector combinators*, *pseudo classes*, etc) and property names are what you expect them to be - 
i.e. the same as in `UIKit`, and you can set things like *fonts, colors, images, transform, insets, offsets, rects, enums* and much, much [***more***](https://github.com/tolo/InterfaCSS/wiki/Stylesheet-Property-Reference).

```css
#helloWorldView .titleLabel {
  font: HelveticaNeue-Light 20;
  text-color: red;
  alpha: 0.75;
  cornerRadius: @numberVariable;
  transform: rotate(90) scale(2, 3);
}
```

### Layouts are expressed in a easy to understand (and HTML-like) way, with support for bindings of elements to properties in a view controller (for instance)
```xml
<layout useSafeAreaInsets="false" useDefaultMargins="true">

  <view class="rootClass">
    <view id="helloWorldView" style="flex-grow:1; flex-direction: column; justify-content: flex-start">
      <label class="titleLabel">Hello world</label>
      <button class="actionButton"/>
    </view>
  </view>

</layout>
```

### Styling is normally contained in stylesheets (css-files)
It can however also be included inline on elements (via the style attribute) or in a within a style tag in the layout. The latter makes it possible to scope view specific 
styling to a particular view, and negates the need for a separate stylesheet for each view. Of course, a well thought through style structure (or design system) 
should require very little view specific styles in most cases, and instead consist of a number of common stylesheets. 
```xml
<layout useSafeAreaInsets="false" useDefaultMargins="true">

  <view class="rootClass">
    <view id="helloWorldView" style="flex-grow:1; flex-direction: column; justify-content: flex-start">
        <label class="titleLabel">Hello world</label>
    </view>
  </view>
  
  <style>
  #helloWorldView .titleLabel {
    font: HelveticaNeue-Light 20;
    text-color: red;
  }
  </style>

</layout>
```

### Hot reload of stylesheets and layouts (for development)
To make development simpler and faster, try using hot reloadable stylesheets and layouts - no more waiting for those frustrating compile/deploy/launch/returnToWhereYouWere-cycles. Note though that this feature is only intended for use during development. See sample code for examples on setting up hot reload support (super easy).


## Sample code
Checking out the sample code is a good way to get a feel for how InterfaCSS is used in an app. To run the sample code, do like this:

* Run `pod install` in the `Samples/<ExampleName>` directory.
* Open `<ExampleName>.xcworkspace`.
* Build and run.

The following examples are available:

* **HelloFlexLayout** - the most simple example of them all, showing extremely basic layout and styling.
* **FlexThatBox** - a simple example showing some basic layout, including autosized table view cells and rotation support.
* **FlexyVistas** - a somewhat more real-app-like example, inspired by the example used in the [Ray Wenderlich Yoga Turorial]([https://www.raywenderlich.com/161413/yoga-tutorial-using-cross-platform-layout-engine).


## Migrating from InterfaCSS 1.X
InterfaCSS 2 is still a work in progress (especially documentation wise) - for now, here is a short list of bigger changes from 1.X:

* Codebase ported to **Swift** 
* The project has been split up into two parts (subspecs): **Core** (containing the most important parts for parsing stylesheets and styling elements) and **Layout** (containing support for defining views/layouts in XML-files - see below)
* The default layout implementation uses **CSS-flexbox** for expressing the layout (the [Facebook Yoga](https://yogalayout.com) engine is used under the hood)
* **Hot reload** during development is supported for both layout files and stylesheets!
* The monolithic main class `InterfaCSS` has now been split up in to several parts (primarily `StylingManager` and `StyleSheetManager`), with a clearer purpose
* The new "main" class is now `StylingManager`
* A protocol for making it easier to work with different scopes of stylesheets have been introduces: `Styler`
* Stylable properties are now (mainly) discovered via runtime introspection, which means that InterfaCSS will easier be able to keep up with changes in UIKit
* More similarities with web CSS, for instance font properties though separate properties (*ongoing work - more will come*)
* New examples demonstrating the use of Flexbox layout (see below)
* And much much more (more and better documentation is coming)...


## Project status and background

### The road to 2.0...
* Better unit testing coverage...
* Even better support for more powerful layouts (action binding, model binding...)
* Documentation, documentation, documentation...
* Covert Core into Swift...

#### ...and beyond... 
* Android version...


### Background

InterfaCSS emerged out of frustration with the shortcomings of the available Interface Building tools, one of the most important being the constant need to repeat yourself when 
it comes to styling of user interface elements. There had to be a better way.

And out of that notion sprung the foundation of InterfaCSS, which after spending a longish time fermenting in dark corners of various applications, finally emerged as an open source 
project, for use by any iOS developers out there that might share the same desires for better stylability and layouts as well as better developer / designer collaboration.    
During it's evolution into an open source project, other similar projects have popped up, although InterfaCSS still differs from most of them:

* Property names are what you expect them to be and the list of supported properties is extensive
* Powerful stylesheet syntax (selector chains, selector combinators, pseudo classes, nested declarations) that is based on the familiar CSS language used for the web
* InterfaCSS is not just for styling - it helps you with view setup and layout as well


## License

MIT license - see [here](LICENSE).

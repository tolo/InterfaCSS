<img src="https://raw.githubusercontent.com/tolo/InterfaCSS/master/Resources/InterfaCSS-title-logo.png" alt="InterfaCSS" title="InterfaCSS" width="432">

[![Build Status](https://travis-ci.org/tolo/InterfaCSS.svg?branch=develop)](https://travis-ci.org/tolo/InterfaCSS)


> Everyone loves a beautifully designed app with a consistent UI, and getting there shouldn't take a huge effort. What if there was a way to do ***styling***, ***theming*** and ***layout*** in a concise and powerful way, without constantly having to repeat yourself. What if things could be more like the web?



## Welcome to InterfaCSS 2 - CSS-based Styling and Layout for iOS

### For now, here's a quick list of changes:

* The project has been split up into two parts (subspecs): **Core** (containing the most important parts for parsing stylesheets and styling elements) and **Layout** (containing support for defining views/layouts in XML-files - see below)
* The default layout implementation uses **CSS-flexbox** for expressing the layout (the [Facebook Yoga](https://yogalayout.com) engine is used under the hood)   
* The monolithic main class `InterfaCSS` has now been split up in to several parts (primarily `ISSStylingManager` and `ISSStyleSheetManager`), with a clearer purpose
* The new "main" class is now `ISSStylingManager`
* A protocol for making it easier to work with different scopes of stylesheets have been introduces: `ISSStyler`
* API is even more swiftified - for instance, ISS-prefix of classes is no longer needed.
* Stylable properties are now (mainly) discovered via runtime introspection, which means that InterfaCSS will easier be able to keep up with changes in UIKit
* A new sample (work in progress) demonstrating the use of Flexbox layout (see below)
* And much much more (more and better documentation is coming)...

### Simple yet powerful styling with CSS
```css
#helloWorldButton {
  attributedText: "Hello " (foregroundColor: yellow), "World" (foregroundColor: #0000ff);
  backgroundColor: "patternImageAsColor.png";
  borderWidth: 3;
  borderColor: fadeout(magenta, 75%);
  cornerRadius: @numberVariable;
  clipsToBounds: YES;
}
```

### Layouts are expressed in a easy to understand (and HTML-like) way, with support for bindings of elements to properties in a view controller (for instance)
```xml
<?xml version="1.0" encoding="UTF-8"?>
<layout useSafeAreaInsets="false" useDefaultMargins="true">

<view id="rootClass">

  <view id="container1" style="flex-grow:1; flex-direction: column; justify-content: flex-start">
    <label id="helloWorldLabel">Hello world 1</label>
    <button id="helloWorldButton" type="custom"/>
  </view>

</view>

<style>
  // Styles unique to this particular view can be defined directly here in the layout file, in a css file 
  // with the same name as the layout file or on individual elements.
  #rootClass {
    flex-direction: column;
    align-items: stretch;
    justify-content: center;
  }
  #rootClass:landscape {
    flex-direction: row;
  }
</style>

</layout>
```


### Sample code
Checking out the sample code is a good way to get a feel for how InterfaCSS is used in an app. To run the sample code, do like this:

* Run `pod install` in the `Samples/FlexLayoutSample` directory.
* Open `FlexLayoutSample.xcworkspace`.
* Build and run.



## License

MIT license - see [here](LICENSE).

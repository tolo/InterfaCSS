<img src="https://raw.githubusercontent.com/tolo/InterfaCSS/master/Resources/InterfaCSS-title-logo.png" alt="InterfaCSS" title="InterfaCSS" width="432">

[![Build Status](https://travis-ci.org/tolo/InterfaCSS.svg?branch=develop)](https://travis-ci.org/tolo/InterfaCSS)


> Everyone loves a beautifully designed app with a consistent UI, and getting there shouldn't take a huge effort. What if there was a way to do ***styling***, ***theming*** and ***layout*** in a concise and powerful way, without constantly having to repeat yourself. What if things could be more like the web?



## Welcome to InterfaCSS 2

### For now, here's a quick list of changes:

* The project has been split up into two parts: **Core** (containing the most important parts for parsing stylesheets and styling elements) and **UI** (when finished, this module, or supspec, will contain stuff related to layout and construction of UI elements etc)
* The monolithic main class `InterfaCSS` has now been split up in to several parts (primarily `ISSStylingManager` and `ISSStyleSheetManager`), with a clearer purpose
* The new "main" class is now `ISSStylingManager`
* Stylable properties are now (mainly) discovered via runtime introspection, which means that InterfaCSS will easier be able to keep up with changes in UIKit
* And more...


## License

MIT license - see [here](LICENSE).

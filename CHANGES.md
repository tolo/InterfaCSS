#Changes


##Version 0.9.10

### New features & changes
* Added support for processing refreshable stylesheets after normal stylesheets (`processRefreshableStylesheetsLast`) 
* Added support for setting interval at which refreshable stylesheets are refreshed (`stylesheetAutoRefreshInterval`) 
* Updated error handing for loading of refreshable stylesheets.
* Added support for registering custom stylesheet properties, by exposing an instance of `ISSPropertyRegistry` through the property `propertyRegistry` in `InterfaCSS`.  

### Bug fixes
* Fixed bug in replacement of unicode escape sequences (`[NSString iss_stringByReplacingUnicodeSequences]`).
 

##Version 0.9.9

### New features & changes
* Swift compatibility fix - added `sharedInstance` class method as a replacement for the `interfaCSS` method.
* Updated InterfaCSS.h to include import statements of the core headers of the InterfaCSS API, to make creating a Swift bridging header simpler.
* Added support for unicode escape sequences (\u0123 and \U00012345) in strings in stylesheets.


##Version 0.9.8

### New features & changes
* Improved handling of transform and anchor point.
* Added support for applying styling only once (applyStylingOnceISS).


##Version 0.9.7

### Bug fixes
* Fixed crash caused by bad handling of `UINavigationItem`.



##Version 0.9.6

### New features & changes
* Updated caching of styles to be more performant.
* Styles are now only applied to a UI element if not already applied, or if there has been a change in stylesheets or style classes etc.
* Slight change in meaning of parameter in method `applyStylingISS:` in `UIView+InterfaCSS` from "clear cached styles" to "force styles to always be applied".
* Added method `clearCachedStylesISS` to `UIView+InterfaCSS` (to compensate for above change).
* Added BOOL return type to add/remove style class methods in `UIView+InterfaCSS`, to indicate success.



##Version 0.9.5

### New features & changes
* Full UIKit enum names (i.e. `UIViewAutoresizingFlexibleWidth`) are now supported alongside short versions (i.e. `width`).
* Added possibility to disable/enable styling for a UI element, using the methods `disableStylingISS` and `enableStylingISS` in `UIView+InterfaCSS`.

### Bug fixes
* Fixed issue with preventOverwriteOfAttributedTextAttributes flag not checking the presence of attributed text correctly.
* Updated supported enum values for `lineBreakMode` to be more in line with `NSLineBreakMode` enum type (i.e. added `wordWrapping`, `charWrapping`, `clipping`, `truncatingHead`, `truncatingTail`, `truncatingMiddle`).



##Version 0.9.4

### New features & changes
* Added support to `UIView+InterfaCSS` for getting notified when styles will be and have been applied for a view, via blocks (`willApplyStylingBlockISS` & `didApplyStylingBlockISS).
* Added flag useLenientSelectorParsing to class InterfaCSS, to allow for more lenient parsing of style class names (i.e. allow missing dot).
* When autoresizingMask is set, the frame property will also be set to the superview bound or the screen bound if empty.



##Version 0.9.3

### Bug fixes
* Fixed issue with image parsing using the `image("xxx")` format.



##Version 0.9.2

### New features & changes
* The order of property declarations is now maintained when parsing a stylesheet file.
* Property values are now lazily transformed from strings to actual values, to speed up loading of stylesheet.
* Added flag preventOverwriteOfAttributedTextAttributes to make it possible to prevent "overwriting" of font and text color in attributed text of labels (and buttons).

### Bug fixes
* Fixed issue with underscore not being allowed as a character in identifiers in stylesheets.
* Fixes problem with color and image values not being parsed correctly in some instances.



##Version 0.9.1

### Bug fixes

* Fixed problem with wildcard selectors not being recognized properly.
* Fixed ordering issue with nested declarations in stylesheets.
* Fixed problem with parsing font sizes with only one digit.
* Fixed issue with quoted string property values containing control characters.
* Fixed broken cancellation of delayed calls to `applyStyling:` and `applyStylingWithAnimation:`.
* Prevented possibility of recursive invocations to applyStyling for the same view from occuring.
* Added missing builder method for `UIActivityIndicatorView` to `ISSViewBuilder`.
* Fixed issue with prefixed properties "overwriting" properties with same (unprefixed) property name.
* Fixed issue with width being used instead of height for inset rects.
* Fixed issue where style class replaced existing style classes instead of appending to them.
* Re-styling of `ISSRootView` is now also scheduled when view moves to window.



##Version 0.9.0

### New features & changes
* Added support for child, adjacent sibling and general sibling selector combinators.
* Added support for pseudo classes:
	* Interface orientation: (`landscape, landscapeLeft, landscapeRight, portrait, portraitUpright, portraitUpSideDown`)
	* Component state: (`enabled, disabled`)
	* Structural (`nthchild, nthlastchild, onlychild, firstchild, lastchild, nthoftype, nthlastofyype, onlyoftype, firstoftype, lastoftype, empty`)
* Stylesheet variables are now global (i.e. can be reused in multiple stylesheets).
* Stylesheet variables can now be accessed and manipulated in code, using methods in class InterfaCSS.
* Added suffix/prefix to all category methods (methods `UIView+InterfaCSS.h` now all have a "ISS" suffix).
* Added new boolean attribute `add` to elements in view definition file, to enable/disable adding as subview to parent (default YES).
* Added support for logging active styles for a view (`-[InterfaCSS logMatchingStyleDeclarationsForUIElement:]`).

### Bug fixes

* Fixed problem with automatic height in `ISSRectValue` (i.e. size(123, auto)).
* Fixed problems with matching types for view classes (`ISSSelector`).
* Fixed caching issue with enum properties.

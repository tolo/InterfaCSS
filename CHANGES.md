#Changes


##Version 1.2

### New features & changes
* Added support for properties leftViewMode and rightViewMode in UITextField. Also added leftView and rightView as valid property prefix key paths. 
* Added support for using swift classes as custom type selectors and custom elements in view definition files.
* Added better control over how refreshable stylesheets are handled (added methods for manually reloading stylesheets etc).
* Added support for starting and stopping animation of a UIActivityIndicatorView via the "animating" property.
* Added support for nesting variables, i.e. referring to other variables in variable declarations. 
* Updated minimum required iOS version to iOS7. 
* Added pseudo classes `minOSVersion` , `maxOSVersion`, `deviceModel`, `screenWidth`, `screenWidthLessThan`, `screenWidthGreaterThan`, `screenHeight`, `screenHeightLessThan` and `screenHeightGreaterThan`.
* Added support for remote loading (via http/https URLs) of fonts and images (resolves [issue 21](https://github.com/tolo/InterfaCSS/issues/21), requested by @tbrannam).
* Added support for using InterfaCSS in tvOS apps (resolves [issue 44](https://github.com/tolo/InterfaCSS/issues/44), requested by @tbrannam).  

### Bug fixes
* Fixed issue in ISSLayout with auto width/height, and also an issue with how layout guide values are calculated.



##Version 1.1.1

### Bug fixes
* Removed incorrect warning logging in view definition file parser (ISSViewHierarchyParser).  
* Fixed error in ISSLayout with how width/height was calculated when using simultaneous left & right / top & bottom attributes.   



##Version 1.1

### New features & changes
* Added support for scoping stylesheets to specific view controllers (for instance).
* Added support for string localization, by using the format L("string") or localized("string").
* Made styleClassISS property `IBInspectable`.
* Performance updates related to styling.
* Added support for W3C style selector specificity for determining the order in which style declarations should be processed. This feature can be enabled using the flag `useSelectorSpecificity`.
* Added pseudo class `root`, which matches if an element is the root view of a view controller.
* Added support for overriding and/or extending already registered property definitions ([issue 28](https://github.com/tolo/InterfaCSS/issues/28), requested by @tbrannam). Also added new property setter block type (`ISSPropertySetterBlock`) that returns a `BOOL`, and deprecated the old one (without the ISS prefix).
* Added support for "selected" and "highlighted" pseudo class selectors ([issue 32](https://github.com/tolo/InterfaCSS/issues/36), requested by @tbrannam).
* Added support for using mathematical expressions in most places where numbers are used in stylesheets ([issue 35](https://github.com/tolo/InterfaCSS/issues/35), requested by @TadeasKriz).
* Added support for using custom types as selectors ([issue 36](https://github.com/tolo/InterfaCSS/issues/36), requested by @TadeasKriz).
* Added support for shorthand versions of type creators in stylesheets, i.e. making it possible to use fewer arguments ([issue 37](https://github.com/tolo/InterfaCSS/issues/37), requested by @TadeasKriz). Also added support for making "function" prefix (i.e. `point` etc) optional, and making it possible to just use the argument list directly (i.e. `10, 20`).
* Added support for using file monitoring instead of polling, when using auto reloadable stylesheets on the local filesystem ([issue 38](https://github.com/tolo/InterfaCSS/issues/38), requested by @TadeasKriz).
* Added support for using view controller classes as type selectors ([issue 42](https://github.com/tolo/InterfaCSS/issues/42), requested by @TadeasKriz).

### Bug fixes
* Fixed issue with using InterfaCSS in an extension target ([issue 33](https://github.com/tolo/InterfaCSS/issues/33), reported by @killobatt).
* Changed the way how setting properties on nested elements (via prefix key paths) in stylesheets works, primarily to solve the problem with this not working in all cases. Resolves issue [issue 39](https://github.com/tolo/InterfaCSS/issues/39), reported by @TadeasKriz.
* Added support to use introspection for getting setter method for property, as an alternative to using KVC for setting property values. This resolves [issue 43](https://github.com/tolo/InterfaCSS/issues/43), reported by @TadeasKriz (problem with setting properties defined in UITextInputTraits).



##Version 1.0.1

### Bug fixes
* Added fix for incorrect import of Parcoa header file ([issue 34](https://github.com/tolo/InterfaCSS/issues/34), reported by @TadeasKriz).


##Version 1.0.0

### New features & changes
* Added ISSLayout - a lightweight and flexible layout system.
* Added HelloISSLayout sample code.
* Updated ISSViewBuilder with methods that take elementId parameter.

### Bug fixes
* Fixed rotation issue in sample code ([issue 24](https://github.com/tolo/InterfaCSS/issues/24), reported by @tbrannam).
* Merged fix for `nthlastoftype` pseudo class name ([issue 25](https://github.com/tolo/InterfaCSS/issues/25), reported by @tbrannam).
* Merged fix missing support for `UITabBar` when calculating type qualified position in parent ([issue 26](https://github.com/tolo/InterfaCSS/issues/26), added by @tbrannam).
* Added support for use of color functions and named colors in gradients ([issue 29](https://github.com/tolo/InterfaCSS/issues/29), reported by @tbrannam).
* Fixed issues with ISSPropertyTypeNumber not supporting negative numbers ([issue 30](https://github.com/tolo/InterfaCSS/issues/30), reported by @tbrannam).


##Version 0.9.13

### New features & changes
* Added support for specifying the collection view layout class (via the `layoutClass` attribute) when creating collection views in a view definition file (fixes [issue 10](https://github.com/tolo/InterfaCSS/issues/10), reported by @tbrannam).
* Added method `elementNameToViewClass` to `ISSViewHierarchyParser`, to make it possible for subclasses to override mapping of tag name to view class.
* Added support for horizontal and vertical centering of rect values, by using the value `auto` in insets (e.g. left(auto).right(auto)`).
* Added pseudo classes for user interface idiom (`pad` & `phone`) and size classes (`regularWidth`, `compactWidth`, `regularHeight`, `compactHeight`) (fixes [issue 18](https://github.com/tolo/InterfaCSS/issues/18), reported by @tbrannam).
* Added support for chaining pseudo classes (fixes [issue 18](https://github.com/tolo/InterfaCSS/issues/18), reported by @tbrannam).
* Simplified handling of view related styling data (ISSUIElementDetails) by using associated objects.

### Bug fixes
* Fixed issue with parsing of CGColor values, when using color functions.
* Merged fix for incorrect parsing of font names with spaces ([issue 22](https://github.com/tolo/InterfaCSS/issues/22)) added by @tbrannam.


##Version 0.9.12

### New features & changes
* Added support for attributed string properties (`attributedText` in `UILabel`, `UITextField` and `UITextView`, and `attributedTitle` in `UIButton`).
* Added support for opting out of scheduled styling when adding and removing style classes (via `UIView (InterfaCSS)` category).
* Updates to xml view definition file parsing (ISSViewHierarchyParser):
    * Added support for `impl` attribute for specifying a custom implementation class.
    * Added support for registering (the iOS6 way) UITableViewCell and UICollectionViewCell classes in the parent UITableView/UICollectionView.
* Added support for associating a view with an element identifier, both though`UIView+InterfaCSS` and the xml view definition file (`id` attribute).
* Added support for setting properties on `UICollectionViewFlowLayout`.
* Added support for "scoping" prototypes under a specific view, instead of always being defined on a global level. Also added support for using the attribute `propertyScope` (valid values are `parent` or `global`) in view definition files.
* Added protocol `ISSViewHierarchyParserDelegate`, to support post processing of view defined in a view definition file (fixes [issue 12](https://github.com/tolo/InterfaCSS/issues/12), reported by @tbrannam).
* Added method to register a ISSPropertyDefinition directly to ISSPropertyRegistry.
* Added support for variable substitution when doing manual property value transformation (i.e. for instance using `-[InterfaCSS transformedValueOfStyleSheetVariableWithName:asPropertyType:]` or `-[ISSStyleSheetParser transformValue:asPropertyType:]`). Fixes [issue 17](https://github.com/tolo/InterfaCSS/issues/17), reported by @tbrannam.

### Bug fixes
* Fixed problem with using multiple constants within the same property value.
* Reduction of excessive cleanup of caches.
* Added fix for issue with view definition file prototypes ([issue 5](https://github.com/tolo/InterfaCSS/issues/5), reported by @tbrannam) - prototype child elements can now be assigned to property in any ancestor element.
* Merged fix for use of incorrect setters for property `attributedTitle` ([issue 4](https://github.com/tolo/InterfaCSS/issues/4)), added by @tbrannam.
* Added support for properly handling custom UITableViewCell/UICollectionViewCell subclasses in ISSViewHierarchyParser ([issue 7](https://github.com/tolo/InterfaCSS/issues/7)).
* Fixed issue with prototype views having a global namespace ([issue 8](https://github.com/tolo/InterfaCSS/issues/8), reported by @tbrannam)
* Added fix for issue with custom enumerated property definition ([issue 16](https://github.com/tolo/InterfaCSS/issues/16), reported by @tbrannam)


##Version 0.9.11

### Bug fixes
* Fixed caching issues, partially related to custom styling identities.


##Version 0.9.10

### New features & changes
* Added support for processing refreshable stylesheets after normal stylesheets (`processRefreshableStylesheetsLast`)
* Added support for setting interval at which refreshable stylesheets are refreshed (`stylesheetAutoRefreshInterval`)
* Updated error handing for loading of refreshable stylesheets.
* Added support for registering custom stylesheet properties, by exposing an instance of `ISSPropertyRegistry` through the property `propertyRegistry` in `InterfaCSS`.
* Updated handling of data associated with styled elements to make it more robust (and to workaround issue when styling SpriteKit nodes: http://openradar.io/18494241).
* Added support for `current` "keyword" in stylesheets. When this keyword is used as a property value, any existing runtime value for a specific property will remain.
* Added support for disabling styling of specific properties in a UI element (in class `InterfaCSS` and through category `UIView+InterfaCSS.h`).

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

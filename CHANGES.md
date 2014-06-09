#Changes


##Version 0.9.2 (yet to be released)

### New features & changes
* The order of property declarations is now maintained when parsing a stylesheet file.
* Property values are now lazily transformed from strings to actual values.
* Added flag preventOverwriteOfAttributedTextAttributes to make it possible to prevent "overwriting" of font and text color in attributed text of labels (and buttons).

### Bug fixes
* Fixed issue with underscore not being allowed as a character in identifiers in stylesheets.
* Fixes problem with color and image values not being parsed correctly in some instances.



##Version 0.9.1

### Bug fixes

* Fixed problem with wildcard selectors not being recognized properly.
* Fixed ordering issue with nested declarations in stylesheets.
* Fixed problem with parsing font sizes with only one digit.
* Fixed issue with quoted string propery values containing control characters.
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

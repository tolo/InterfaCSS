#Changes

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

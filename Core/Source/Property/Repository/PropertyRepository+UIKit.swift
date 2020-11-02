//
//  PropertyRepository+UIKit.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

import UIKit
import Parsicle


extension PropertyRepository {
  
  private static let controlStateParametersValues: [String: UIControl.State] = [
    "normal": .normal, "focused": .focused, "highlighted": .highlighted,
    "selected": .selected, "disabled": .disabled]
  static let controlStateMapping = PropertyBitMaskEnumValueMapping(enumValues: controlStateParametersValues, enumBaseName: "UIControlState", defaultValue: .normal)
  static let controlStateTransformer: PropertyParameterTransformer = { return controlStateMapping.enumValue(from: $0) }
  
  // MARK: - Registration utility methods
  
  func _register(_ name: String, inClasses classes: [AnyClass], type: PropertyType, enums enumValueMapping: AnyPropertyEnumValueMappingType? = nil) {
    for clazz in classes {
      _register(name, in: clazz, type: type, enums: enumValueMapping)
    }
  }
  
  @discardableResult
  func _register(_ name: String, in clazz: AnyClass, type: PropertyType, enums enumValueMapping: AnyPropertyEnumValueMappingType? = nil) -> Property? {
    guard let runtimeProperty = RuntimeIntrospectionUtils.runtimeProperty(withName: name, in: clazz, lowercasedNames: true) else {
      error(.properties, "Cannot register '\(name)' in '\(clazz)'")
      return nil
    }
    return register(Property(runtimeProperty: runtimeProperty, type: type, enumValueMapping: enumValueMapping))
  }
  
  @discardableResult
  func _register(_ name: String, in clazz: AnyClass, type: PropertyType, selector: Foundation.Selector, params parameterTransformers: [PropertyParameterTransformer]) -> Property {
    return register(Property(withName: name, in: clazz, type: type, selector: selector, enumValueMapping: nil, parameterTransformers: parameterTransformers))
  }
  
  @discardableResult
  func _register(_ name: String, in clazz: AnyClass, type: PropertyType, selector: Foundation.Selector, params parameterMappers: [AnyPropertyEnumValueMappingType]) -> Property {
    let parameterTransformers: [PropertyParameterTransformer] = parameterMappers.map { mapper in
      { value in return mapper.value(from: value) }
    }
    return register(Property(withName: name, in: clazz, type: type, selector: selector, enumValueMapping: nil, parameterTransformers: parameterTransformers))
  }
  
  @discardableResult
  //func _register<TargetType, ValueType>(_ name: String, in clazz: TargetType.Type, type: PropertyType, typedSetter: @escaping TypedNeverFailingPropertySetterBlock<TargetType, ValueType>) -> Property {
  func _register<TargetType: UIResponder, ValueType>(_ name: String, in clazz: TargetType.Type, type: PropertyType, typedSetter: @escaping TypedNeverFailingPropertySetterBlock<TargetType, ValueType>) -> Property {
    return register(Property(withName: name, in: clazz, type: type, setterBlock: typedSetter))
  }
  
  
  // MARK: - Register defaults
  
  func registerDefaultUIKitProperties() {
    let contentModeMappingValues: [String: UIView.ContentMode] = [
      "scaletofill": .scaleToFill, "scaleaspectfit": .scaleAspectFit, "scaleaspectfill": .scaleAspectFill,
      "redraw": .redraw, "center": .center, "top": .top, "bottom": .bottom,
      "left": .left, "right": .right, "topleft": .topLeft, "topright": .topRight,
      "bottomleft": .bottomLeft, "bottomright": .bottomRight
    ]
    let contentModeMapping = PropertyEnumValueMapping(enumValues: contentModeMappingValues, enumBaseName: "UIViewContentMode", defaultValue: .scaleToFill)
    
    let viewAutoresizingMapping = PropertyBitMaskEnumValueMapping<UIView.AutoresizingMask>(enumValues: [
      "none": [], "width": .flexibleWidth, "flexibleWidth": .flexibleWidth, "height": .flexibleHeight, "flexibleHeight": .flexibleHeight,
      "bottom": .flexibleBottomMargin, "flexibleBottomMargin": .flexibleBottomMargin, "top": .flexibleTopMargin, "flexibleTopMargin": .flexibleTopMargin,
      "left": .flexibleLeftMargin, "flexibleLeftMargin": .flexibleLeftMargin, "right": .flexibleRightMargin, "flexibleRightMargin": .flexibleRightMargin
    ], enumBaseName: "UIViewAutoresizing", defaultValue: [])
    
    let tintAdjustmentModeMapping = PropertyEnumValueMapping<UIView.TintAdjustmentMode>(enumValues: [
      "automatic": .automatic, "normal": .normal, "dimmed": .dimmed], enumBaseName: "UIViewTintAdjustmentMode", defaultValue: .automatic)
    
    let barMetricsMapping = PropertyEnumValueMapping<UIBarMetrics>(enumValues: [
      "default": .default, "landscapePhone": .compact, "compact": .compact, "landscapePhonePrompt": .compactPrompt,
      "compactPrompt": .compactPrompt, "defaultPrompt": .defaultPrompt,
    ], enumBaseName: "UIBarMetrics", defaultValue: .default)
    
    let barPositionMapping = PropertyEnumValueMapping<UIBarPosition>(enumValues: [
      "any": .any, "bottom": .bottom, "top": .top, "topAttached": .topAttached
    ], enumBaseName: "UIBarPosition", defaultValue: .any)
    
    let segmentTypeMapping = PropertyEnumValueMapping<UISegmentedControl.Segment>(enumValues: [
      "any": .any, "left": .left, "center": .center, "right": .right, "alone": .alone
    ], enumBaseName: "UISegmentedControlSegment", defaultValue: .any)
    
    #if os(iOS)
    let dataDetectorTypesMapping = PropertyEnumValueMapping<UIDataDetectorTypes>(enumValues: [
      "all": .all, "none": [], "address": .address, "calendarEvent": .calendarEvent, "link": .link, "phoneNumber": .phoneNumber
    ], enumBaseName: "UIDataDetectorType", defaultValue: [])
    #endif
    
    let textAlignmentMapping = PropertyEnumValueMapping<NSTextAlignment>(enumValues: [
      "left": .left, "center": .center, "right": .right
    ], enumBaseName: "NSTextAlignment", defaultValue: .left)
    
    let viewModeMapping = PropertyEnumValueMapping<UITextField.ViewMode>(enumValues: [
      "never": .never, "always": .always, "unlessEditing": .unlessEditing, "whileEditing": .whileEditing
    ], enumBaseName: "UITextFieldViewMode", defaultValue: .never)
    
    
    let searchBarIconParameters: [String: UISearchBar.Icon]
    #if os(iOS)
    let barStyleMapping = PropertyEnumValueMapping<UIBarStyle>(enumValues: [
      "default": .default, "black": .black, "blackOpaque": .blackOpaque, "blackTranslucent": .blackTranslucent
    ], enumBaseName: "UIBarStyle", defaultValue: .default)
    let accessoryTypeMapping = PropertyEnumValueMapping<UITableViewCell.AccessoryType>(enumValues: [
      "none": .none, "checkmark": .checkmark, "detailButton": .detailButton, "disclosureButton": .detailDisclosureButton, "disclosureIndicator": .disclosureIndicator
    ], enumBaseName: "UITableViewCellAccessory", defaultValue: .none)
    searchBarIconParameters = ["bookmark": .bookmark, "clear": .clear, "resultsList": .resultsList, "search": .search]
    #else
    searchBarIconParameters = ["search": .search]
    #endif
    
    let searchBarIconMapping = PropertyEnumValueMapping(enumValues: searchBarIconParameters, enumBaseName: "UISearchBarIcon", defaultValue: .search)
    let barMetricsTransformer: PropertyParameterTransformer = { barMetricsMapping.enumValue(from: $0) }
    let barPositionTransformer: PropertyParameterTransformer = { barPositionMapping.enumValue(from: $0) }
    let integerTransformer: PropertyParameterTransformer = { Int($0) ?? 0 }
    //let segmentTypeTransformer: PropertyParameterTransformer = { segmentTypeMapping.enumValue(from: $0) }
    let searchBarIconTransformer: PropertyParameterTransformer = { searchBarIconMapping.enumValue(from: $0) }
    
    //* UIView *//
    var clazz: AnyClass = UIView.self
    _register("backgroundColor", in: clazz, type: .color) // backgroundColor is missing type in runtime, due to declaration in category ( UIView(UIViewRendering) )
    _register("autoresizingMask", in: clazz, type: .enumType, enums: viewAutoresizingMapping)
    _register("contentMode", in: clazz, type: .enumType, enums: contentModeMapping)
    _register("tintAdjustmentMode", in: clazz, type: .enumType, enums: tintAdjustmentModeMapping)
    _register("tintColor", in: clazz, type: .color) // tintColor is missing type in runtime, due to declaration in category ( UIView(UIViewRendering) )
    // TODO: Remove
    //    _register("layer.cornerRadius", in: UIView.self, type: .number) { (_, view, value: CGFloat, _ ) in
    //      view.layer.borderWidth = value
    //    }
    //    _register("layer.borderWidth", in: UIView.self, type: .number) { (_, view, value: CGFloat, _ ) in
    //      view.layer.borderWidth = value
    //    }
    
    //* UIControl *//
    clazz = UIControl.self
    _register("contentVerticalAlignment", in: clazz, type: .enumType, enums: PropertyEnumValueMapping<UIControl.ContentVerticalAlignment>(enumValues: [
      "center": .center, "top": .top, "bottom": .bottom, "fill": .fill
    ], enumBaseName: "UIControlContentVerticalAlignment", defaultValue: .top))
    _register("contentHorizontalAlignment", in: clazz, type: .enumType, enums: PropertyEnumValueMapping<UIControl.ContentHorizontalAlignment>(enumValues: [
      "center": .center, "left": .left, "right": .right, "fill": .fill
    ], enumBaseName: "UIControlContentHorizontalAlignment", defaultValue: .center))
    
    //* UIButton *//
    clazz = UIButton.self
    _register("attributedTitle", in: clazz, type: .string, selector: #selector(UIButton.setAttributedTitle(_:for:)), params: [Self.controlStateMapping])
    _register("backgroundImage", in: clazz, type: .image, selector: #selector(UIButton.setBackgroundImage(_:for:)), params: [Self.controlStateMapping])
    _register("image", in: clazz, type: .image, selector: #selector(UIButton.setImage(_:for:)), params: [Self.controlStateMapping])
    _register("title", in: clazz, type: .string, selector: #selector(UIButton.setTitle(_:for:)), params: [Self.controlStateMapping])
    _register("titleColor", in: clazz, type: .color, selector: #selector(UIButton.setTitleColor(_:for:)), params: [Self.controlStateMapping])
    _register("titleShadowColor", in: clazz, type: .color, selector: #selector(UIButton.setTitleShadowColor(_:for:)), params: [Self.controlStateMapping])
    
    //* UILabel *//
    clazz = UILabel.self
    _register("baselineAdjustment", in: clazz, type: .enumType, enums: PropertyEnumValueMapping<UIBaselineAdjustment>(enumValues: [
      "none": .none, "alignBaselines": .alignBaselines, "alignCenters": .alignCenters
    ], enumBaseName: "UIBaselineAdjustment", defaultValue: .none))
    _register("lineBreakMode", in: clazz, type: .enumType, enums: PropertyEnumValueMapping<NSLineBreakMode>(enumValues: [
      "wordWrap": .byWordWrapping, "wordWrapping": .byWordWrapping, "charWrap": .byCharWrapping, "charWrapping": .byCharWrapping,
      "clip": .byClipping, "clipping": .byClipping, "truncateHead": .byTruncatingHead, "truncatingHead": .byTruncatingHead,
      "truncateTail": .byTruncatingTail, "truncatingTail": .byTruncatingTail, "truncateMiddle": .byTruncatingMiddle, "truncatingMiddle": .byTruncatingMiddle,
    ], enumBaseName: "NSLineBreakBy", defaultValue: .byTruncatingTail))
    _register("textAlignment", in: clazz, type: .enumType, enums: textAlignmentMapping)
    
    //* UISegmentedControl *//
    clazz = UISegmentedControl.self
    _register("backgroundImage", in: clazz, type: .image, selector: #selector(UISegmentedControl.setBackgroundImage(_:for:barMetrics:)), params: [Self.controlStateMapping, barMetricsMapping])
    _register("contentPositionAdjustment", in: clazz, type: .offset, selector: #selector(UISegmentedControl.setContentPositionAdjustment(_:forSegmentType:barMetrics:)), params: [segmentTypeMapping, barMetricsMapping])
    _register("contentOffset", in: clazz, type: .offset, selector: #selector(UISegmentedControl.setContentOffset(_:forSegmentAt:)), params: [integerTransformer])
    _register("dividerImage", in: clazz, type: .image, selector: #selector(UISegmentedControl.setDividerImage(_:forLeftSegmentState:rightSegmentState:barMetrics:)), params: [
      Self.controlStateTransformer, Self.controlStateTransformer, barMetricsTransformer
    ])
    _register("enabled", in: clazz, type: .bool, selector: #selector(UISegmentedControl.setEnabled(_:forSegmentAt:)), params: [integerTransformer])
    _register("image", in: clazz, type: .image, selector: #selector(UISegmentedControl.setImage(_:forSegmentAt:)), params: [integerTransformer])
    _register("title", in: clazz, type: .string, selector: #selector(UISegmentedControl.setTitle(_:forSegmentAt:)), params: [integerTransformer])
    _register("titleTextAttributes", in: clazz, type: .textAttributes, selector: #selector(UISegmentedControl.setTitleTextAttributes(_:for:)), params: [Self.controlStateTransformer])
    _register("width", in: clazz, type: .number, selector: #selector(UISegmentedControl.setWidth(_:forSegmentAt:)), params: [integerTransformer])
    
    #if os(iOS)
    //* UISlider *//
    clazz = UISlider.self
    _register("maximumTrackImage", in: clazz, type: .image, selector: #selector(UISlider.setMaximumTrackImage(_:for:)), params: [Self.controlStateTransformer])
    _register("minimumTrackImage", in: clazz, type: .image, selector: #selector(UISlider.setMinimumTrackImage(_:for:)), params: [Self.controlStateTransformer])
    _register("thumbImage", in: clazz, type: .image, selector: #selector(UISlider.setThumbImage(_:for:)), params: [Self.controlStateTransformer])
    
    //* UIStepper *//
    clazz = UIStepper.self
    _register("backgroundImage", in: clazz, type: .image, selector: #selector(UIStepper.setBackgroundImage(_:for:)), params: [Self.controlStateTransformer])
    _register("decrementImage", in: clazz, type: .image, selector: #selector(UIStepper.setDecrementImage(_:for:)), params: [Self.controlStateTransformer])
    _register("dividerImage", in: clazz, type: .image, selector: #selector(UIStepper.setDividerImage(_:forLeftSegmentState:rightSegmentState:)), params: [Self.controlStateTransformer, Self.controlStateTransformer])
    _register("incrementImage", in: clazz, type: .image, selector: #selector(UIStepper.setIncrementImage(_:for:)), params: [Self.controlStateTransformer])
    #endif
    
    //* UIActivityIndicatorView *//
    clazz = UIActivityIndicatorView.self
    #if os(tvOS)
    let activityIndicatorViewStyleValues: [String: UIActivityIndicatorView.Style] = ["white": .white, "whiteLarge": .whiteLarge]
    #else
    let activityIndicatorViewStyleValues: [String: UIActivityIndicatorView.Style] = ["gray": .gray, "white": .white, "whiteLarge": .whiteLarge]
    #endif
    _register("activityIndicatorViewStyle", in: clazz, type: .enumType, enums: PropertyEnumValueMapping(enumValues: activityIndicatorViewStyleValues,
                                                                                                        enumBaseName: "UIActivityIndicatorViewStyle", defaultValue: .white))
    _register("animating", in: UIActivityIndicatorView.self, type: .bool) { (_, target, value: Bool, _) in
      value ? target.startAnimating() : target.stopAnimating()
    }
    
    //* UIProgressView *//
    clazz = UIProgressView.self
    #if os(iOS)
    _register("progressViewStyle", in: clazz, type: .enumType, enums: PropertyEnumValueMapping<UIProgressView.Style>(enumValues: [
      "default": .default, "bar": .bar
    ], enumBaseName: "UIProgressViewStyle", defaultValue: .default))
    #endif
    
    //* UITextField *//
    clazz = UITextField.self
    _register("borderStyle", in: clazz, type: .enumType, enums: PropertyEnumValueMapping<UITextField.BorderStyle>(enumValues: [
      "none": .none, "bezel": .bezel, "line": .line, "roundedRect": .roundedRect
    ], enumBaseName: "UITextBorderStyle", defaultValue: .none))
    _register("defaultTextAttributes", in: clazz, type: .textAttributes, enums: nil)
    _register("leftViewMode", in: clazz, type: .enumType, enums: viewModeMapping)
    _register("rightViewMode", in: clazz, type: .enumType, enums: viewModeMapping)
    _register("textAlignment", in: clazz, type: .enumType, enums: textAlignmentMapping)
    
    //* UITextView *//
    clazz = UITextView.self
    #if os(iOS)
    _register("dataDetectorTypes", in: clazz, type: .enumType, enums: dataDetectorTypesMapping)
    #endif
    _register("linkTextAttributes", in: clazz, type: .textAttributes, enums: nil)
    _register("textAlignment", in: clazz, type: .enumType, enums: textAlignmentMapping)
    _register("typingAttributes", in: clazz, type: .textAttributes, enums: nil)
    
    //* UIScrollView *//
    clazz = UIScrollView.self
    _register("indicatorStyle", in: clazz, type: .enumType, enums: PropertyEnumValueMapping<UIScrollView.IndicatorStyle>(enumValues: [
      "default": .default, "black": .black, "white": .white,
    ], enumBaseName: "UIScrollViewIndicatorStyle", defaultValue: .default))
    _register("decelerationRate", in: clazz, type: .enumType, enums: PropertyEnumValueMapping<UIScrollView.DecelerationRate>(enumValues: [
      "normal": .normal, "fast": .fast
    ], enumBaseName: "UIScrollViewDecelerationRate", defaultValue: .normal))
    _register("keyboardDismissMode", in: clazz, type: .enumType, enums: PropertyEnumValueMapping<UIScrollView.KeyboardDismissMode>(enumValues: [
      "none": .none, "onDrag": .onDrag, "interactive": .interactive
    ], enumBaseName: "UIScrollViewKeyboardDismissMode", defaultValue: .none))
    
    //* UITableView *//
    clazz = UITableView.self
    #if os(iOS)
    _register("separatorStyle", in: clazz, type: .enumType, enums: PropertyEnumValueMapping<UITableViewCell.SeparatorStyle>(enumValues: [
      "none": .none, "singleLine": .singleLine
    ], enumBaseName: "UITableViewCellSeparatorStyle", defaultValue: .none))
    #endif
    
    //* UITableViewCell *//
    clazz = UITableViewCell.self
    _register("selectionStyle", in: clazz, type: .enumType, enums: PropertyEnumValueMapping<UITableViewCell.SelectionStyle>(enumValues: [
      "none": .none, "default": .default, "blue": .blue, "gray": .gray,
    ], enumBaseName: "UITableViewCellSelectionStyle", defaultValue: .none))
    _register("editingStyle", in: clazz, type: .enumType, enums: PropertyEnumValueMapping<UITableViewCell.EditingStyle>(enumValues: [
      "none": .none, "delete": .delete, "insert": .insert,
    ], enumBaseName: "UITableViewCellEditingStyle", defaultValue: .none))
    #if os(iOS)
    _register("accessoryType", in: clazz, type: .enumType, enums: accessoryTypeMapping)
    _register("editingAccessoryType", in: clazz, type: .enumType, enums: accessoryTypeMapping)
    #endif
    
    //* UIWebView *//
    //    #if os(iOS)
    //    clazz = UIWebView.self
    //    _register("dataDetectorTypes", in: clazz, type: .enumType, enums: dataDetectorTypesMapping)
    //    _register("paginationMode", in: clazz, type: .enumType, enums: PropertyEnumValueMapping<UIWebView.PaginationMode>(enumValues: [
    //      "unpaginated": .unpaginated, "lefttoright": .leftToRight, "toptobottom": .topToBottom, "bottomtotop": .bottomToTop, "righttoleft": .rightToLeft
    //      ], enumBaseName: "UIWebPaginationMode", defaultValue: .unpaginated))
    //    _register("paginationBreakingMode", in: clazz, type: .enumType, enums: PropertyEnumValueMapping<UIWebView.PaginationBreakingMode>(enumValues: [
    //      "page": .page, "column": .column
    //      ], enumBaseName: "UIWebPaginationBreakingMode", defaultValue: .page))
    //    #endif
    
    //* UIBarItem *//
    clazz = UIBarItem.self
    _register("titleTextAttributes", in: clazz, type: .textAttributes, selector: #selector(UIBarItem.setTitleTextAttributes(_:for:)), params: [Self.controlStateTransformer])
    
    //* UIBarButtonItem *//
    clazz = UIBarButtonItem.self
    //setBackgroundImage:forState:style:barMetrics:
    _register("backButtonBackgroundImage", in: clazz, type: .image, selector: #selector(UIBarButtonItem.setBackButtonBackgroundImage(_:for:barMetrics:)), params: [Self.controlStateTransformer, barMetricsTransformer])
    _register("backButtonBackgroundVerticalPositionAdjustment", in: clazz, type: .number, selector: #selector(UIBarButtonItem.setBackButtonBackgroundVerticalPositionAdjustment(_:for:)), params: [barMetricsTransformer])
    _register("backgroundImage", in: clazz, type: .image, selector: #selector(UIBarButtonItem.setBackgroundImage(_:for:barMetrics:)), params: [Self.controlStateTransformer, barMetricsTransformer])
    _register("backgroundVerticalPositionAdjustment", in: clazz, type: .number, selector: #selector(UIBarButtonItem.setBackgroundVerticalPositionAdjustment(_:for:)), params: [barMetricsTransformer])
    _register("backButtonTitlePositionAdjustment", in: clazz, type: .offset, selector: #selector(UIBarButtonItem.setBackButtonTitlePositionAdjustment(_:for:)), params: [barMetricsTransformer])
    _register("style", in: clazz, type: .enumType, enums: PropertyEnumValueMapping<UIBarButtonItem.Style>(enumValues: [
      "plain": .plain, "done": .done
    ], enumBaseName: "UIBarButtonItemStyle", defaultValue: .plain))
    _register("titlePositionAdjustment", in: clazz, type: .offset, selector: #selector(UIBarButtonItem.setTitlePositionAdjustment(_:for:)), params: [barMetricsTransformer])
    
    //* UISearchBar *//
    clazz = UISearchBar.self
    _register("backgroundImage", in: clazz, type: .image, selector: #selector(UISearchBar.setBackgroundImage(_:for:barMetrics:)), params: [barPositionTransformer, barMetricsTransformer])
    #if os(iOS)
    _register("barStyle", in: clazz, type: .enumType, enums: barStyleMapping)
    #endif
    _register("imageForSearchBarIcon", in: clazz, type: .image, selector: #selector(UISearchBar.setImage(_:for:state:)), params: [searchBarIconTransformer, Self.controlStateTransformer])
    _register("positionAdjustmentForSearchBarIcon", in: clazz, type: .offset, selector: #selector(UISearchBar.setPositionAdjustment(_:for:)), params: [searchBarIconTransformer])
    _register("scopeBarButtonBackgroundImage", in: clazz, type: .image, selector: #selector(UISearchBar.setScopeBarButtonBackgroundImage(_:for:)), params: [Self.controlStateTransformer])
    _register("scopeBarButtonDividerImage", in: clazz, type: .image, selector: #selector(UISearchBar.setScopeBarButtonDividerImage(_:forLeftSegmentState:rightSegmentState:)), params: [Self.controlStateTransformer, Self.controlStateTransformer])
    #if os(iOS)
    _register("scopeBarButtonTitleTextAttributes", in: clazz, type: .textAttributes, selector: #selector(UISearchBar.setScopeBarButtonTitleTextAttributes(_:for:)), params: [Self.controlStateTransformer])
    #endif
    _register("searchBarStyle", in: clazz, type: .enumType, enums: PropertyEnumValueMapping<UISearchBar.Style>(enumValues: [
      "default": .default, "minimal": .minimal, "prominent": .prominent
    ], enumBaseName: "UISearchBarStyle", defaultValue: .default))
    _register("searchFieldBackgroundImage", in: clazz, type: .image, selector: #selector(UISearchBar.setSearchFieldBackgroundImage(_:for:)), params: [Self.controlStateTransformer])
    
    //* UINavigationBar *//
    clazz = UINavigationBar.self
    _register("backgroundImage", in: clazz, type: .image, selector: #selector(UINavigationBar.setBackgroundImage(_:for:barMetrics:)), params: [barPositionTransformer, barMetricsTransformer])
    #if os(iOS)
    _register("barStyle", in: clazz, type: .enumType, enums: barStyleMapping)
    #endif
    _register("titleTextAttributes", in: clazz, type: .textAttributes, enums: nil)
    
    //* UIToolbar *//
    #if os(iOS)
    clazz = UIToolbar.self
    _register("backgroundImage", in: clazz, type: .image, selector: #selector(UIToolbar.setBackgroundImage(_:forToolbarPosition:barMetrics:)), params: [barPositionTransformer, barMetricsTransformer])
    _register("barStyle", in: clazz, type: .enumType, enums: barStyleMapping)
    _register("shadowImage", in: clazz, type: .image, selector: #selector(UIToolbar.setShadowImage(_:forToolbarPosition:)), params: [barPositionTransformer])
    #endif
    
    //* UITabBar *//
    clazz = UITabBar.self
    #if os(iOS)
    _register("barStyle", in: clazz, type: .enumType, enums: barStyleMapping)
    #endif
    _register("itemPositioning", in: clazz, type: .enumType, enums: PropertyEnumValueMapping<UITabBar.ItemPositioning>(enumValues: [
      "automatic": .automatic, "centered": .centered, "fill": .fill
    ], enumBaseName: "UITabBarItemPositioning", defaultValue: .automatic))
    
    //* UITextInputTraits *//
    let classes = [UITextField.self, UITextView.self, UISearchBar.self]
    _register("autocapitalizationType", inClasses: classes, type: .enumType, enums: PropertyEnumValueMapping<UITextAutocapitalizationType>(enumValues: [
      "none": .none, "allCharacters": .allCharacters, "sentences": .sentences, "words": .words,
    ], enumBaseName: "UITextAutocapitalizationType", defaultValue: .none))
    _register("autocorrectionType", inClasses: classes, type: .enumType, enums: PropertyEnumValueMapping<UITextAutocorrectionType>(enumValues: [
      "default": .default, "no": .no, "yes": .yes,
    ], enumBaseName: "UITextAutocorrectionType", defaultValue: .default))
    _register("keyboardAppearance", inClasses: classes, type: .enumType, enums: PropertyEnumValueMapping<UIKeyboardAppearance>(enumValues: [
      "default": .default, "alert": .alert, "dark": .dark, "light": .light
    ], enumBaseName: "UIKeyboardAppearance", defaultValue: .default))
    _register("keyboardType", inClasses: classes, type: .enumType, enums: PropertyEnumValueMapping<UIKeyboardType>(enumValues: [
      "default": .default, "alphabet": .alphabet, "asciiCapable": .asciiCapable, "decimalPad": .decimalPad, "emailAddress": .emailAddress, "namePhonePad": .namePhonePad,
      "numberPad": .numberPad, "numbersAndPunctuation": .numbersAndPunctuation, "phonePad": .phonePad, "twitter": .twitter, "URL": .URL, "webSearch": .webSearch
    ], enumBaseName: "UIKeyboardType", defaultValue: .default))
    _register("returnKeyType", inClasses: classes, type: .enumType, enums: PropertyEnumValueMapping<UIReturnKeyType>(enumValues: [
      "default": .default, "go": .go, "google": .google, "join": .join, "next": .next, "route": .route,
      "search": .search, "send": .send, "yahoo": .yahoo, "done": .done, "emergencyCall": .emergencyCall
    ], enumBaseName: "UIReturnKey", defaultValue: .default))
    _register("spellCheckingType", inClasses: classes, type: .enumType, enums: PropertyEnumValueMapping<UITextSpellCheckingType>(enumValues: [
      "default": .default, "no": .no, "yes": .yes
    ], enumBaseName: "UITextSpellCheckingType", defaultValue: .default))
  }
}

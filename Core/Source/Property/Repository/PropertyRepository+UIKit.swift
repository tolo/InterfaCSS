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
  
  static let textAlignmentMapping = PropertyEnumValueMapping<NSTextAlignment>(enumValues: [
    "left": .left, "center": .center, "right": .right
  ], enumBaseName: "NSTextAlignment", defaultValue: .left)
  
  
  // MARK: - Registration utility methods
  
  @discardableResult
  internal func registerRuntimeProperty(_ name: String, in clazz: AnyClass, type: PropertyType, enums enumValueMapping: AnyPropertyEnumValueMappingType? = nil) -> Property? {
    guard let runtimeProperty = RuntimeIntrospectionUtils.runtimeProperty(withName: name, in: clazz, lowercasedNames: true) else {
      error(.properties, "Cannot register '\(name)' in '\(clazz)'")
      return nil
    }
    return register(Property(runtimeProperty: runtimeProperty, type: type, enumValueMapping: enumValueMapping))
  }
  
  internal func registerRuntimeProperty(_ name: String, inClasses classes: [AnyClass], type: PropertyType, enums enumValueMapping: AnyPropertyEnumValueMappingType? = nil) {
    for clazz in classes { registerRuntimeProperty(name, in: clazz, type: type, enums: enumValueMapping) }
  }
  
  
  @discardableResult
  internal func registerSelectorProperty(_ name: String, in clazz: AnyClass, type: PropertyType, selector: Foundation.Selector,
                 enums enumValueMapping: AnyPropertyEnumValueMappingType? = nil,
                 params parameterTransformers: [PropertyParameterTransformer]) -> Property {
    return register(Property(withName: name, in: clazz, type: type, propertySetter:
                              SelectorSetter(enumValueMapping: enumValueMapping, parameterTransformers: parameterTransformers, selector: selector)))
  }
  
  @discardableResult
  internal func registerSelectorProperty(_ name: String, in clazz: AnyClass, type: PropertyType, selector: Foundation.Selector,
                 enums enumValueMapping: AnyPropertyEnumValueMappingType? = nil,
                 params parameterMappers: [AnyPropertyEnumValueMappingType]) -> Property {
    let parameterTransformers: [PropertyParameterTransformer] = parameterMappers.map { mapper in
      { value in return mapper.value(from: value) }
    }
    return registerSelectorProperty(name, in: clazz, type: type, selector: selector, enums: enumValueMapping, params: parameterTransformers)
  }
  
  @discardableResult
  internal func registerBlockProperty<TargetType: UIView, ValueType>(_ name: String, in clazz: TargetType.Type = TargetType.self, type: PropertyType,
                                                     params parameterTransformers: [PropertyParameterTransformer]? = nil,
                                                     typedSetter: @escaping PropertySetterBlock<TargetType, ValueType>) -> Property {
    return register(Property(withName: name, in: clazz, type: type,
                             propertySetter: BlockSetter(parameterTransformers: parameterTransformers, setterBlock: typedSetter)))
  }
  
  @discardableResult
  internal func registerBlockProperty<TargetType: UIView, ValueType>(_ name: String, in clazz: TargetType.Type = TargetType.self, type: TypedPropertyType<ValueType>,
                                                            params parameterTransformers: [PropertyParameterTransformer]? = nil,
                                                            typedSetter: @escaping PropertySetterBlock<TargetType, ValueType>) -> Property {
    return register(Property(withName: name, in: clazz, type: type,
                             propertySetter: BlockSetter(parameterTransformers: parameterTransformers, setterBlock: typedSetter)))
  }
    
  @discardableResult
  internal func registerEnumBlockProperty<TargetType: UIView, ValueType, EnumMappingType: PropertyEnumValueMappingType>(_ name: String, in clazz: TargetType.Type = TargetType.self,
                                                     enums enumValueMapping: EnumMappingType,
                                                     params parameterTransformers: [PropertyParameterTransformer]? = nil,
                                                     typedSetter: @escaping PropertySetterBlock<TargetType, ValueType>) -> Property where EnumMappingType.EnumValueType == ValueType {
    return register(Property(withName: name, in: clazz, type: .enumType, propertySetter:
                              EnumBlockSetter(enumValueMapping: enumValueMapping, parameterTransformers: parameterTransformers, setterBlock: typedSetter)))
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
    registerRuntimeProperty("backgroundColor", in: clazz, type: .color) // backgroundColor is missing type in runtime, due to declaration in category ( UIView(UIViewRendering) )
    registerRuntimeProperty("autoresizingMask", in: clazz, type: .enumType, enums: viewAutoresizingMapping)
    registerRuntimeProperty("contentMode", in: clazz, type: .enumType, enums: contentModeMapping)
    registerRuntimeProperty("tintAdjustmentMode", in: clazz, type: .enumType, enums: tintAdjustmentModeMapping)
    registerRuntimeProperty("tintColor", in: clazz, type: .color) // tintColor is missing type in runtime, due to declaration in category ( UIView(UIViewRendering) )
    // TODO: Remove
    //    _register("layer.cornerRadius", in: UIView.self, type: .number) { (_, view, value: CGFloat, _ ) in
    //      view.layer.borderWidth = value
    //    }
    //    _register("layer.borderWidth", in: UIView.self, type: .number) { (_, view, value: CGFloat, _ ) in
    //      view.layer.borderWidth = value
    //    }
    
    //* UIControl *//
    clazz = UIControl.self
    registerRuntimeProperty("contentVerticalAlignment", in: clazz, type: .enumType, enums: PropertyEnumValueMapping<UIControl.ContentVerticalAlignment>(enumValues: [
      "center": .center, "top": .top, "bottom": .bottom, "fill": .fill
    ], enumBaseName: "UIControlContentVerticalAlignment", defaultValue: .top))
    registerRuntimeProperty("contentHorizontalAlignment", in: clazz, type: .enumType, enums: PropertyEnumValueMapping<UIControl.ContentHorizontalAlignment>(enumValues: [
      "center": .center, "left": .left, "right": .right, "fill": .fill
    ], enumBaseName: "UIControlContentHorizontalAlignment", defaultValue: .center))
    
    //* UIButton *//
    clazz = UIButton.self
    registerSelectorProperty("attributedTitle", in: clazz, type: .string, selector: #selector(UIButton.setAttributedTitle(_:for:)), params: [Self.controlStateMapping])
    registerSelectorProperty("backgroundImage", in: clazz, type: .image, selector: #selector(UIButton.setBackgroundImage(_:for:)), params: [Self.controlStateMapping])
    registerSelectorProperty("image", in: clazz, type: .image, selector: #selector(UIButton.setImage(_:for:)), params: [Self.controlStateMapping])
    registerSelectorProperty("title", in: clazz, type: .string, selector: #selector(UIButton.setTitle(_:for:)), params: [Self.controlStateMapping])
    registerSelectorProperty("titleColor", in: clazz, type: .color, selector: #selector(UIButton.setTitleColor(_:for:)), params: [Self.controlStateMapping])
    registerSelectorProperty("titleShadowColor", in: clazz, type: .color, selector: #selector(UIButton.setTitleShadowColor(_:for:)), params: [Self.controlStateMapping])
    
    //* UILabel *//
    clazz = UILabel.self
    registerRuntimeProperty("baselineAdjustment", in: clazz, type: .enumType, enums: PropertyEnumValueMapping<UIBaselineAdjustment>(enumValues: [
      "none": .none, "alignBaselines": .alignBaselines, "alignCenters": .alignCenters
    ], enumBaseName: "UIBaselineAdjustment", defaultValue: .none))
    registerRuntimeProperty("lineBreakMode", in: clazz, type: .enumType, enums: PropertyEnumValueMapping<NSLineBreakMode>(enumValues: [
      "wordWrap": .byWordWrapping, "wordWrapping": .byWordWrapping, "charWrap": .byCharWrapping, "charWrapping": .byCharWrapping,
      "clip": .byClipping, "clipping": .byClipping, "truncateHead": .byTruncatingHead, "truncatingHead": .byTruncatingHead,
      "truncateTail": .byTruncatingTail, "truncatingTail": .byTruncatingTail, "truncateMiddle": .byTruncatingMiddle, "truncatingMiddle": .byTruncatingMiddle,
    ], enumBaseName: "NSLineBreakBy", defaultValue: .byTruncatingTail))
    registerRuntimeProperty("textAlignment", in: clazz, type: .enumType, enums: Self.textAlignmentMapping)
    
    //* UISegmentedControl *//
    clazz = UISegmentedControl.self
    registerSelectorProperty("backgroundImage", in: clazz, type: .image, selector: #selector(UISegmentedControl.setBackgroundImage(_:for:barMetrics:)), params: [Self.controlStateMapping, barMetricsMapping])
    registerSelectorProperty("contentPositionAdjustment", in: clazz, type: .offset, selector: #selector(UISegmentedControl.setContentPositionAdjustment(_:forSegmentType:barMetrics:)), params: [segmentTypeMapping, barMetricsMapping])
    registerSelectorProperty("contentOffset", in: clazz, type: .offset, selector: #selector(UISegmentedControl.setContentOffset(_:forSegmentAt:)), params: [integerTransformer])
    registerSelectorProperty("dividerImage", in: clazz, type: .image, selector: #selector(UISegmentedControl.setDividerImage(_:forLeftSegmentState:rightSegmentState:barMetrics:)), params: [
      Self.controlStateTransformer, Self.controlStateTransformer, barMetricsTransformer
    ])
    registerSelectorProperty("enabled", in: clazz, type: .bool, selector: #selector(UISegmentedControl.setEnabled(_:forSegmentAt:)), params: [integerTransformer])
    registerSelectorProperty("image", in: clazz, type: .image, selector: #selector(UISegmentedControl.setImage(_:forSegmentAt:)), params: [integerTransformer])
    registerSelectorProperty("title", in: clazz, type: .string, selector: #selector(UISegmentedControl.setTitle(_:forSegmentAt:)), params: [integerTransformer])
    registerSelectorProperty("titleTextAttributes", in: clazz, type: .textAttributes, selector: #selector(UISegmentedControl.setTitleTextAttributes(_:for:)), params: [Self.controlStateTransformer])
    registerSelectorProperty("width", in: clazz, type: .number, selector: #selector(UISegmentedControl.setWidth(_:forSegmentAt:)), params: [integerTransformer])
    
    #if os(iOS)
    //* UISlider *//
    clazz = UISlider.self
    registerSelectorProperty("maximumTrackImage", in: clazz, type: .image, selector: #selector(UISlider.setMaximumTrackImage(_:for:)), params: [Self.controlStateTransformer])
    registerSelectorProperty("minimumTrackImage", in: clazz, type: .image, selector: #selector(UISlider.setMinimumTrackImage(_:for:)), params: [Self.controlStateTransformer])
    registerSelectorProperty("thumbImage", in: clazz, type: .image, selector: #selector(UISlider.setThumbImage(_:for:)), params: [Self.controlStateTransformer])
    
    //* UIStepper *//
    clazz = UIStepper.self
    registerSelectorProperty("backgroundImage", in: clazz, type: .image, selector: #selector(UIStepper.setBackgroundImage(_:for:)), params: [Self.controlStateTransformer])
    registerSelectorProperty("decrementImage", in: clazz, type: .image, selector: #selector(UIStepper.setDecrementImage(_:for:)), params: [Self.controlStateTransformer])
    registerSelectorProperty("dividerImage", in: clazz, type: .image, selector: #selector(UIStepper.setDividerImage(_:forLeftSegmentState:rightSegmentState:)), params: [Self.controlStateTransformer, Self.controlStateTransformer])
    registerSelectorProperty("incrementImage", in: clazz, type: .image, selector: #selector(UIStepper.setIncrementImage(_:for:)), params: [Self.controlStateTransformer])
    #endif
    
    //* UIActivityIndicatorView *//
    clazz = UIActivityIndicatorView.self
    #if os(tvOS)
    let activityIndicatorViewStyleValues: [String: UIActivityIndicatorView.Style] = ["white": .white, "whiteLarge": .whiteLarge]
    #else
    let activityIndicatorViewStyleValues: [String: UIActivityIndicatorView.Style] = ["gray": .gray, "white": .white, "whiteLarge": .whiteLarge]
    #endif
    registerRuntimeProperty("activityIndicatorViewStyle", in: clazz, type: .enumType, enums: PropertyEnumValueMapping(enumValues: activityIndicatorViewStyleValues,
                                                                                                        enumBaseName: "UIActivityIndicatorViewStyle", defaultValue: .white))
    registerBlockProperty("animating", in: UIActivityIndicatorView.self, type: .bool) { (_, target, value: Bool, _) in
      value ? target.startAnimating() : target.stopAnimating()
    }
    
    //* UIProgressView *//
    clazz = UIProgressView.self
    #if os(iOS)
    registerRuntimeProperty("progressViewStyle", in: clazz, type: .enumType, enums: PropertyEnumValueMapping<UIProgressView.Style>(enumValues: [
      "default": .default, "bar": .bar
    ], enumBaseName: "UIProgressViewStyle", defaultValue: .default))
    #endif
    
    //* UITextField *//
    clazz = UITextField.self
    registerRuntimeProperty("borderStyle", in: clazz, type: .enumType, enums: PropertyEnumValueMapping<UITextField.BorderStyle>(enumValues: [
      "none": .none, "bezel": .bezel, "line": .line, "roundedRect": .roundedRect
    ], enumBaseName: "UITextBorderStyle", defaultValue: .none))
    registerRuntimeProperty("defaultTextAttributes", in: clazz, type: .textAttributes, enums: nil)
    registerRuntimeProperty("leftViewMode", in: clazz, type: .enumType, enums: viewModeMapping)
    registerRuntimeProperty("rightViewMode", in: clazz, type: .enumType, enums: viewModeMapping)
    registerRuntimeProperty("textAlignment", in: clazz, type: .enumType, enums: Self.textAlignmentMapping)
    
    //* UITextView *//
    clazz = UITextView.self
    #if os(iOS)
    registerRuntimeProperty("dataDetectorTypes", in: clazz, type: .enumType, enums: dataDetectorTypesMapping)
    #endif
    registerRuntimeProperty("linkTextAttributes", in: clazz, type: .textAttributes, enums: nil)
    registerRuntimeProperty("textAlignment", in: clazz, type: .enumType, enums: Self.textAlignmentMapping)
    registerRuntimeProperty("typingAttributes", in: clazz, type: .textAttributes, enums: nil)
    
    //* UIScrollView *//
    clazz = UIScrollView.self
    registerRuntimeProperty("indicatorStyle", in: clazz, type: .enumType, enums: PropertyEnumValueMapping<UIScrollView.IndicatorStyle>(enumValues: [
      "default": .default, "black": .black, "white": .white,
    ], enumBaseName: "UIScrollViewIndicatorStyle", defaultValue: .default))
    registerRuntimeProperty("decelerationRate", in: clazz, type: .enumType, enums: PropertyEnumValueMapping<UIScrollView.DecelerationRate>(enumValues: [
      "normal": .normal, "fast": .fast
    ], enumBaseName: "UIScrollViewDecelerationRate", defaultValue: .normal))
    registerRuntimeProperty("keyboardDismissMode", in: clazz, type: .enumType, enums: PropertyEnumValueMapping<UIScrollView.KeyboardDismissMode>(enumValues: [
      "none": .none, "onDrag": .onDrag, "interactive": .interactive
    ], enumBaseName: "UIScrollViewKeyboardDismissMode", defaultValue: .none))
    
    //* UITableView *//
    clazz = UITableView.self
    #if os(iOS)
    registerRuntimeProperty("separatorStyle", in: clazz, type: .enumType, enums: PropertyEnumValueMapping<UITableViewCell.SeparatorStyle>(enumValues: [
      "none": .none, "singleLine": .singleLine
    ], enumBaseName: "UITableViewCellSeparatorStyle", defaultValue: .none))
    #endif
    
    //* UITableViewCell *//
    clazz = UITableViewCell.self
    registerRuntimeProperty("selectionStyle", in: clazz, type: .enumType, enums: PropertyEnumValueMapping<UITableViewCell.SelectionStyle>(enumValues: [
      "none": .none, "default": .default, "blue": .blue, "gray": .gray,
    ], enumBaseName: "UITableViewCellSelectionStyle", defaultValue: .none))
    registerRuntimeProperty("editingStyle", in: clazz, type: .enumType, enums: PropertyEnumValueMapping<UITableViewCell.EditingStyle>(enumValues: [
      "none": .none, "delete": .delete, "insert": .insert,
    ], enumBaseName: "UITableViewCellEditingStyle", defaultValue: .none))
    #if os(iOS)
    registerRuntimeProperty("accessoryType", in: clazz, type: .enumType, enums: accessoryTypeMapping)
    registerRuntimeProperty("editingAccessoryType", in: clazz, type: .enumType, enums: accessoryTypeMapping)
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
    registerSelectorProperty("titleTextAttributes", in: clazz, type: .textAttributes, selector: #selector(UIBarItem.setTitleTextAttributes(_:for:)), params: [Self.controlStateTransformer])
    
    //* UIBarButtonItem *//
    clazz = UIBarButtonItem.self
    //setBackgroundImage:forState:style:barMetrics:
    registerSelectorProperty("backButtonBackgroundImage", in: clazz, type: .image, selector: #selector(UIBarButtonItem.setBackButtonBackgroundImage(_:for:barMetrics:)), params: [Self.controlStateTransformer, barMetricsTransformer])
    registerSelectorProperty("backButtonBackgroundVerticalPositionAdjustment", in: clazz, type: .number, selector: #selector(UIBarButtonItem.setBackButtonBackgroundVerticalPositionAdjustment(_:for:)), params: [barMetricsTransformer])
    registerSelectorProperty("backgroundImage", in: clazz, type: .image, selector: #selector(UIBarButtonItem.setBackgroundImage(_:for:barMetrics:)), params: [Self.controlStateTransformer, barMetricsTransformer])
    registerSelectorProperty("backgroundVerticalPositionAdjustment", in: clazz, type: .number, selector: #selector(UIBarButtonItem.setBackgroundVerticalPositionAdjustment(_:for:)), params: [barMetricsTransformer])
    registerSelectorProperty("backButtonTitlePositionAdjustment", in: clazz, type: .offset, selector: #selector(UIBarButtonItem.setBackButtonTitlePositionAdjustment(_:for:)), params: [barMetricsTransformer])
    registerRuntimeProperty("style", in: clazz, type: .enumType, enums: PropertyEnumValueMapping<UIBarButtonItem.Style>(enumValues: [
      "plain": .plain, "done": .done
    ], enumBaseName: "UIBarButtonItemStyle", defaultValue: .plain))
    registerSelectorProperty("titlePositionAdjustment", in: clazz, type: .offset, selector: #selector(UIBarButtonItem.setTitlePositionAdjustment(_:for:)), params: [barMetricsTransformer])
    
    //* UISearchBar *//
    clazz = UISearchBar.self
    registerSelectorProperty("backgroundImage", in: clazz, type: .image, selector: #selector(UISearchBar.setBackgroundImage(_:for:barMetrics:)), params: [barPositionTransformer, barMetricsTransformer])
    #if os(iOS)
    registerRuntimeProperty("barStyle", in: clazz, type: .enumType, enums: barStyleMapping)
    #endif
    registerSelectorProperty("imageForSearchBarIcon", in: clazz, type: .image, selector: #selector(UISearchBar.setImage(_:for:state:)), params: [searchBarIconTransformer, Self.controlStateTransformer])
    registerSelectorProperty("positionAdjustmentForSearchBarIcon", in: clazz, type: .offset, selector: #selector(UISearchBar.setPositionAdjustment(_:for:)), params: [searchBarIconTransformer])
    registerSelectorProperty("scopeBarButtonBackgroundImage", in: clazz, type: .image, selector: #selector(UISearchBar.setScopeBarButtonBackgroundImage(_:for:)), params: [Self.controlStateTransformer])
    registerSelectorProperty("scopeBarButtonDividerImage", in: clazz, type: .image, selector: #selector(UISearchBar.setScopeBarButtonDividerImage(_:forLeftSegmentState:rightSegmentState:)), params: [Self.controlStateTransformer, Self.controlStateTransformer])
    #if os(iOS)
    registerSelectorProperty("scopeBarButtonTitleTextAttributes", in: clazz, type: .textAttributes, selector: #selector(UISearchBar.setScopeBarButtonTitleTextAttributes(_:for:)), params: [Self.controlStateTransformer])
    #endif
    registerRuntimeProperty("searchBarStyle", in: clazz, type: .enumType, enums: PropertyEnumValueMapping<UISearchBar.Style>(enumValues: [
      "default": .default, "minimal": .minimal, "prominent": .prominent
    ], enumBaseName: "UISearchBarStyle", defaultValue: .default))
    registerSelectorProperty("searchFieldBackgroundImage", in: clazz, type: .image, selector: #selector(UISearchBar.setSearchFieldBackgroundImage(_:for:)), params: [Self.controlStateTransformer])
    
    //* UINavigationBar *//
    clazz = UINavigationBar.self
    registerSelectorProperty("backgroundImage", in: clazz, type: .image, selector: #selector(UINavigationBar.setBackgroundImage(_:for:barMetrics:)), params: [barPositionTransformer, barMetricsTransformer])
    #if os(iOS)
    registerRuntimeProperty("barStyle", in: clazz, type: .enumType, enums: barStyleMapping)
    #endif
    registerRuntimeProperty("titleTextAttributes", in: clazz, type: .textAttributes, enums: nil)
    
    //* UIToolbar *//
    #if os(iOS)
    clazz = UIToolbar.self
    registerSelectorProperty("backgroundImage", in: clazz, type: .image, selector: #selector(UIToolbar.setBackgroundImage(_:forToolbarPosition:barMetrics:)), params: [barPositionTransformer, barMetricsTransformer])
    registerRuntimeProperty("barStyle", in: clazz, type: .enumType, enums: barStyleMapping)
    registerSelectorProperty("shadowImage", in: clazz, type: .image, selector: #selector(UIToolbar.setShadowImage(_:forToolbarPosition:)), params: [barPositionTransformer])
    #endif
    
    //* UITabBar *//
    clazz = UITabBar.self
    #if os(iOS)
    registerRuntimeProperty("barStyle", in: clazz, type: .enumType, enums: barStyleMapping)
    #endif
    registerRuntimeProperty("itemPositioning", in: clazz, type: .enumType, enums: PropertyEnumValueMapping<UITabBar.ItemPositioning>(enumValues: [
      "automatic": .automatic, "centered": .centered, "fill": .fill
    ], enumBaseName: "UITabBarItemPositioning", defaultValue: .automatic))
    
    //* UITextInputTraits *//
    let classes = [UITextField.self, UITextView.self, UISearchBar.self]
    registerRuntimeProperty("autocapitalizationType", inClasses: classes, type: .enumType, enums: PropertyEnumValueMapping<UITextAutocapitalizationType>(enumValues: [
      "none": .none, "allCharacters": .allCharacters, "sentences": .sentences, "words": .words,
    ], enumBaseName: "UITextAutocapitalizationType", defaultValue: .none))
    registerRuntimeProperty("autocorrectionType", inClasses: classes, type: .enumType, enums: PropertyEnumValueMapping<UITextAutocorrectionType>(enumValues: [
      "default": .default, "no": .no, "yes": .yes,
    ], enumBaseName: "UITextAutocorrectionType", defaultValue: .default))
    registerRuntimeProperty("keyboardAppearance", inClasses: classes, type: .enumType, enums: PropertyEnumValueMapping<UIKeyboardAppearance>(enumValues: [
      "default": .default, "alert": .alert, "dark": .dark, "light": .light
    ], enumBaseName: "UIKeyboardAppearance", defaultValue: .default))
    registerRuntimeProperty("keyboardType", inClasses: classes, type: .enumType, enums: PropertyEnumValueMapping<UIKeyboardType>(enumValues: [
      "default": .default, "alphabet": .alphabet, "asciiCapable": .asciiCapable, "decimalPad": .decimalPad, "emailAddress": .emailAddress, "namePhonePad": .namePhonePad,
      "numberPad": .numberPad, "numbersAndPunctuation": .numbersAndPunctuation, "phonePad": .phonePad, "twitter": .twitter, "URL": .URL, "webSearch": .webSearch
    ], enumBaseName: "UIKeyboardType", defaultValue: .default))
    registerRuntimeProperty("returnKeyType", inClasses: classes, type: .enumType, enums: PropertyEnumValueMapping<UIReturnKeyType>(enumValues: [
      "default": .default, "go": .go, "google": .google, "join": .join, "next": .next, "route": .route,
      "search": .search, "send": .send, "yahoo": .yahoo, "done": .done, "emergencyCall": .emergencyCall
    ], enumBaseName: "UIReturnKey", defaultValue: .default))
    registerRuntimeProperty("spellCheckingType", inClasses: classes, type: .enumType, enums: PropertyEnumValueMapping<UITextSpellCheckingType>(enumValues: [
      "default": .default, "no": .no, "yes": .yes
    ], enumBaseName: "UITextSpellCheckingType", defaultValue: .default))
  }
}

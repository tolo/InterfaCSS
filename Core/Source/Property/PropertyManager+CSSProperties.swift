//
//  PropertyManager+CSSProperties.swift
//  InterfaCSS
//
//  Created by Tobias on 2020-02-27.
//  Copyright © 2020 Leafnode AB. All rights reserved.
//

import UIKit

extension PropertyManager {
  
  // MARK: - Register defaults
  
  func registerDefaultCSSProperties() {
    
    Property(withCompoundName: "font-family", type: .string)
    // font-family
    // font-weight
    // font-style (kanske)
    // font
       
    // text-align
    // line-height
    
    // background-color
    // color
    
    // background-image
    
    // border-width
    // border-color
    // border-radius (also border-top-left-radius etc)
    // border
    
    // text-align
    // text-shadow
       
    // box-shadow...
  }
}

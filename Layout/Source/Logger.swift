//
//  Logger.swift
//  InterfaCSS-Layout
//
//  Created by Tobias Löfstrand on 2019-01-10.
//  Copyright © 2019 Leafnode AB. All rights reserved.
//

import Foundation

final class Logger: NSObject {

  let name: String
  override var description: String { return name }

  init(_ name: String) {
    self.name = name
  }
}

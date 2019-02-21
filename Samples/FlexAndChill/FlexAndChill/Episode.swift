//
//  Model.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

import Foundation

typealias Episodes = [Episode]

struct Episode: Codable {
  let title, description, image, length: String

  static func fromJSON(file fileURL: URL) -> Episodes? {
    guard let data = try? Data(contentsOf: fileURL) else { return nil }
    return try? JSONDecoder().decode(Episodes.self, from: data)
  }

  var imageFileName: String {
    return image + ".jpg"
  }
}

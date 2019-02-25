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
  
  static func loadDefaultEpisodes() -> Episodes {
    do {
      return try JSONDecoder().decode(Episodes.self, from: episodesJSON.data(using: .utf8)!)
    } catch _ {
      return [Episode(title: "Error", description: "", image: "holuhraun", length: "")]
    }
  }

  var imageFileName: String {
    return image + ".jpg"
  }
}

private let episodesJSON = """
[
  {
    "title": "Holuhraun & Bárðarbunga",
    "description": "Iceland ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
    "image": "holuhraun",
    "length": "52m"
  },
  {
    "title": "Snæfellsjökull",
    "description": "Iceland ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
    "image": "snaefell",
    "length": "44m"
  },
  {
    "title": "Fjallabak Nature Reserve",
    "description": "Iceland ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
    "image": "fjallabak",
    "length": "47m"
  },
  {
    "title": "Landmannalaugar",
    "description": "Iceland ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
    "image": "landmannalaugar",
    "length": "48m"
  },
  {
    "title": "Þingvellir National Park",
    "description": "Iceland ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
    "image": "thingvellir",
    "length": "50m"
  },
  {
    "title": "Geysir",
    "description": "Iceland ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
    "image": "geysir",
    "length": "49m"
  }
]
"""

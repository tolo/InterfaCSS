//
//  ListCell.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

import UIKit
import InterfaCSS

class ListCell: LayoutTableViewCell {
  @objc var thumbnail: UIImageView?
  @objc var cellLabel1: UILabel?
  @objc var cellLabel2: UILabel?
  
  var model: Episode? {
    didSet { populateCell() }
  }
  
  override func populateCell() {
    guard let model = model else { return }
    cellLabel1?.text = model.title
    cellLabel2?.text = model.length
    thumbnail?.image = UIImage(named: model.imageFileName)
  }
}

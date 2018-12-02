//
//  ViewController.swift
//  FlexLayoutSample
//
//  Created by PMB on 2018-11-23.
//

import UIKit
import InterfaCSS

class MainViewController: FlexLayoutViewController {

  // MARK: - These properties can be injected from the layout:
  @objc var label1: UILabel? // @IBOutlet works too
  @objc var button1: UIButton? // @IBOutlet works too
  
  // When using FlexLayoutViewController as a base class, overload this method to create the LayoutContainerView and set it as the view of
  // the view controller. LayoutContainerView will take care of loading the layout, create the view tree and apply styling and the (Flexbox/Yoga) layout.
  override func loadLayoutContainerView() -> LayoutContainerView {
    let file = BundleFile.refreshableProjectFile("MainView.xml", inSameLocalProjectDirectoryAsCurrentFile: #file)
    return createLayoutContainerView(bundleFile: file)
  }
  
  override func layout(view: UIView, didLoadIn containerView: LayoutContainerView) {
    self.label1?.text = "Title set in code"
    self.button1?.setTitle("Le Button", for: .normal)
  }
}

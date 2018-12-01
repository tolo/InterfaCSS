//
//  ViewController.swift
//  FlexLayoutSample
//
//  Created by PMB on 2018-11-23.
//

import UIKit
import InterfaCSS

class ViewController: FlexLayoutViewController {

  @objc var label1: UILabel? // @IBOutlet works too
  @objc var button1: UIButton? // @IBOutlet works too
  
//  init() {
//    let file = BundleFile.refreshableProjectFile("ViewController.xml", inSameLocalProjectDirectoryAsCurrentFile: #file)
//    super.init(bundleFile: file)
//  }
//
//  public required init?(coder aDecoder: NSCoder) {
//    fatalError("init(coder:) has not been implemented")
//  }

  override func loadLayoutContainerView() -> LayoutContainerView {
    let file = BundleFile.refreshableProjectFile("ViewController.xml", inSameLocalProjectDirectoryAsCurrentFile: #file)
    return createLayoutContainerView(bundleFile: file)
  }
  
  override func layout(view: UIView, didLoadIn containerView: LayoutContainerView) {
    self.label1?.text = "Title set in code"
    self.button1?.setTitle("Le Button", for: .normal)
  }
  
 /* override func loadView() {
    let file = BundleFile.refreshableProjectFile("ViewController.xml", inSameLocalProjectDirectoryAsCurrentFile: #file)

    let flexView = FlexLayoutContainerView(bundleFile: file, fileOwner: self) { [unowned self] (flexView, view) in
      self.label1?.text = "Title set in code"
      self.button1?.setTitle("Le Button", for: .normal)
    }
    self.view = flexView
  }
  
  override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator);
    coordinator.animate(alongsideTransition: { (context) in
      
    }, completion: nil)
  }*/
}

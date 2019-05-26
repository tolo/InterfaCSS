//
//  ViewController.swift
//  HelloFlexLayout
//
//  Created by Tobias Löfstrand on 2019-05-26.
//

import UIKit
import InterfaCSS

class ViewController: LayoutViewController {

    @objc var label1: UILabel?
    @objc var button1: UIButton?


    // MARK: - LayoutViewController

    // When using LayoutViewController as a base class, overload this method to create the LayoutContainerView and set it as the view of
    // the view controller. LayoutContainerView will take care of loading the layout, create the view tree and apply styling and the (Flexbox/Yoga) layout.
    // If you don't implement this method, LayoutViewController will attempt to load a layout file named "<classname>.xml" by default (i.e. "ViewController.xml").
    override func loadLayoutContainerView() -> LayoutContainerView {
        // Using the method below to create the view enables hot reloading when running on the simulator (loaded from main bundle otherwise).
        return createLayoutContainerView(refreshableProjectFile: "View.xml", relativeToDirectoryContaining: #file)
    }
}

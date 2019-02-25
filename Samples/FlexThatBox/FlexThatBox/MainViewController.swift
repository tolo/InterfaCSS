//
//  ViewController.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

import UIKit
import InterfaCSS


class ExampleCell: LayoutTableViewCell {
  
  struct Model {
    let title: String
  }
  
  var model: Model? {
    didSet { populateCell() }
  }
  
  @objc var cellLabel1: UILabel? // @IBOutlet works too
  
  override func populateCell() {
    cellLabel1?.text = model?.title
  }
}



class MainViewController: LayoutViewController {
  
  // MARK: - These properties can be injected from the layout (use either $objc or @IBOutlet).
  @objc var tableView: UITableView? // Note: using ? instead of ! here, since it can be a bit safer when playing around with live reload ;)
  @objc var label1: UILabel?
  @objc var button1: UIButton?
  
  
  // MARK: - LayoutViewController
  
  // When using LayoutViewController as a base class, overload this method to create the LayoutContainerView and set it as the view of
  // the view controller. LayoutContainerView will take care of loading the layout, create the view tree and apply styling and the (Flexbox/Yoga) layout.
  // If you don't implement this method, LayoutViewController will attempt to load a layout file named "<classname>.xml" by default (i.e. "MainViewController.xml").
  override func loadLayoutContainerView() -> LayoutContainerView {
    // Using the method below to create the view enables hot reloading when running on the simulator (loaded from main bundle otherwise).
    return createLayoutContainerView(refreshableProjectFile: "MainView.xml", relativeToDirectoryContaining: #file)
  }
  
  // This method is called when the layout is loaded (or reloded). If you're not using hot reload, you can use viewDidLoad to do view setup etc instead.
  override func layout(view: UIView, didLoadIn containerView: LayoutContainerView) {
    super.layout(view: view, didLoadIn: containerView)
    self.label1?.text = "Title set in code"
    self.button1?.setTitle("Le Button", for: .normal)
    
    // In this example, table view cells are automatically sized (LayoutTableViewCell has build in support).
    // The maximum height of the cells depends on the configuration of "ExampleCell" (currently, "cellLabel1" is set to a maxium of 3 rows).
    tableView?.rowHeight = UITableView.automaticDimension
    tableView?.estimatedRowHeight = 44
  }
}


// MARK: - UITableViewDelegate / UITableViewDataSource
extension MainViewController: UITableViewDelegate, UITableViewDataSource {
  
  func sectionIndexTitles(for tableView: UITableView) -> [String]? {
    return ["F", "L", "E", "X", "B", "O", "X"] // Simulating section index to check that cell height adjusts accordingly
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "exampleCell", for: indexPath) as! ExampleCell
    if indexPath.row % 3 == 0 {
      cell.accessoryType = .checkmark
      cell.model = ExampleCell.Model(title: "This is row numer \(indexPath.row)")
    } else if indexPath.row % 3 == 1 {
      cell.accessoryType = .detailDisclosureButton
      cell.model = ExampleCell.Model(title: "This is the label for row number \(indexPath.row)")
    } else {
      cell.accessoryType = .disclosureIndicator
      cell.model = ExampleCell.Model(title: "This is a bit longish label for the row with the number, or rather, index of \(indexPath.row)")
    }
    return cell
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 3
  }
  
}

//
//  MainViewController.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

import UIKit
import InterfaCSS

class MainViewController: LayoutViewController {

  // MARK: - These properties can be injected from the layout (use either $objc or @IBOutlet).
  @objc var episodeLabel: UILabel? // Using ? instead or ! can be a bit safer when playing around with live reload ;)
  @objc var titleLabel: UILabel?
  @objc var descriptionLabel: UILabel!
  @objc var lengthLabel: UILabel!
  @objc var image: UIImageView?
  
  @objc var tableView: UITableView!

  var models: Episodes = {
    return Episode.fromJSON(file: Bundle.main.url(forResource: "episodes", withExtension: "json")!) ??
      [Episode(title: "Error", description: "", image: "holuhraun", length: "")]
  }()
  
  var selectedEpisode = 0 {
    didSet {
      selectedEpisodeChanged()
      updateLayout()
    }
  }
  
  func selectedEpisodeChanged() {
    self.episodeLabel?.text = "S1:E\(selectedEpisode+1)"
    self.titleLabel?.text = models[selectedEpisode].title
    self.descriptionLabel?.text = models[selectedEpisode].description
    self.image?.image = UIImage(named: models[selectedEpisode].imageFileName)
  }

  // MARK: - LayoutViewController
  
  // When using LayoutViewController as a base class, overload this method to create the LayoutContainerView and set it as the view of
  // the view controller. LayoutContainerView will take care of loading the layout, create the view tree and apply styling and the (Flexbox/Yoga) layout.
  override func loadLayoutContainerView() -> LayoutContainerView {
    return createLayoutContainerView(refreshableProjectFile: "MainView.xml", relativeToDirectoryContaining: #file)
  }

  override func layout(view: UIView, didLoadIn containerView: LayoutContainerView) {
    selectedEpisodeChanged()
  }

  // MARK: - UIViewController

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .default
  }
}


// MARK: - UITableViewDataSource / UITableViewDelegate

extension MainViewController: UITableViewDataSource, UITableViewDelegate {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return models.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "listCell", for: indexPath) as! ListCell
    cell.model = models[indexPath.row]
    return cell
  }

  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 100.0
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    selectedEpisode = indexPath.row
  }
}

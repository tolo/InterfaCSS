//
//  Styler+BundleFile.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

import Foundation

// TODO: Move into core after Swift conversion.
public extension Styler {

  @discardableResult
  public func loadStyleSheet(fromRefreshableProjectFile projectFile: String, relativeToDirectoryContaining currentFile: String) -> StyleSheet? {
    let bundleFile = BundleFile.refreshableProjectFile(projectFile, relativeToDirectoryContaining: currentFile)
    return loadStyleSheet(fromBundleFile: bundleFile)
  }

  @discardableResult
  public func loadStyleSheet(fromBundleFile bundleFile: BundleFile) -> StyleSheet? {
    if bundleFile.refreshable {
      return loadRefreshableStyleSheet(from: bundleFile.fileURL)
    } else {
      return loadStyleSheet(fromFileURL: bundleFile.fileURL)
    }
  }
}

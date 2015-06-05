//
//  ViewController.swift
//  ISSLayout
//
//  Created by Tobias Löfstrand on 2015-05-01.
//  Copyright (c) 2015 Leafnode. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    // Properties auto populated by ISSViewBuilder (when using elementId):
    var button: UIButton?
    var label: UILabel?
    var rootView:ISSLayoutContextView?
    
    override func loadView() {
        // Setup view hierarchy
        self.view = ISSViewBuilder.rootViewWithId("rootView", withOwner: self, andSubViews: {
            return [
                ISSViewBuilder.labelWithId("marginLabel"),
                ISSViewBuilder.labelWithId("layoutGuideLabel"),
                
                ISSViewBuilder.viewOfClass(UIButton.self, withId: "button"),
                ISSViewBuilder.viewWithId("view1"),
                ISSViewBuilder.viewWithId("view2"),
                ISSViewBuilder.viewWithId("view3"),
                ISSViewBuilder.viewWithId("view4"),
                ISSViewBuilder.labelWithId("label")
            ];
        })

        if let b = button {
            b.setTitle("Tap Me", forState: .Normal)
            b.addTarget(self, action: "moveMe", forControlEvents: .TouchDown)
        }
        if let l = label {
            l.text = "Hello ISSLayout World!"
        }

        // Example of how additional layout post processing / validation / customization can be applied:
        if let layoutContextView = self.rootView {
            layoutContextView.layoutPostProcessingBlock = ViewController.layoutPostProcessingBlock
        }
    }
    
    // Function used as layout post processing block to calculate some custom weird frame value for view4:
    class func layoutPostProcessingBlock(v: UIView!, l: ISSLayout!) {
        if v.elementIdISS == "view4" {
            let vf = v.frame
            if vf.origin.y > (UIScreen.mainScreen().bounds.size.height * 2 / 3) {
                v.frame = CGRectMake(vf.origin.x - vf.size.width, vf.origin.y - vf.size.height, vf.size.width, vf.size.height)
            }
        }
    }
    
    func moveMe() {
        var hasClass: Bool = self.button?.hasStyleClassISS("moveMe") as Bool!
        
        UIView.animateWithDuration(0.3, delay: 0, options: .BeginFromCurrentState | .LayoutSubviews, animations: { () -> Void in
            if( hasClass ) {
                self.button?.removeStyleClassISS("moveMe")
            } else {
                self.button?.addStyleClassISS("moveMe")
            }
            self.button?.applyStylingISS()
            // Force re-layout of root view:
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
}

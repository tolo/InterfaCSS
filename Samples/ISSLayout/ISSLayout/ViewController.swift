//
//  ViewController.swift
//  ISSLayout
//
//  Created by Tobias Löfstrand on 2015-05-01.
//  Copyright (c) 2015 Leafnode. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet var view1: UIView?
    @IBOutlet var view2: UIView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if let v1 = view1 {
            if let v2 = view2 {
                let r = v2.convertRect(v1.frame, fromView: view)
                println(NSStringFromCGRect(r))
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}


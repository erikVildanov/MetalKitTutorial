//
//  MetalViewController.swift
//  MetalKitTutorial
//
//  Created by Erik Vildanov on 02/08/2019.
//  Copyright © 2019 Erik Vildanov. All rights reserved.
//

import UIKit

class MetalViewController: UIViewController {

    let metalView = MetalView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view = metalView
        
    }
}

//
//  ViewController.swift
//  Cam
//
//  Created by flow on 2021/12/29.
//

import UIKit

class CameraController: UIViewController {
    
    lazy var camera: SoCamera = {
        var camera = SoCamera()
        camera.delegate = self
        camera.dataCallbackDelegate = self
        return camera
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        camera.begin()
    }
    

}

extension CameraController: SoCameraDataDelegate {
    
    func startFailRequirePermisson() {
        
    }
    

    
}

extension CameraController: SoCameraUserConfigDelegate {
    
    var preview: UIView {
        return self.view
    }

}

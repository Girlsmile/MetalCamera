//
//  Task.swift
//  Cam
//
//  Created by flow on 2021/12/29.
//

import Foundation
class Task {
    
    static var shared = Task()
    
    private var procressSemaphore = DispatchSemaphore(value: 1)
    
    lazy var cameraOutputQueue: DispatchQueue = {
        var cameraOutputQueue = DispatchQueue.init(label: "SoCamera.cameraOutputQueue", qos: .background)
        return cameraOutputQueue
    }()
    
    
    lazy var procressQueue: DispatchQueue = {
        var cameraOutputQueue = DispatchQueue.init(label: "SoCamera.cameraOutputQueue", qos: .userInitiated, attributes: [.concurrent])
        return procressQueue
    }()
    
    
}

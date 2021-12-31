

import Foundation

@objc protocol SoCameraDataDelegate {
    
    /// 设备缺失
    @objc optional func startFailRequireDevice()
    
    /// 权限缺失
    func startFailRequirePermisson()
    
}

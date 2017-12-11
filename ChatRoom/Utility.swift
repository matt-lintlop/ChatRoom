//
//  Utility.swift
//  ChatRoom
//
//  Created by Matthew Lintlop on 12/6/17.
//  Copyright © 2017 Matthew Lintlop. All rights reserved.
//

import Foundation
import UIKit

// Get the current time as an integer as used my the chat service protocol.
// Equal to (now.timeIntervalSince1970 * 1000)
func currentTime() -> Int {
    let now = Date.init(timeIntervalSinceNow: 0)
    return Int(now.timeIntervalSince1970 * 1000)
}

// show or hide the network indicator in the navigation bar
func setActivityInditcatorVisible(_ visible: Bool) {
    if (visible) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    else {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
}

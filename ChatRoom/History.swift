//
//  History.swift
//  MyChat
//
//  Created by Matthew Lintlop on 12/7/17.
//  Copyright © 2017 Matthew Lintlop. All rights reserved.
//

import Foundation

struct History : Codable {
    let command = "?command?"
    var client_time: Int
    var since: Int
}

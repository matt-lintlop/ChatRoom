//
//  History.swift
//  ChatServer
//
//  Created by Matthew Lintlop on 12/7/17.
//  Copyright © 2017 Matthew Lintlop. All rights reserved.
//

import Foundation

struct History : Codable {
    let command = "history"
    var client_time: Int
    var since: Int
    
    init(since: Int) {
        self.since = since
        self.client_time = currentTime()
    }
}

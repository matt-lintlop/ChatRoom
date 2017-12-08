//
//  Message.swift
//  ChatRoom
//
//  Created by Matthew Lintlop on 12/6/17.
//  Copyright © 2017 Matthew Lintlop. All rights reserved.
//

import Foundation

struct Message: Codable {
    var msg: String
    var client_time:Int
    var server_time:Int?
    
    init(msg: String, client_time: Int) {
        self.msg = msg
        self.client_time = client_time
        self.server_time = nil
    }
    
    init(msg: String, client_time: Int, server_time: Int) {
        self.msg = msg
        self.client_time = client_time
        self.server_time = server_time
    }
}


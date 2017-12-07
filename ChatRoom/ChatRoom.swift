//
//  ChatRoom.swift
//  MyChat
//
//  Created by Matthew Lintlop on 12/6/17.
//  Copyright © 2017 Matthew Lintlop. All rights reserved.
//

import Foundation

protocol ChatRoomDelegateProtocol {
    func showMessage(_ message: String);
}

class ChatRoom {
    var  delegate: ChatRoomDelegateProtocol?
    
    init() {
        self.delegate = nil
        testMessageJSON()
    }
    
    func testMessageJSON() {
        let message = Message(msg: "Hello There!", client_time: 123456)
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        do {
            let data = try encoder.encode(message)
            let json = String(data: data, encoding: .utf8)
            print("Message JSON:\n\(json!.debugDescription)")
            
            let message2 = try JSONDecoder().decode(Message.self, from: data)
            print("Message 2: \(message2)")
         } catch {
        }

    }
}

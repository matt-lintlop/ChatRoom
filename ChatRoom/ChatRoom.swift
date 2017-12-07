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
//            let data = try encoder.encode(message)
//            let json = String(data: data, encoding: .utf8)
//            print("Message JSON:\n\(json!.debugDescription)")
            
 //           let json = "{\n  \"msg\" : \"Hello There!\",\n  \"client_time\" : 123456\n}"
            
            let json = "{'msg':'hello from the other side','client_time':1446754551485,'server_time':1512609867179}"
            let json2 = json.replacingOccurrences(of: "'", with: "\"")
            let data = json2.data(using: .utf8)
            let message2 = try JSONDecoder().decode(Message.self, from: data!)
            print("Message 2: \(message2)")
         } catch {
            print("Error parsing: \(error)")
        }

    }
}

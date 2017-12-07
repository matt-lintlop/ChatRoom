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
    }
    
    func testMessageJSON() {
        let message = Message(msg: "Hello There!", client_time: 123456)
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        let json =  """
                    {'msg':'hello from the other side','client_time':1446754551485,'server_time':1512609867179}
                    {'msg':'test','client_time':1512610643732,'server_time':1512610641873}
                    {'msg':'return error','client_time':1512610681791,'server_time':1512610679920}
                    {'msg':'give me error','client_time':1512610749697,'server_time':1512610747827}
                    {'msg':'another try','client_time':1512610766977,'server_time':1512610765107}
                    {'msg':'queue this up','client_time':1512610994095,'server_time':1512610992393}
                    {'msg':'queued','client_time':1512611154298,'server_time':1512611152424}
                    {'msg':'code refactoring','client_time':1512612260099,'server_time':1512612258236}
                    {'msg':'queuing','client_time':1512612367635,'server_time':1512612365772}
                    {'msg':'refactoring','client_time':1512612904839,'server_time':1512612902974}
                    {'msg':'hello from the other side','client_time':1446754551485,'server_time':1512612924827}
                    {'msg':'hello from the other side','client_time':1446754551485,'server_time':1512612924827}
                    {'msg':'hello from the other side','client_time':1446754551485,'server_time':1512612932812}
                    {'msg':'hello from the other side','client_time':1446754551485,'server_time':1512612933477}
                    {'msg':'hello from the other side','client_time':1446754551485,'server_time':1512612934116}
                    {'msg':'hello from the other side','client_time':1446754551485,'server_time':1512612934741}
                    """
        parseJSONFromServer(json)
    }
    
    // Parse JSON from the server 1 object at a time
    func parseJSONFromServer(_ json: String) {
        let formattedJSON = json.replacingOccurrences(of: "'", with: "\"")
        var currenJSONItem: String = ""
        var index = 0;
        for char in formattedJSON {
            index += 1;
            if char == "\n" {
                continue
            }
            currenJSONItem += String(char)
            if char == "}" {
                let data = currenJSONItem.data(using: .utf8)
                if let message = try? JSONDecoder().decode(Message.self, from: data!) {
                    delegate?.showMessage(message.msg)
                    print("Showing Message: \(message)")
               }
                currenJSONItem = ""
            }
        }
    }
}

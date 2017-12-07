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

class ChatRoom : NSObject, StreamDelegate {
    var delegate: ChatRoomDelegateProtocol?             // Chat Roome Delegate
    var inputStream: InputStream!                       // Input Stream
    var outputStream: OutputStream!                     // Output Stream
    var chatServerReachability: Reachability            // Chat Server Reachability

    let chatServerIP = "52.91.109.76"                   // Chat Server IP Address
    let chatServerPort: UInt32 = 1234                   // Chat Server Port

    override init() {
        self.delegate = nil
        self.chatServerReachability = Reachability(hostName: chatServerIP)
   }
    
    deinit {
        self.chatServerReachability.stopNotifier()
        NotificationCenter.default.removeObserver(self)
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
    
    func setupNetworkCommunication() {
        var readStream: Unmanaged<CFReadStream>?
        var writeStream: Unmanaged<CFWriteStream>?
        
        CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault,
                                           chatServerIP as CFString,
                                           chatServerPort,
                                           &readStream,
                                           &writeStream)
        
        inputStream = readStream!.takeRetainedValue()
        outputStream = writeStream!.takeRetainedValue()
        
        inputStream.delegate = self
        outputStream.delegate = self
        
        inputStream.schedule(in: .main, forMode: .commonModes)
        outputStream.schedule(in: .main, forMode: .commonModes)
        
        inputStream.open()
        outputStream.open()
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
               }
                currenJSONItem = ""
            }
        }
    }
 
    // MARK: Chat Server Reachability
    func startCheckingReachability() {
        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChanged(_:)), name: NSNotification.Name.reachabilityChanged, object: nil)
        self.chatServerReachability.startNotifier()
   }
    
    func isChatServerReachable() -> Bool {
        var reachable = false
        switch chatServerReachability.currentReachabilityStatus() {
            case ReachableViaWiFi,ReachableViaWWAN:
                reachable = true
                print("The chat server is Reachable");
            case NotReachable:
                reachable = false
                print("The chat server is Not Reachable");
            default:
                reachable = false
                print("The chat server is Not Reachable");
        }
        return reachable
    }
    
    @objc func reachabilityChanged(_ notification: NSNotification) {
        let _ = isChatServerReachable()
    }
    
    // MARK: Outgoing Messages
    
    func deleteOutgoingMessages() {
        
    }
    
    func loadOutgoingMessages() {
        
    }
    
    func saveOutgoingMessages() {
        
    }
    
    func sendOutgoingMessages() {
        
    }
    
    func addOutgoingMessages(_ message: Message) {
        
    }
}

//
//  ChatRoom.swift
//  ChatRoom
//
//  Created by Matthew Lintlop on 12/6/17.
//  Copyright © 2017 Matthew Lintlop. All rights reserved.
//

import Foundation
import UIKit

protocol ChatRoomDelegateProtocol {
    func showMessage(_ message: String);                        // Show A Message To The User
    func showOfflineMessageSentAlert();                         // Show Alert When User Sends Message Offfline
}

class ChatRoom : NSObject, StreamDelegate {
    var delegate: ChatRoomDelegateProtocol?                     // Chat Room Delegate
    var inputStream: InputStream!                               // Input Stream
    var outputStream: OutputStream!                             // Output Stream
    var chatServerReachability: Reachability                    // Chat Server Reachability
    var outgoingMessages: [Message]?                            // Outgoing Messages
    var lastTimeConnected: Int?                                 // Time Of Last Connection To The Chat Server
    var lastTimeDisconnected: Int?                              // Time Of Last Disconnect From The Chat Server
   var chatServerReachableTimer: Timer?                        // Timer Used To Check For Reachability To Chat Server
    
    let chatServerIP = "52.91.109.76"                           // Chat Server IP Address
    let chatServerPort: UInt32 = 1234                           // Chat Server Port
    let outgoingMessagesDataFileName = "OutgoingMessages.json"  // Outgoing Message Data File
    let maxReadLength = 1024                                    // Maximum # Of Bytes Read From Chat Server

    override init() {
        self.delegate = nil
        self.chatServerReachability = Reachability(hostName: chatServerIP)
        
        super.init()

        // load outgoing messages that are persisted on disk
        self.loadOutgoingMessages()
    
        // start periodic tasks
        resume()
    }
    
    deinit {
        self.chatServerReachability.stopNotifier()
        NotificationCenter.default.removeObserver(self)
    }
    
    func setupNetworkCommunication() {
        var readStream: Unmanaged<CFReadStream>?
        var writeStream: Unmanaged<CFWriteStream>?
        
        setActivityInditcatorVisible(true)

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
 
        setActivityInditcatorVisible(false)
}
    
    func teardownNetworkCommunication() {
        inputStream.remove(from: .main, forMode: .commonModes)
        inputStream.close()
        inputStream = nil
        
        outputStream.remove(from: .main, forMode: .commonModes)
        outputStream.close()
        outputStream = nil
 
        self.lastTimeDisconnected = currentTime()
}
    
    func getLastTimeConnected() {
        let defaults = UserDefaults()
        let lastTime = defaults.integer(forKey: "lastTimeConnected")
        if lastTime == 0 {
            setLastTimeConnectedToNow()
        }
        else {
            self.lastTimeConnected = lastTime
        }
    }
    
    func setLastTimeConnected(_ time: Int) {
        let defaults = UserDefaults()
        defaults.set(time, forKey: "lastTimeConnected")
        self.lastTimeConnected = time
    }
    
    func setLastTimeConnectedToNow() {
        setLastTimeConnected(currentTime())
    }
    
    // Parse JSON from the server 1 object at a time
    func parseJSONFromServer(_ json: String) {
        
//        print("*****************************************************")
//        print("JSON From Server = \(json)")
//        print("*****************************************************")

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
                
                // Decode the current line of JSON
                let data = currenJSONItem.data(using: .utf8)
                
                if let message = try? JSONDecoder().decode(Message.self, from: data!) {
                    delegate?.showMessage(message.msg)
                }
                else {
                    print("Error Decoding Message JSON: \(currenJSONItem)")
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
            case NotReachable:
                reachable = false
            default:
                reachable = false
        }
        return reachable
    }
    
    @objc func reachabilityChanged(_ notification: NSNotification) {
        let reachable = isChatServerReachable()
        if reachable {
            downloadMessagesSinceLastTimeConnected();     // download all messages since last time connected
       }
    }
    
    // MARK: Sending Messages
    func userDidEnterMessage(_ text: String) {
        // create a new Message with the given text at the current time
        let newMessage = Message(msg: text, client_time: currentTime())

        if isChatServerReachable() {
            // the chat server is reachable. send the messag
            _ = sendMessage(newMessage)
        }
        else {
            // the chat server is not reachable. add the message to outgoing messages.
            addOutgoingMessage(newMessage)
            
            // show alert to the user taht says the message was not sent.
            delegate?.showOfflineMessageSentAlert()
        }
    }
    
    // download messages from the chat server after a given date
    func downloadMessagesSinceDate(_ since: Int) -> Bool {
        guard outputStream != nil else {
            return false
        }
        
        let elapsedSecs = (currentTime() - since)/1000
        print("Downloading Messages Since: \(since) : Elapsed \(elapsedSecs) Seconds")
        
        var result = true
        let encoder = JSONEncoder()
        do {
            let history = History(since: since)
            let data = try encoder.encode(history)
            data.withUnsafeBytes {  (bytes: UnsafePointer<UInt8>)->Void in
                self.outputStream.write(bytes, maxLength: data.count)
                self.outputStream.write("\n", maxLength: 1)
            }
        } catch {
            print("Error Getting History: \(error.localizedDescription)")
            result = false
        }
        return result
    }
  
    // send a message to the chat server
    func sendMessage(_ message: Message) -> Bool {
        guard (outputStream != nil) && outputStream.hasSpaceAvailable else {
            print("ERROR: Output Has No Space Available!")
            return false
        }

        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(message)
            data.withUnsafeBytes { (u8Ptr: UnsafePointer<UInt8>) in
                outputStream.write(u8Ptr, maxLength: data.count)
                outputStream.write("\n", maxLength: 1)
            }
        } catch {
            print("Error Sending Message: \(error.localizedDescription)")
        }
        return true
    }

    // MARK: Outgoing Messages
    
    // Load all outgoing messages
    func loadOutgoingMessages() {
        guard let url = getOutgoingMessagesURL() else  {
            return
        }
        let decoder = JSONDecoder()
        do {
            let data = try Data(contentsOf: url, options: [])
            self.outgoingMessages = try decoder.decode([Message].self, from: data)
        } catch {
            // ignore the error
        }
    }
    
    // Save all outgoing messages tto the local disk.
    func saveOutgoingMessages() {
        guard let outgoingMessages = outgoingMessages else {
            return
        }
        guard outgoingMessages.count > 0 else {
            return
        }
        guard let url = getOutgoingMessagesURL() else {
            return
        }
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(outgoingMessages)
            try data.write(to: url, options: [])
        } catch {
            print("Error Saving Outgoing Messages!: \(error.localizedDescription)")
        }
    }
    
    // Send all outgoing messages
    func sendOutgoingMessages() {
        guard let outgoingMessages = outgoingMessages else {
            return
        }
        guard outgoingMessages.count > 0 else {
            return
        }
        var sentMessageCount = 0;
        var failedMessageCount = 0;

        DispatchQueue.global(qos: .background).async {
            var failedMessages: [Message] = []
            for message in outgoingMessages {
                if (!self.sendMessage(message)) {
                    failedMessages.append(message)
                    failedMessageCount += 1
                }
                else {
                    sentMessageCount += 1
                }
            }
            self.outgoingMessages = failedMessages
            if failedMessages.count > 0 {
                self.saveOutgoingMessages()
            }
            else {
                self.deleteOutgoingMessages()
            }
         }
    }
    
    // Add a new outgoing mesage
    func addOutgoingMessage(_ message: Message) {
        if outgoingMessages == nil {
            outgoingMessages = []
        }
        outgoingMessages?.append(message)
        saveOutgoingMessages()
    }
    
    // Delete all outgoing messages
    func deleteOutgoingMessages() {
        guard let url = getOutgoingMessagesURL() else {
            return
        }
        try? FileManager().removeItem(at: url)
    }
    
    // Get the url of the outgoing messages data file
    func getOutgoingMessagesURL() -> URL? {
        guard let docURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return docURL.appendingPathComponent(outgoingMessagesDataFileName)
    }
    
    func stopChatSession() {
        inputStream.close()
        outputStream.close()
    }
    
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case Stream.Event.hasBytesAvailable:
            setActivityInditcatorVisible(true)
            readAvailableBytes(stream: aStream as! InputStream)
            setActivityInditcatorVisible(false)
            
       case Stream.Event.endEncountered:
            stopChatSession()
            
        case Stream.Event.hasSpaceAvailable:
            if let outgoingMessages = self.outgoingMessages {
                if outgoingMessages.count > 0 {
                    setActivityInditcatorVisible(true)
                    sendOutgoingMessages()
                    setActivityInditcatorVisible(false)
               }
            }
         default:
            break
        }
    }
    
    private func readAvailableBytes(stream: InputStream) {
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: maxReadLength)
        while stream.hasBytesAvailable {
            let numberOfBytesRead = inputStream.read(buffer, maxLength: maxReadLength-10)
            if numberOfBytesRead < 0 {
                if let _ = inputStream.streamError {
                    break
                }
            }
            
            processDataFromChatServer(buffer: buffer, length: numberOfBytesRead)
        }
    }
    
    private func processDataFromChatServer(buffer: UnsafeMutablePointer<UInt8>,
                                           length: Int) {
        guard length > 0 else {
            return
        }
        let data = Data(bytes: buffer, count: length)
        if let json = String(data: data, encoding: .utf8) {
            parseJSONFromServer(json)
        }
    }
    
    // MARK: Message History
    
    func downloadMessagesSinceLastTimeConnected() {
        getLastTimeConnected()
        guard let lastTimeConnected = lastTimeConnected else {
            return
        }
 
        if lastTimeConnected != 0 {
            let _ = downloadMessagesSinceDate(lastTimeConnected)
            setLastTimeConnectedToNow()
            return
        }
        else {
            return
        }
    }
    
    func downloadMessagesSinceLastTimeDisconnected() {
        guard let lastTimeDisconnected = self.lastTimeDisconnected else {
            return
        }
        if lastTimeDisconnected != 0 {
            let _ = downloadMessagesSinceDate(lastTimeDisconnected)
        }
    }

    // MARK: Suspend & Resume
    
    // supend periodic chat room tasks
    func suspend() {
        chatServerReachableTimer?.invalidate()
        chatServerReachableTimer = nil
    }
    
    // resume periodic chat room tasks
    func resume() {        
        chatServerReachableTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(testChatServerReachability), userInfo: nil, repeats: true)
        chatServerReachableTimer?.fire()
    }

    @objc func testChatServerReachability() {
        if self.isChatServerReachable() {
            self.setLastTimeConnectedToNow()
        }
    }
}


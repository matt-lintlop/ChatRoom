//
//  ChatRoom.swift
//  ChatRoom
//
//  Created by Matthew Lintlop on 12/6/17.
//  Copyright © 2017 Matthew Lintlop. All rights reserved.
//

import Foundation

protocol ChatRoomDelegateProtocol {
    func showMessage(_ message: String);
}

class ChatRoom : NSObject {
    var delegate: ChatRoomDelegateProtocol?             // Chat Roome Delegate
    var inputStream: InputStream!                       // Input Stream
    var outputStream: OutputStream!                     // Output Stream
    var chatServerReachability: Reachability            // Chat Server Reachability
    var outgoingMessages: [Message]?                    // Outgoing Messages

    let chatServerIP = "52.91.109.76"                   // Chat Server IP Address
    let chatServerPort: UInt32 = 1234                   // Chat Server Port
    let outgoingMessagesDataFileName = "OutgoingMessages.json"
    let maxReadLength = 1024*4                          // maximum # of bytes read from chat server

    override init() {
        self.delegate = nil
        self.chatServerReachability = Reachability(hostName: chatServerIP)
        
        super.init()

        // load outgoing messages that are persisted on disk
        self.loadOutgoingMessages()
   }
    
    deinit {
        self.chatServerReachability.stopNotifier()
        NotificationCenter.default.removeObserver(self)
    }
    
    func testMessageJSON() {
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
        print("Processing JSON fro Server:\n\(json)")
        
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
        }
    }
    
    func sendMessage(_ message: Message) -> Bool {
        delegate?.showMessage(message.msg)
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
            print("Loaded \(outgoingMessages!.count) Outgoing Messages From Disk")
            print("Outgoing Messages: \(outgoingMessages!.debugDescription)")
        } catch {
            print("Error Loading Outgoing Messages!: \(error.localizedDescription)")
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
            print("Saved Reservations To Disk: \(outgoingMessages.count)")
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
            print("Sent \(sentMessageCount) Messages")
            print("Error Sending \(failedMessageCount) Messages")
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
}

extension ChatRoom: StreamDelegate {
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case Stream.Event.hasBytesAvailable:
            print("new message received")
            readAvailableBytes(stream: aStream as! InputStream)
        case Stream.Event.endEncountered:
            stopChatSession()
        case Stream.Event.errorOccurred:
            print("error occurred")
        case Stream.Event.hasSpaceAvailable:
            print("has space available")
        default:
            print("some other event...")
            break
        }
    }
    
    private func readAvailableBytes(stream: InputStream) {
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: maxReadLength)
        while stream.hasBytesAvailable {
            let numberOfBytesRead = inputStream.read(buffer, maxLength: maxReadLength)
            
            print("read data from chat server!: \(numberOfBytesRead) Bytes")

            if numberOfBytesRead < 0 {
                if let _ = inputStream.streamError {
                    break
                }
            }
            
            // process all of the data from the chat server
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
    
}


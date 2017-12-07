//
//  ChatViewController.swift
//  MyChat
//
//  Created by Matthew Lintlop on 12/6/17.
//  Copyright © 2017 Matthew Lintlop. All rights reserved.
//

import UIKit

class ChatRoomViewController: UIViewController, UITextFieldDelegate, ChatRoomDelegateProtocol {
    
    @IBOutlet weak var messagesTextView: UITextView!
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var messageLabelBottomConstraint: NSLayoutConstraint!
    
    var chatRoom: ChatRoom!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.chatRoom = ChatRoom()
        self.chatRoom.delegate = self
        
        self.chatRoom.isChatServerReachable()   // TESING
        self.chatRoom.testMessageJSON()     // TESTING\
        print("Time is now \(currentTime())")
        
        NotificationCenter.default.addObserver(self, selector: #selector(ChatRoomViewController.keyboardWillShow(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ChatRoomViewController.keyboardWillHide(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let message = textField.text?.trimmingCharacters(in: CharacterSet(charactersIn: "\r\n")) {
            showMessage(message)
        }
        messageTextField.text = nil
        messageTextField.resignFirstResponder()
        return false
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        if let message = textField.text?.trimmingCharacters(in: CharacterSet(charactersIn: "\r\n")) {
            showMessage(message)
        }
        messageTextField.text = nil
        return true
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        guard let keyboardSize = ((notification.userInfo?[UIKeyboardFrameBeginUserInfoKey]) as? NSValue)?.cgRectValue else {
            return
        }
        
        UIView.animate(withDuration: 0.5) {
            self.messageLabelBottomConstraint.constant = keyboardSize.size.height + 10
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
        }
        
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        UIView.animate(withDuration: 0.5) {
            self.messageLabelBottomConstraint.constant = 10
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
        }
    }
    
    // MARK: ChatRoomDelegateProtocol
    
    func showMessage(_ message: String) {
        guard message.count > 0 else {
            return
        }
        if Thread.current.isMainThread {
            messagesTextView.text.append("\(message)\r")
        }
        else {
            DispatchQueue.main.async(execute: {
                self.messagesTextView.text.append("\(message)\r")
            })
        }
    }
}


//
//  ChatViewController.swift
//  ChatRoom
//
//  Created by Matthew Lintlop on 12/6/17.
//  Copyright © 2017 Matthew Lintlop. All rights reserved.
//

import UIKit

class ChatRoomViewController: UIViewController, UITextFieldDelegate, ChatRoomDelegateProtocol {
    
    @IBOutlet weak var messagesTextView: UITextView!
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var messageLabelBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var messageLabelRightConstraint: NSLayoutConstraint!
    @IBOutlet weak var sendButton: UIButton!
    
    var chatRoom: ChatRoom!
    var keyboardVisible = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        chatRoom = ChatRoom()
        chatRoom.delegate = self
        chatRoom.setupNetworkCommunication()
        chatRoom.startCheckingReachability()
        if chatRoom.isChatServerReachable() {
            chatRoom.downloadMessagesSinceLastTimeConnected()
            chatRoom.sendOutgoingMessages()
       }
        
        NotificationCenter.default.addObserver(self, selector: #selector(ChatRoomViewController.keyboardWillShow(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ChatRoomViewController.keyboardWillHide(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ChatRoomViewController.handleTextFieldChanged(notification:)), name: NSNotification.Name.UITextFieldTextDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ChatRoomViewController.keyboardDidChangeFrame(notification:)), name: NSNotification.Name.UIKeyboardDidChangeFrame, object: nil)
        enableSendButton()
        
//        let time = currentTime() - Int(5 * 60 * 60 * 1000)      // 5 hours
//        chatRoom.downloadMessagesSinceDate(time)                // TESTING
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.chatRoom = chatRoom
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func sendPressed(_ sender: Any) {
        guard let text = messageTextField.text else {
            return
        }
        chatRoom.userDidEnterMessage(text)
        messageTextField.text = nil
        enableSendButton()
    }
    
    @IBAction func erasePressed(_ sender: Any) {
        messagesTextView?.text = nil
    }
    
    func enableSendButton() {
        var enabled = false
        if let text = messageTextField.text {
            if text.count >= 1 {
                enabled = true
            }
        }
        sendButton.isEnabled = enabled
     }
    
    // show an alert when the user sends a message offline
    func showOfflineMessageSentAlert() {
        let alertController = UIAlertController(title: "No Internet", message:
            "Your message will be sent when you are back online.", preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default,handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }

    // MARK: Notifications
    
    @objc func keyboardDidChangeFrame(notification: NSNotification) {
        guard self.keyboardVisible else {
            return
        }
        guard let endSize = ((notification.userInfo?[UIKeyboardFrameEndUserInfoKey]) as? NSValue)?.cgRectValue else {
            return
        }
        UIView.animate(withDuration: 0.25) {
            self.messageLabelBottomConstraint.constant = endSize.height + 10
            self.messageLabelRightConstraint.constant = CGFloat(16)
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
        }
    }

    @objc func keyboardWillShow(notification: NSNotification) {
        guard let keyboardSize = ((notification.userInfo?[UIKeyboardFrameBeginUserInfoKey]) as? NSValue)?.cgRectValue else {
            return
        }
        self.keyboardVisible = true

        UIView.animate(withDuration: 0.25) {
            self.messageLabelBottomConstraint.constant = keyboardSize.size.height + 10
            self.messageLabelRightConstraint.constant = CGFloat(16)
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
        }
        
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        self.keyboardVisible = false
        UIView.animate(withDuration: 0.25) {
            self.messageLabelBottomConstraint.constant = 10
            self.messageLabelRightConstraint.constant = CGFloat(90)
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
        }
    }
    
    @objc func handleTextFieldChanged(notification: NSNotification) {
        enableSendButton()
    }

    // MARK: ChatRoomDelegateProtocol
    
    func showMessage(_ message: String) {
        guard message.count > 0 else {
            return
        }
        if Thread.current.isMainThread {
            messagesTextView.text.append("\(message)\r")
            scrollTextViewToBottom()
       }
        else {
            DispatchQueue.main.async(execute: {
                self.messagesTextView.text.append("\(message)\r")
                self.scrollTextViewToBottom()
           })
        }
    }
    
    func scrollTextViewToBottom() {
        if (messagesTextView.contentOffset.y >= messagesTextView.contentSize.height - messagesTextView.frame.size.height) {
        }
        else {
            let contentOffset = CGPoint(x: messagesTextView.contentOffset.x, y: messagesTextView.contentSize.height - messagesTextView.frame.size.height)
            messagesTextView.setContentOffset(contentOffset, animated: true)
        }
    }
    
    // MARK: UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // hide the keyboard when Return pressed
        textField.resignFirstResponder()
        return true
    }
}


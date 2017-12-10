//
//  AppDelegate.swift
//  ChatRoom
//
//  Created by Matthew Lintlop on 12/6/17.
//  Copyright © 2017 Matthew Lintlop. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    weak var chatRoom: ChatRoom?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        UINavigationBar.appearance().tintColor = UIColor.white
        UINavigationBar.appearance().titleTextAttributes = [NSAttributedStringKey.foregroundColor:UIColor.white]
        
        // TESTING to Retrieve A Few Hours Of Messages
        let time = currentTime() - Int(3 * 60 * 60 * 1000)      // 3 hours
        chatRoom?.downloadMessagesSinceDate(time)
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // suspend chat room periodic tasks
        chatRoom?.suspend()
        chatRoom?.teardownNetworkCommunication()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // resume chat room periodic tasks
        chatRoom?.resume()
        chatRoom?.setupNetworkCommunication()
        
        // download all messages since we disconnected when the app went to the background
        chatRoom?.downloadMessagesSinceLastTimeDisconnected()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}


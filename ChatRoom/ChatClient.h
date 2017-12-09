//
//  ChatClient.h
//  ChatRoom
//
//  Created by Matthew Lintlop on 12/8/17.
//  Copyright © 2017 Matthew Lintlop. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <netinet/in.h>

@interface ChatClient : NSObject

- (BOOL)connectToChatServer;

@property (nonatomic) int sockfd, newsockfd;

@end

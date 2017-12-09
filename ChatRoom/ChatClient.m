//
//  ChatClient.m
//  ChatRoom
//
//  Created by Matthew Lintlop on 12/8/17.
//  Copyright © 2017 Matthew Lintlop. All rights reserved.
//

#import "ChatClient.h"
#include <sys/socket.h>
#include <stdio.h>
#include <stdlib.h>
#include <netdb.h>
#include <netinet/in.h>
#include <string.h>

@implementation ChatClient

- (BOOL)connectToChatServer {
    struct hostent *server;
    struct sockaddr_in serv_addr;
    
    // Create a socket point
    self.sockfd = socket(AF_INET, SOCK_STREAM, 0);
    if (self.sockfd < 0) {
        perror("ERROR opening socket");
        exit(1);
    }
    server = gethostbyname("52.91.109.76");
    if (server == NULL) {
        fprintf(stderr, "ERROR, no such host: %s\n", "52.91.109.76");
        exit(0);
    }
    printf("Resolved Host: %s\n", server->h_name);
    
    bzero((char*) &serv_addr, sizeof(serv_addr));
    serv_addr.sin_family = AF_INET;
    bcopy((char*)server->h_addr_list[0], (char*)&serv_addr.sin_addr.s_addr, server->h_length);
    serv_addr.sin_port = htons(1234);
    
    // Now connect to the TCP Server
    if (connect(self.sockfd, (struct sockaddr*)&serv_addr, sizeof(serv_addr)) < 0) {
        NSLog(@"ERROR connecting");
        return NO;
    }
    else {
        return YES;
    }
}
@end

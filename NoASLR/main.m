//
//  main.cpp
//  NoASLR
//
//  Created by Callum Taylor on 10/10/2014.
//  Copyright (c) 2014 Callum Taylor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASLRTasks.h"
int main(int argc, const char * argv[])
{
    NSString *desc = [NSString stringWithUTF8String:argv[1]];
    printf("%i\n", [ASLRTasks removeASLRFor:desc]);
    
}


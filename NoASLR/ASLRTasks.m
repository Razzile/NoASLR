//
//  ASLRTasks.m
//  NoASLR
//
//  Created by Callum Taylor on 10/10/2014.
//  Copyright (c) 2014 Callum Taylor. All rights reserved.
//

#import "ASLRTasks.h"
@interface ASLRTasks ()
+ (enum ASLRStatus)isFileMacho:(NSString *)path;
+ (enum ASLRStatus)doRemoveASLR:(NSString *)path forOffset:(uint)offset;
+ (BOOL)hasASLR:(uint)flags;
@end

@implementation ASLRTasks

+ (enum ASLRStatus)isFileMacho:(NSString *)path {
    uint magic;
    FILE *bin = fopen([path UTF8String], "r+");
    fread(&magic, sizeof(magic), 1, bin);
    fclose(bin);
    printf("%x\n", magic);
    return (magic == MH_MAGIC || magic == MH_MAGIC_64 || magic == FAT_MAGIC) ? kSuccess : kNotMacho;
}

+ (enum ASLRStatus)removeASLRFor:(NSString *)path {
    enum ASLRStatus status = [ASLRTasks isFileMacho:path];
    if (status == kSuccess)
    {
        uint magic;
        FILE *bin = fopen([path UTF8String], "r+");
        fread(&magic, 1, sizeof(magic), bin);
        fseek(bin, 0, SEEK_SET);
        if (magic == FAT_MAGIC)
        {
            struct fat_header fat;
            fread(&fat, 1, sizeof(fat), bin);
            struct fat_arch *archs = malloc(sizeof(struct fat_arch) * fat.nfat_arch);
            
            for (int i = 0; i < fat.nfat_arch; i++)
            {
                struct fat_arch temp;
                fread(&temp, 1, sizeof(temp), bin);
                memcpy(&archs[i], &temp, sizeof(temp));
            }
            fclose(bin);
            for (int i = 0; i < fat.nfat_arch; i++)
            {
                status = [ASLRTasks doRemoveASLR:path forOffset:archs[i].offset];
            }
            free(archs);
        }
        else
        {
            status = [ASLRTasks doRemoveASLR:path forOffset:0];
        }
    }
    return status;
}

+ (enum ASLRStatus)doRemoveASLR:(NSString *)path forOffset:(uint)offset {
    enum ASLRStatus status = kNoASLR;
    FILE *bin = fopen([path UTF8String], "r+");
    fseek(bin, offset, SEEK_SET);
    uint magic;
    fread(&magic, 1, sizeof(magic), bin);
    fseek(bin, offset, SEEK_SET);
    if (magic == MH_MAGIC)
    {
        struct mach_header mach;
        fread(&mach, sizeof(mach), 1, bin);
        if ([ASLRTasks hasASLR:mach.flags])
        {
            mach.flags &= ~MH_PIE;
            status = kSuccess;
        }
        fseek(bin, offset, SEEK_SET);
        fwrite(&mach, 1, sizeof(mach), bin);
    }
    else if (magic == MH_MAGIC_64)
    {
        struct mach_header_64 mach;
        fread(&mach, sizeof(mach), 1, bin);
        if ([ASLRTasks hasASLR:mach.flags])
        {
            mach.flags &= ~MH_PIE;
            status = kSuccess;
        }
        fseek(bin, offset, SEEK_SET);
        fwrite(&mach, 1, sizeof(mach), bin);
    }
    fclose(bin);
    return status;
}

+ (BOOL)hasASLR:(uint)flags {
    return (flags & MH_PIE) > 0;
}
@end
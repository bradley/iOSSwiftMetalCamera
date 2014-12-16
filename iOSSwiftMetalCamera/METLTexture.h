/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  Simple Utility class for creating a 2d texture
  
 */

#import <UIKit/UIKit.h>
#import <Metal/Metal.h>

@interface METLTexture : NSObject

@property (nonatomic) id <MTLTexture> texture;
@property (nonatomic) MTLTextureType target;
@property (nonatomic) uint32_t width;
@property (nonatomic) uint32_t height;
@property (nonatomic) uint32_t depth;
@property (nonatomic) uint32_t format;
@property (nonatomic) BOOL hasAlpha;
@property (nonatomic) NSString *path;

- (id) initWithResourceName:(NSString *)name
                        ext:(NSString *)ext;

- (BOOL) finalize:(id<MTLDevice>)device;

- (BOOL) finalize:(id<MTLDevice>)device
             flip:(BOOL)flip;

- (UIImage *)image;

- (void *)bytes;

@end

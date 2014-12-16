/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  Simple Utility class for creating a 2d texture
  
 */

#import "METLTexture.h"

@implementation METLTexture

- (instancetype) initWithResourceName:(NSString *)name
                                  ext:(NSString *)ext
{
    NSString *path = [[NSBundle mainBundle] pathForResource:name
                                                     ofType:ext];
    
    if(!path)
    {
        return nil;
    } // if
    
    self = [super init];
    
    if (self)
    {
        _path     = path;
        _width    = 0;
        _height   = 0;
        _depth    = 1;
        _format   = MTLPixelFormatRGBA8Unorm;
        _target   = MTLTextureType2D;
        _texture  = nil;
        _hasAlpha = NO;
    } // if
    
    return self;
} // initWithResourceName

- (BOOL) finalize:(id <MTLDevice>)device
{
    return [self finalize:device
                     flip:YES];
} // finalize

- (void) dealloc
{
    _path    = nil;
    _texture = nil;
} // dealloc

// assumes png file
- (BOOL) finalize:(id <MTLDevice>)device
             flip:(BOOL)flip
{
    UIImage *pImage = [UIImage imageWithContentsOfFile:_path];
    
    if(!pImage)
    {
        pImage = nil;
        
        return NO;
    } // if
    
    CGColorSpaceRef pColorSpace = CGColorSpaceCreateDeviceRGB();
    
    if(!pColorSpace)
    {
        pImage = nil;
        
        return NO;
    } // if
    
    self.width  = (uint32_t)CGImageGetWidth(pImage.CGImage);
    self.height = (uint32_t)CGImageGetHeight(pImage.CGImage);
    
    uint32_t width    = _width;
    uint32_t height   = _height;
    uint32_t rowBytes = width * 4;
    
    CGContextRef pContext = CGBitmapContextCreate(NULL,
                                                  width,
                                                  height,
                                                  8,
                                                  rowBytes,
                                                  pColorSpace,
                                                  (CGBitmapInfo)kCGImageAlphaPremultipliedLast);
    
    CGColorSpaceRelease(pColorSpace);
    
    if(!pContext)
    {
        return NO;
    } // if
    
    CGRect bounds = CGRectMake(0.0f, 0.0f, width, height);
    
    CGContextClearRect(pContext, bounds);
    
    // Vertical Reflect
    if(flip)
    {
        CGContextTranslateCTM(pContext, width, height);
        CGContextScaleCTM(pContext, -1.0, -1.0);
    } // if
    
    CGContextDrawImage(pContext, bounds, pImage.CGImage );
    
    pImage = nil;
    
    MTLTextureDescriptor *pTexDesc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm
                                                                                        width:width
                                                                                       height:height
                                                                                    mipmapped:NO];
    self.target  = pTexDesc.textureType;
    self.texture = [device newTextureWithDescriptor:pTexDesc];
    
    pTexDesc = nil;
    
    if(!self.texture)
    {
        CGContextRelease(pContext);
        
        return NO;
    } // if
    
    const void *pPixels = CGBitmapContextGetData(pContext);
    
    [self.texture replaceRegion:MTLRegionMake2D(0, 0, width, height)
                    mipmapLevel:0
                      withBytes:pPixels
                    bytesPerRow:rowBytes];
    
    CGContextRelease(pContext);
    
    return YES;
} // finalize


//


- (UIImage *)image{
  
  void * p = self.bytes;
  
  CGColorSpaceRef pColorSpace = CGColorSpaceCreateDeviceRGB();
  
  CGContextRef pContext = CGBitmapContextCreate(p,
                                                _width,
                                                _height,
                                                8,
                                                _width * 4,
                                                pColorSpace,
                                                (CGBitmapInfo)kCGImageAlphaPremultipliedLast);
  CGImageRef imgRef = CGBitmapContextCreateImage(pContext);
  UIImage *image = [UIImage imageWithCGImage:imgRef];
  
  
  return image;
}

- (void *)bytes
{
  uint32_t width    = _width;
  uint32_t height   = _height;
  uint32_t rowBytes = width * 4;
  
  void * p = malloc(width * height * 4);
  
  [self.texture getBytes:p bytesPerRow:rowBytes fromRegion:MTLRegionMake2D(0, 0, width, height) mipmapLevel:0];
  
  return p;
}

@end

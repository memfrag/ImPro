//
//  MJViewController.m
//  ImPro
//
//  Created by Martin Johannesson on 2013-09-14.
//  Copyright (c) 2013 Martin Johannesson. All rights reserved.
//

#import "MJViewController.h"
#import <GLKit/GLKit.h>
#import "gpufilter.h"
#import "shaders.h"

static __weak MJViewController *this = nil;

@interface MJViewController ()

- (void)showShaderLog:(NSString *)log;

@end

static void logFunc(const char *log)
{
    [this showShaderLog:[NSString stringWithCString:log encoding:NSUTF8StringEncoding]];
}

@implementation MJViewController {
    NSArray *_shaders;
    NSOpenGLContext *_glContext;
    GPUFramebuffer _framebuffer;
    GPUTexture _inputTexture;
    BOOL _defaultProgramIsCompiled;
    GPUProgram _defaultProgram;
    uint8_t *_pixelData;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)awakeFromNib
{
    this = self;
    [self setupFilters];
    
    _shaders = @[
                 @{@"name" : @"Pass-through", @"fragmentShader" : [self loadString:FRAGMENT_SHADER_FILE(Pass-through) ofType:@"fsh"]},
                 @{@"name" : @"L*a*b, L=100", @"fragmentShader" : [self loadString:FRAGMENT_SHADER_FILE(Maximize L) ofType:@"fsh"]},
                 @{@"name" : @"Visualize a & b", @"fragmentShader" : [self loadString:FRAGMENT_SHADER_FILE(Visualize AB) ofType:@"fsh"]},
                 @{@"name" : @"Visualize Hue", @"fragmentShader" : [self loadString:FRAGMENT_SHADER_FILE(Visualize Hue) ofType:@"fsh"]},
                 @{@"name" : @"Isolate Neon", @"fragmentShader" : [self loadString:FRAGMENT_SHADER_FILE(Isolate Neon) ofType:@"fsh"]},
                 @{@"name" : @"Isolate Neon Color", @"fragmentShader" : [self loadString:FRAGMENT_SHADER_FILE(Isolate Neon Color) ofType:@"fsh"]},
                 @{@"name" : @"HSV", @"fragmentShader" : [self loadString:FRAGMENT_SHADER_FILE(RGB to HSV) ofType:@"fsh"]},
                 @{@"name" : @"Quantize 8", @"fragmentShader" : [self loadString:FRAGMENT_SHADER_FILE(Quantize 8) ofType:@"fsh"]},
                 @{@"name" : @"CGA", @"fragmentShader" : [self loadString:FRAGMENT_SHADER_FILE(RGB to CGA) ofType:@"fsh"]},
                 @{@"name" : @"Outer Levels", @"fragmentShader" : [self loadString:FRAGMENT_SHADER_FILE(Outer Levels) ofType:@"fsh"]},
                 @{@"name" : @"ConSatBri", @"fragmentShader" : [self loadString:FRAGMENT_SHADER_FILE(ConSatBri) ofType:@"fsh"]},
    ];
    
    [self.shaderComboBox reloadData];
    [self.shaderComboBox selectItemAtIndex:0];
}

- (NSString *)loadString:(NSString *)filename ofType:(NSString *)type
{
    NSError *error = nil;
    NSString *path = [[NSBundle mainBundle] pathForResource:filename ofType:type];
    NSString *string = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    if (!string) {
        NSLog(@"ERROR: Unable to load %@", filename);
    }
    return string;
}
    
- (IBAction)selectBeforeAction:(id)sender
{
    NSOpenPanel *panel = [NSOpenPanel openPanel];    
    [panel setCanChooseFiles:YES];
    [panel setCanChooseDirectories:NO];
    [panel setAllowsMultipleSelection:NO];
    [panel setAllowedFileTypes:@[@"jpg", @"jpeg", @"png"]];
    
    [panel beginWithCompletionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton) {
            for (NSURL *fileURL in [panel URLs]) {
                NSLog(@"Selected file: %@", fileURL);
                break;
            }
        }
    }];
}

- (void)setupFilters
{
    NSOpenGLPixelFormatAttribute attributes[] =
    {
        NSOpenGLPFADoubleBuffer,
        NSOpenGLPFAAccelerated, 0,
        // Must specify the 3.2 Core Profile to use OpenGL 3.2
        //NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersion3_2Core,
        0
    };
    NSOpenGLPixelFormat *pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:attributes];
    _glContext = [[NSOpenGLContext alloc] initWithFormat:pixelFormat shareContext:nil];
    [_glContext makeCurrentContext];
    
    
    gpuConfigureRenderingPipeline();
    
    _pixelData = NULL;
}

- (void)destroyFilters
{
    [self destroyProgram];
}

- (void)showShaderLog:(NSString *)log
{
    [self.shaderCompilerLogTextView setString:log];
}

- (void)clearShaderLog
{
    [self.shaderCompilerLogTextView setString:@""];
}

- (BOOL)compileProgramWithVertexShader:(NSString *)vertexShader fragmentShader:(NSString *)fragmentShader
{
    [self destroyProgram];
 
    [self clearShaderLog];
    
    GPUStatus status = gpuCompileProgram(vertexShader ? [vertexShader UTF8String] : kGPUDefaultVertexShaderCode,
                                         fragmentShader ? [fragmentShader UTF8String] : kGPUDefaultFragmentShaderCode,
                                         &_defaultProgram, logFunc);
    _defaultProgramIsCompiled = (status == GPUStatusOK);
    
    if (status == GPUStatusOK) {
        [self showShaderLog:@"Compiled!"];
    }
    
    return _defaultProgramIsCompiled;
}

- (void)destroyProgram
{
    if (_defaultProgramIsCompiled) {
        gpuDestroyProgram(&_defaultProgram);
    }
}

- (void)prepForImage:(NSImage *)image
{
    if (_pixelData != NULL) {
        free(_pixelData);
        _pixelData = NULL;
        gpuDestroyFramebuffer(&_framebuffer);
        gpuDestroyTexture(&_inputTexture);
    }
    
    if (self.beforeImageView.image) {
        uint32_t width = image.size.width;
        uint32_t height = image.size.height;
        gpuCreateFramebuffer(width, height, &_framebuffer);
        gpuCreateBlankTexture(_framebuffer.texture.width,
                              _framebuffer.texture.height,
                              &_inputTexture);
        _pixelData = malloc(gpuGetFramebufferSizeInBytes(&_framebuffer));
        memset(_pixelData, 0, gpuGetFramebufferSizeInBytes(&_framebuffer));
    }
}

- (void)filterImage:(NSImage *)image
{
    if (!image) {
        self.afterImageView.image = nil;
        return;
    }
    
    double t0 = CFAbsoluteTimeGetCurrent();

    [self uploadImage:image toTexture:&_inputTexture];
    
    gpuRenderTextureToFramebufferUsingProgram(&_inputTexture,
                                              &_framebuffer,
                                              &_defaultProgram);
    
    gpuGetFramebufferContents(&_framebuffer, _pixelData, GPUColorFormatRGBA);
    
    
    NSImage *outputImage = [self createNSImageFromRGBA:_pixelData
                                                 width:_framebuffer.texture.width
                                                height:_framebuffer.texture.height];
    
    double t1 = CFAbsoluteTimeGetCurrent();
    NSLog(@"TIMER: %f", (float)(t1 - t0));
    
    self.afterImageView.image = outputImage;
}

- (void)uploadImage:(NSImage *)image toTexture:(GPUTexture *)texture
{
    NSError *error = nil;
    GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithContentsOfData:[self.beforeImageView.image TIFFRepresentation] options:@{} error:&error];
    if (textureInfo == nil) {
        NSLog(@"ERROR: Unable to create texture from CGImage: %@", error.localizedDescription);
        return;
    }
    glBindTexture(GL_TEXTURE_2D, textureInfo.name);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    _inputTexture.textureId = textureInfo.name;
    _inputTexture.width = textureInfo.width;
    _inputTexture.height = textureInfo.height;
    _inputTexture.valid = 1;
}

- (NSImage *)createNSImageFromRGBA:(uint8_t *)data width:(int)width height:(int)height
{
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, data, width * height * 4, NULL);
    
    int bitsPerComponent = 8;
    int bitsPerPixel = 32;
    int bytesPerRow = width * 4;
    
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    
    CGImageRef imageRef = CGImageCreate(width, height, bitsPerComponent, bitsPerPixel, bytesPerRow, colorSpaceRef, bitmapInfo, provider, NULL, NO, renderingIntent);
    
    NSImage *newImage = [[[NSImage alloc] initWithCGImage:imageRef size:NSMakeSize(width, height)] copy];
    
    return newImage;
}


- (IBAction)runAction:(id)sender
{
    if (self.beforeImageView.image) {
        [self filterImage:self.beforeImageView.image];
    }
}

- (IBAction)imageChangedAction:(id)sender {
    if (self.beforeImageView.image) {
        [self prepForImage:self.beforeImageView.image];
        [self filterImage:self.beforeImageView.image];
    }
}

- (IBAction)compileShaderAction:(id)sender {
    NSInteger selectedIndex = [self.shaderComboBox indexOfSelectedItem];
    if (selectedIndex >= 0) {
        NSString *vertexShader = _shaders[selectedIndex][@"vertexShader"];
        BOOL compiledOk = [self compileProgramWithVertexShader:vertexShader fragmentShader:[[self.shaderTextView textStorage] string]];
        if (compiledOk && self.beforeImageView.image) {
            [self prepForImage:self.beforeImageView.image];
            [self filterImage:self.beforeImageView.image];
        }
    }
}

- (IBAction)copyAfterImageToPasteboard:(id)sender {
    if (self.afterImageView.image) {
        NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
        [pasteboard clearContents];
        NSArray *copiedObjects = [NSArray arrayWithObject:self.afterImageView.image];
        [pasteboard writeObjects:copiedObjects];
    }
}

- (IBAction)openFragmentShaderEditor:(id)sender {
    [self.shaderEditorWindow makeKeyAndOrderFront:self];
}

#pragma mark - Combo Box delegate

- (void)comboBoxSelectionDidChange:(NSNotification *)notification {
    NSComboBox *comboBox = [notification object];
    NSInteger selectedIndex = [comboBox indexOfSelectedItem];
    NSString *vertexShader = _shaders[selectedIndex][@"vertexShader"];
    NSString *fragmentShader = _shaders[selectedIndex][@"fragmentShader"];
    [self.shaderTextView setString:fragmentShader];
    [[self.shaderTextView textStorage] setFont:[NSFont fontWithName:@"Menlo" size:11]];
    [self compileProgramWithVertexShader:vertexShader fragmentShader:fragmentShader];
    [self filterImage:self.beforeImageView.image];
}

#pragma mark - Combo Box data source

- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(NSInteger)index
{
    return _shaders[index][@"name"];
}

- (NSInteger)numberOfItemsInComboBox:(NSComboBox *)aComboBox
{
    return _shaders.count;
}

@end


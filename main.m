#import <Cocoa/Cocoa.h>
#import <MetalKit/MetalKit.h>
#import <simd/simd.h>

typedef struct {
  vector_float2 position;
  vector_float4 color;
} Vertex;

static matrix_float4x4 mat_rotationY(float a) {
  float c = cosf(a), s = sinf(a);
  return (matrix_float4x4){{
      {c, 0, -s, 0}, // column 0
      {0, 1, 0, 0},  // column 1
      {s, 0, c, 0},  // column 2
      {0, 0, 0, 1},  // column 3
  }};
}

static matrix_float4x4 mat_translation(float x, float y, float z) {
  return (matrix_float4x4){{
      {1, 0, 0, 0},
      {0, 1, 0, 0},
      {0, 0, 1, 0},
      {x, y, z, 1},
  }};
}

static matrix_float4x4 mat_perspective(float fovy, float aspect, float nearZ,
                                       float farZ) {
  float ys = 1.0f / tanf(fovy * 0.5f);
  float xs = ys / aspect;
  float zs = farZ / (nearZ - farZ);
  return (matrix_float4x4){{
      {xs, 0, 0, 0},
      {0, ys, 0, 0},
      {0, 0, zs, -1},
      {0, 0, nearZ * zs, 0},
  }};
}

static NSString *const kShaderSource =
    @"#include <metal_stdlib>\n"
    @"using namespace metal;\n"
    @"struct VertexIn  { float2 position; float4 color; };\n"
    @"struct VertexOut { float4 position [[position]]; float4 color; };\n"
    @"vertex VertexOut vertexShader(uint vid [[vertex_id]],\n"
    @"                              constant VertexIn *vertices [[buffer(0)]]) "
    @"{\n"
    @"    VertexOut out;\n"
    @"    out.position = float4(vertices[vid].position, 0.0, 1.0);\n"
    @"    out.color = vertices[vid].color;\n"
    @"    return out;\n"
    @"}\n"
    @"fragment float4 fragmentShader(VertexOut in [[stage_in]]) {\n"
    @"    return in.color;\n"
    @"}\n";

@interface Renderer : NSObject <MTKViewDelegate>
@property(nonatomic, strong) id<MTLDevice> device;
@property(nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property(nonatomic, strong) id<MTLBuffer> vertexBuffer;
@property(nonatomic, strong) id<MTLRenderPipelineState> pipelineState;
- (instancetype)initWithDevice:(id<MTLDevice>)device;
@end

@implementation Renderer
- (instancetype)initWithDevice:(id<MTLDevice>)device {
  self = [super init];
  if (self) {
    _device = device;
    _commandQueue = [device newCommandQueue];

    static const Vertex triangleVertices[] = {
        {{0.0, 0.5}, {1.0, 0.0, 0.0, 1.0}},
        {{-0.5, -0.5}, {0.0, 1.0, 0.0, 1.0}},
        {{0.5, -0.5}, {0.0, 0.0, 1.0, 1.0}},
    };
    _vertexBuffer = [device newBufferWithBytes:triangleVertices
                                        length:sizeof(triangleVertices)
                                       options:MTLResourceStorageModeShared];

    NSError *error = nil;
    id<MTLLibrary> library = [device newLibraryWithSource:kShaderSource
                                                  options:nil
                                                    error:&error];
    if (library == nil) {
      NSLog(@"Shader compile failed: %@", error);
      return self;
    }

    id<MTLFunction> vertexFn = [library newFunctionWithName:@"vertexShader"];
    id<MTLFunction> fragmentFn =
        [library newFunctionWithName:@"fragmentShader"];

    MTLRenderPipelineDescriptor *desc =
        [[MTLRenderPipelineDescriptor alloc] init];
    desc.vertexFunction = vertexFn;
    desc.fragmentFunction = fragmentFn;
    desc.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    _pipelineState = [device newRenderPipelineStateWithDescriptor:desc
                                                            error:&error];
    if (_pipelineState == nil) {
      NSLog(@"Pipeline failed: %@", error);
    }
  }
  return self;
}

- (void)drawInMTKView:(MTKView *)view {
  id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
  MTLRenderPassDescriptor *passDescriptor = view.currentRenderPassDescriptor;
  if (passDescriptor == nil) {
    return;
  }

  id<MTLRenderCommandEncoder> encoder =
      [commandBuffer renderCommandEncoderWithDescriptor:passDescriptor];

  [encoder setRenderPipelineState:self.pipelineState];
  [encoder setVertexBuffer:self.vertexBuffer offset:0 atIndex:0];
  [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];

  [encoder endEncoding];
  [commandBuffer presentDrawable:view.currentDrawable];
  [commandBuffer commit];
}

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
}
@end

int main() {
  @autoreleasepool {
    [NSApplication sharedApplication];
    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];

    NSRect frame = NSMakeRect(0, 0, 600, 600);
    NSWindow *window =
        [[NSWindow alloc] initWithContentRect:frame
                                    styleMask:(NSWindowStyleMaskTitled |
                                               NSWindowStyleMaskClosable)
                                      backing:NSBackingStoreBuffered
                                        defer:NO];
    [window setTitle:@"Triangle"];
    [window center];

    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    if (device == nil) {
      NSLog(@"No Metal GPU.");
      return 1;
    }

    MTKView *mtkView = [[MTKView alloc] initWithFrame:frame device:device];
    mtkView.clearColor = MTLClearColorMake(0.1, 0.1, 0.15, 1.0);

    Renderer *renderer = [[Renderer alloc] initWithDevice:device];
    mtkView.delegate = renderer;
    window.contentView = mtkView;

    [window makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];
    [NSApp run];
  }
  return 0;
}

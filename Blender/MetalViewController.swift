import Cocoa
import MetalKit
import QuartzCore
import simd

protocol MetalViewControllerDelegate : class {
  func updateLogic(_ timeSinceLastUpdate:CFTimeInterval)
  func renderObjects(_ drawable:CAMetalDrawable)
}

class MetalViewController: NSViewController {

  var device: MTLDevice! = nil
  var pipelineState: MTLRenderPipelineState! = nil
  var commandQueue: MTLCommandQueue! = nil
  var projectionMatrix: float4x4!
  @IBOutlet weak var mtkView: MTKView! {
    didSet {
      mtkView.delegate = self
      mtkView.preferredFramesPerSecond = 60
      mtkView.clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
    }
  }
  
  weak var metalViewControllerDelegate:MetalViewControllerDelegate?
  
  override func viewDidLoad() {
    super.viewDidLoad()

    projectionMatrix = float4x4.makePerspectiveViewAngle(float4x4.degrees(toRad: 85.0), aspectRatio: Float(self.view.bounds.size.width / self.view.bounds.size.height), nearZ: 0.01, farZ: 100.0)
    
    
    device = MTLCreateSystemDefaultDevice()
    mtkView.device = device
    commandQueue = device.makeCommandQueue()
    
    let defaultLibrary = device.newDefaultLibrary()
    let fragmentProgram = defaultLibrary!.makeFunction(name: "basic_fragment")
    let vertexProgram = defaultLibrary!.makeFunction(name: "basic_vertex")
    
    
    let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
    pipelineStateDescriptor.vertexFunction = vertexProgram
    pipelineStateDescriptor.fragmentFunction = fragmentProgram
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
    pipelineStateDescriptor.colorAttachments[0].isBlendingEnabled = true
    pipelineStateDescriptor.colorAttachments[0].rgbBlendOperation = MTLBlendOperation.add;
    pipelineStateDescriptor.colorAttachments[0].alphaBlendOperation = MTLBlendOperation.add;
    pipelineStateDescriptor.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactor.one;
    pipelineStateDescriptor.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactor.one;
    pipelineStateDescriptor.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactor.oneMinusSourceAlpha;
    pipelineStateDescriptor.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactor.oneMinusSourceAlpha;
    
    pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
  }

  func render(_ drawable: CAMetalDrawable?) {
    guard let drawable = drawable else { return }
    self.metalViewControllerDelegate?.renderObjects(drawable)
  }

}

// MARK: - MTKViewDelegate
extension MetalViewController: MTKViewDelegate {
  
  // 1
  func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    projectionMatrix = float4x4.makePerspectiveViewAngle(float4x4.degrees(toRad: 85.0),
                                                         aspectRatio: Float(self.view.bounds.size.width / self.view.bounds.size.height),
                                                         nearZ: 0.01, farZ: 100.0)
  }
  
  // 2
  func draw(in view: MTKView) {
    render(view.currentDrawable)
  }
  
}


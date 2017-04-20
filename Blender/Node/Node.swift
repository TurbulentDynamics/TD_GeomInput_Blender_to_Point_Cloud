import Foundation
import Metal
import QuartzCore
import simd

class Node {
  
  var time:CFTimeInterval = 0.0
  
  let name: String
  let light = Light(color: (0.5,0.5,0.5), ambientIntensity: 0.5, direction: (0.0, 0.0, 1.0), diffuseIntensity: 0.1, shininess: 0.1, specularIntensity: 0.2)
  
  var vertexCount: Int
  var vertexBuffer: MTLBuffer
  var device: MTLDevice
  
  var positionX:Float = 0.0
  var positionY:Float = 0.0
  var positionZ:Float = 0.0
  
  var rotationX:Float = 0.0
  var rotationY:Float = 0.0
  var rotationZ:Float = 0.0
  var scale:Float     = 1.0
  
  var rotateMatrix: float4x4?
    
  var bufferProvider: BufferProvider
  lazy var samplerState: MTLSamplerState? = Node.defaultSampler(self.device)
  
  init(name: String, vertices: [Vertex], device: MTLDevice) {
    
    var vertexData = Array<Float>()
    for vertex in vertices {
      vertexData += vertex.floatBuffer()
    }
  
    let dataSize = vertexData.count * MemoryLayout<Float>.size
    vertexBuffer = device.makeBuffer(bytes: vertexData, length: dataSize, options: MTLResourceOptions())
    
    self.name = name
    self.device = device
    vertexCount = vertices.count
    
    self.bufferProvider = BufferProvider(device: device, inflightBuffersCount: 3)
  }
  
  func render(_ commandQueue: MTLCommandQueue, pipelineState: MTLRenderPipelineState, drawable: CAMetalDrawable, parentModelViewMatrix: float4x4, projectionMatrix: float4x4, clearColor: MTLClearColor?) {
    
    let _ = bufferProvider.avaliableResourcesSemaphore.wait(timeout: DispatchTime.distantFuture)
    
    let renderPassDescriptor = MTLRenderPassDescriptor()
    renderPassDescriptor.depthAttachment.loadAction = .clear
    renderPassDescriptor.colorAttachments[0].texture = drawable.texture
    renderPassDescriptor.colorAttachments[0].loadAction = .clear
    renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
    renderPassDescriptor.colorAttachments[0].storeAction = .store
    
    let commandBuffer = commandQueue.makeCommandBuffer()
    commandBuffer.addCompletedHandler { (commandBuffer) -> Void in
      self.bufferProvider.avaliableResourcesSemaphore.signal()
    }
    
    let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
    renderEncoder.setCullMode(MTLCullMode.front)
    
    renderEncoder.setRenderPipelineState(pipelineState)
    renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, at: 0)

    let depthStateDesc = MTLDepthStencilDescriptor()
    depthStateDesc.depthCompareFunction = .less;
    depthStateDesc.isDepthWriteEnabled = true
    let depthState = device.makeDepthStencilState(descriptor: depthStateDesc)
    renderEncoder.setDepthStencilState(depthState)

    if let samplerState = samplerState {
      renderEncoder.setFragmentSamplerState(samplerState, at: 0)
    }
    
    var nodeModelMatrix = self.modelMatrix()
    nodeModelMatrix.multiplyLeft(parentModelViewMatrix)
    
    let uniformBuffer = bufferProvider.nextUniformsBuffer(projectionMatrix, modelViewMatrix: nodeModelMatrix, light: light)
    
    renderEncoder.setVertexBuffer(uniformBuffer, offset: 0, at: 1)
    renderEncoder.setFragmentBuffer(uniformBuffer, offset: 0, at: 1)
    //renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount)
    //renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: vertexCount)
    //renderEncoder.drawPrimitives(type: .line, vertexStart: 0, vertexCount: vertexCount)
    renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: vertexCount)
    renderEncoder.endEncoding()
    
    commandBuffer.present(drawable)
    commandBuffer.commit()
  }
  
  func modelMatrix() -> float4x4 {
    var matrix = float4x4()
    matrix.translate(positionX, y: positionY, z: positionZ)
    matrix.rotateAroundX(rotationX, y: rotationY, z: rotationZ)
    matrix.scale(scale, y: scale, z: scale)
    if let rotateMatrix = rotateMatrix {
      matrix *= rotateMatrix
    }
    return matrix
  }
  
  func updateWithDelta(_ delta: CFTimeInterval) {
    time += delta
  }
  
  class func defaultSampler(_ device: MTLDevice) -> MTLSamplerState {
    let pSamplerDescriptor:MTLSamplerDescriptor? = MTLSamplerDescriptor();
    
    if let sampler = pSamplerDescriptor {
      sampler.minFilter             = MTLSamplerMinMagFilter.nearest
      sampler.magFilter             = MTLSamplerMinMagFilter.nearest
      sampler.mipFilter             = MTLSamplerMipFilter.nearest
      sampler.maxAnisotropy         = 1
      sampler.sAddressMode          = MTLSamplerAddressMode.clampToEdge
      sampler.tAddressMode          = MTLSamplerAddressMode.clampToEdge
      sampler.rAddressMode          = MTLSamplerAddressMode.clampToEdge
      sampler.normalizedCoordinates = true
      sampler.lodMinClamp           = 0
      sampler.lodMaxClamp           = .greatestFiniteMagnitude
    }
    else {
      print(">> ERROR: Failed creating a sampler descriptor!")
    }
    return device.makeSamplerState(descriptor: pSamplerDescriptor!)
  }
}

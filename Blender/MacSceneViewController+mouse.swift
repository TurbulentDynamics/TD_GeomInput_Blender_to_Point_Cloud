//
//  ViewController.swift
//  HelloMetalMac
//

import Cocoa
import simd
import GLKit

private let panSensivity:Float = 5.0
private var lastLocation: CGPoint!
private var trackedTouch: NSTouch?

private var anchorPosition: GLKVector3!
private var currentPosition: GLKVector3!
private var quatStart: GLKQuaternion!
private var quat: GLKQuaternion!

extension MacSceneViewController {
  
  // MARK: mouse
  // MARK: right
  
  override func rightMouseDown(with event: NSEvent) {
    lastLocation = event.locationInWindow
  }
  
  override func rightMouseDragged(with event: NSEvent) {
    let xDelta = Float((lastLocation.x - event.locationInWindow.x)/self.view.bounds.width)
    let yDelta = Float((lastLocation.y - event.locationInWindow.y)/self.view.bounds.height)
    print(xDelta, yDelta)
    
    worldModelMatrix.translate(-3*xDelta, y: -3*yDelta, z: 0)
    lastLocation = event.locationInWindow
  }
  
  // MARK: left
  
  override func mouseDown(with event: NSEvent) {
    anchorPosition = projectOntoSurface(location: event.locationInWindow)
    currentPosition = anchorPosition
    if quat == nil {
      quat = GLKQuaternionMake(0, 0, 0, 1)
    }
    
    quatStart = quat
  }
  
  override func mouseDragged(with event: NSEvent) {
    currentPosition = projectOntoSurface(location: event.locationInWindow)
    computeIncremental()
  }
  
  // MARK: scroll
  
  override func scrollWheel(with event: NSEvent) {
    if event.subtype == .mouseEvent {
      vectorsObject!.scale -= Float(event.deltaY) * vectorsObject!.scale
    }
  }

  
  // MARK: trackpad
  
  override func magnify(with event: NSEvent) {
    vectorsObject!.scale += Float(event.magnification) * vectorsObject!.scale
  }
  
  override func touchesBegan(with event: NSEvent) {

    let touches = event.touches(matching: .touching, in: self.view)
    if (touches.count == 2) {
      trackedTouch = touches.first
      let point = trackedTouch!.normalizedPosition
      lastLocation = NSPoint(x: point.x * view.bounds.width, y: point.y * view.bounds.height)
    }
  }
  
  override func touchesMoved(with event: NSEvent) {
    
    let touches = event.touches(matching: .touching, in: self.view)
    
    if (touches.count == 2) {
      
      guard let tracked = trackedTouch else {
        return
      }

      for touch in touches {
        if tracked.identity.isEqual(touch.identity) {
          trackedTouch = touch
        }
      }

      let point = tracked.normalizedPosition
      let loc = NSPoint(x: point.x * view.bounds.width, y: point.y * view.bounds.height)

      let xDelta = Float((lastLocation.x - loc.x)/self.view.bounds.width)
      let yDelta = Float((lastLocation.y - loc.y)/self.view.bounds.height)

      worldModelMatrix.translate(-xDelta, y: -yDelta, z: 0)
      lastLocation = loc
    }
  }
  
  override func touchesEnded(with event: NSEvent) {
    trackedTouch = nil
  }
  
  
  
  func projectOntoSurface(location: NSPoint) -> GLKVector3 {
    let locationVector = GLKVector3Make(Float(location.x), Float(location.y), 0)
    let center = GLKVector3Make(Float(view.bounds.midX), Float(view.bounds.midY), 0)
    var P = GLKVector3Subtract(locationVector, center)
    
    // Flip the x and y axis because pixel coords increase toward the bottom.
    P = GLKVector3Make(-P.x, -P.y, P.z)
    
    let radius = Float(view.bounds.midY)
    let radius2 = radius * radius
    let length2: Float = P.x * P.x + P.y * P.y
    
    if length2 <= Float(radius2) {
      P = GLKVector3Make(P.x, P.y, sqrt(radius2 - length2))
    } else {
      //let k = Float(radius) / sqrt(length2)
      //P = GLKVector3Make(P.x * k, P.y * k, 0)
      
      P = GLKVector3Make(P.x, P.y, radius2 / (2.0 * sqrt(length2)))
      let length: Float = sqrt(length2 + P.z * P.z);
      P = GLKVector3DivideScalar(P, length);
    }
    
    return GLKVector3Normalize(P);
  }
  
  func computeIncremental() {
    let axis = GLKVector3CrossProduct(anchorPosition, currentPosition)
    let dot = GLKVector3DotProduct(anchorPosition, currentPosition)
    let angle = acosf(dot)
    
    var Q_rot = GLKQuaternionMakeWithAngleAndVector3Axis(angle * 2, axis)
    Q_rot = GLKQuaternionNormalize(Q_rot)
    
    quat = GLKQuaternionMultiply(Q_rot, quatStart)
    
    var modelViewMatrix = float4x4()
    modelViewMatrix.translate(0.0, y: 0.0, z: -1)
    let rotation:float4x4 = convertToFloat4x4FromGLKMatrix(matrix: GLKMatrix4MakeWithQuaternion(quat))
    modelViewMatrix = modelViewMatrix * rotation
    //worldModelMatrix = modelViewMatrix * rotation
    
    vectorsObject?.rotateMatrix = rotation
  }
  
  func convertToFloat4x4FromGLKMatrix(matrix: GLKMatrix4) -> float4x4 {
    return float4x4(rows: [float4( matrix.m00,matrix.m01,matrix.m02,matrix.m03 ),
                           float4( matrix.m10,matrix.m11,matrix.m12,matrix.m13 ),
                           float4( matrix.m20,matrix.m21,matrix.m22,matrix.m23 ),
                           float4( matrix.m30,matrix.m31,matrix.m32,matrix.m33 )] )
  }

  
}

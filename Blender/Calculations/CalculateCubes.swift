//
//  CalculateCubes.swift
//  Blender
//

import Cocoa
import simd

class CalculateCubes: NSObject {
  
  func getCubedVertices(incomingData: IncomingData!, cubes: Int) -> [Vertex] {
    
    let scaleAndMin = getScaleAndMin(verticesArray: incomingData.verticesArray)
    let scale = scaleAndMin[0] / Float(cubes)
    let min = float3(scaleAndMin[1], scaleAndMin[2], scaleAndMin[3])
    let cubedVertices = CalculateAdditionalPoints().createCubedMatrix(incomingData: incomingData, scale: scale, cubes: cubes, min: min)
    
    return cubedVertices
  }
  
  private func hasVertice(cubedVertices: [Vertex], vertice: Vertex) -> Bool {
    if cubedVertices.count == 0 {
      return false
    }
    
    for cubedVertice in cubedVertices {
      if cubedVertice.x == vertice.x && cubedVertice.y == vertice.y && cubedVertice.z == vertice.z {
        return true
      }
    }
    return false
  }
  
  private func getScaleAndMin(verticesArray: [Vertex]) -> [Float] {
    var minX: Float = .greatestFiniteMagnitude
    var maxX: Float = .leastNormalMagnitude
    var minY: Float = .greatestFiniteMagnitude
    var maxY: Float = .leastNormalMagnitude
    var minZ: Float = .greatestFiniteMagnitude
    var maxZ: Float = .leastNormalMagnitude
    for vertice in verticesArray {
      minX = min(minX, vertice.x)
      maxX = max(maxX, vertice.x)
      minY = min(minY, vertice.y)
      maxY = max(maxY, vertice.y)
      minZ = min(minZ, vertice.z)
      maxZ = max(maxZ, vertice.z)
    }
    print("SCALE = ")
    print(minX, maxX, minY, maxY, minZ, maxZ)
    let maxScale = max(max(maxX - minX, maxY-minY), maxZ-minZ)
    print(maxScale)
    return [maxScale, minX, minY, minZ]
  }
  
}

//
//  CalculateAdditionalPoints.swift
//  Blender
//

import Cocoa
import simd

struct OutputPatch {
  var WorldPos_B030: float3
  var WorldPos_B021: float3
  var WorldPos_B012: float3
  var WorldPos_B003: float3
  var WorldPos_B102: float3
  var WorldPos_B201: float3
  var WorldPos_B300: float3
  var WorldPos_B210: float3
  var WorldPos_B120: float3
  var WorldPos_B111: float3
  var Normal: [float3]
  
  init() {
    WorldPos_B030 = float3()
    WorldPos_B021 = float3()
    WorldPos_B012 = float3()
    WorldPos_B003 = float3()
    WorldPos_B102 = float3()
    WorldPos_B201 = float3()
    WorldPos_B300 = float3()
    WorldPos_B210 = float3()
    WorldPos_B120 = float3()
    WorldPos_B111 = float3()
    Normal = [float3](repeatElement(float3(), count: 3))
  }
}

class CalculateAdditionalPoints: NSObject {
  
  var cubedMatrix: Array3D!
  var count = 0
  
  func createCubedMatrix(incomingData: IncomingData!, scale: Float, cubes: Int, min: float3) -> [Vertex] {
    let date = NSDate()
    
    cubedMatrix = Array3D.init(x: cubes, y: cubes, z: cubes)

    // add vertices
    for vertice in incomingData.verticesArray {
      let cubedVertex = self.getCubedVertice(vertex: vertice, scale: scale, min: min)
      if cubedMatrix[Int(cubedVertex.x), Int(cubedVertex.y), Int(cubedVertex.z)] == false {
        count += 1
        cubedMatrix[Int(cubedVertex.x), Int(cubedVertex.y), Int(cubedVertex.z)] = true
      }
    }

    // add middle points
    for face in incomingData.faces {
      self.getNewPoints(incomingData: incomingData, face: face, scale: scale, min: min)
    }
    
    print("created cubedMatrix: \(date.timeIntervalSinceNow)")
    let date2 = NSDate()
    print("count cubedMatrix: \(count)")
    
    var resultVerticesArray = [Vertex?](repeating:nil, count: count)

    var countVertices = 0
    for x in 0...cubes-1 {
      for y in 0...cubes-1 {
        for z in 0...cubes-1 {
          if cubedMatrix[Int(x), Int(y), Int(z)] == true {
            resultVerticesArray[countVertices] = Vertex(x: Float(x), y: Float(y), z: Float(z), nX: 0, nY: 0, nZ: 0)
            countVertices += 1
          }
        }
      }
    }
    print("resultVerticesArray count: \(resultVerticesArray.count)")
    print("created resultVerticesArray: \(date2.timeIntervalSinceNow)")
    print("Total createCubedMatrix: \(date.timeIntervalSinceNow)")
    
    return resultVerticesArray as! [Vertex]
  }
  
  private func getCubedVertice(vertex: Vertex, scale: Float, min: float3) -> int3 {
    let x = Int32( (vertex.x - min.x) / scale)
    let y = Int32( (vertex.y - min.y) / scale)
    let z = Int32( (vertex.z - min.z) / scale)
    return int3(x, y, z)
  }
  
  private func getNewPoints(incomingData: IncomingData!, face: [Int32], scale:Float, min: float3) {
    
    var oPatch: OutputPatch!
    
    let vertices = incomingData.vertices
    
    oPatch = OutputPatch()
    
    let point0 = vertices[Int(face[0])]
    oPatch.WorldPos_B030 = [point0[0], point0[1], point0[2]]
    
    let point1 = vertices[Int(face[2])]
    oPatch.WorldPos_B003 = [point1[0], point1[1], point1[2]]
    
    let point2 = vertices[Int(face[4])]
    oPatch.WorldPos_B300 = [point2[0], point2[1], point2[2]]
    
    let maxDistance = maxDistance3(point0: point0, point1: point1, point2: point2)
    
    guard maxDistance >= 2 * scale else {
      return
    }
    
    let multiplier = Int(maxDistance / scale)
    
    let normals = incomingData.normals
    let normal0 = normals[Int(face[1])]
    oPatch.Normal[0] = [normal0[0], normal0[1], normal0[2]]
    
    let normal1 = normals[Int(face[3])]
    oPatch.Normal[1] = [normal1[0], normal1[1], normal1[2]]
    
    let normal2 = normals[Int(face[5])]
    oPatch.Normal[2] = [normal2[0], normal2[1], normal2[2]]
    
    let EdgeB300 = oPatch.WorldPos_B003 - oPatch.WorldPos_B030
    let EdgeB030 = oPatch.WorldPos_B300 - oPatch.WorldPos_B003
    let EdgeB003 = oPatch.WorldPos_B030 - oPatch.WorldPos_B300
    
    // Generate two midpoints on each edge
    oPatch.WorldPos_B021 = oPatch.WorldPos_B030 + EdgeB300 * Float(1.0 / 3.0)
    oPatch.WorldPos_B012 = oPatch.WorldPos_B030 + EdgeB300 * Float(2.0 / 3.0)
    oPatch.WorldPos_B102 = oPatch.WorldPos_B003 + EdgeB030 * Float(1.0 / 3.0)
    oPatch.WorldPos_B201 = oPatch.WorldPos_B003 + EdgeB030 * Float(2.0 / 3.0)
    oPatch.WorldPos_B210 = oPatch.WorldPos_B300 + EdgeB003 * Float(1.0 / 3.0)
    oPatch.WorldPos_B120 = oPatch.WorldPos_B300 + EdgeB003 * Float(2.0 / 3.0)
    
    // Project each midpoint on the plane defined by the nearest vertex and its normal
    oPatch.WorldPos_B021 = ProjectToPlane(oPatch.WorldPos_B021, oPatch.WorldPos_B030, oPatch.Normal[0]);
    oPatch.WorldPos_B012 = ProjectToPlane(oPatch.WorldPos_B012, oPatch.WorldPos_B003, oPatch.Normal[1]);
    oPatch.WorldPos_B102 = ProjectToPlane(oPatch.WorldPos_B102, oPatch.WorldPos_B003, oPatch.Normal[1]);
    oPatch.WorldPos_B201 = ProjectToPlane(oPatch.WorldPos_B201, oPatch.WorldPos_B300, oPatch.Normal[2]);
    oPatch.WorldPos_B210 = ProjectToPlane(oPatch.WorldPos_B210, oPatch.WorldPos_B300, oPatch.Normal[2]);
    oPatch.WorldPos_B120 = ProjectToPlane(oPatch.WorldPos_B120, oPatch.WorldPos_B030, oPatch.Normal[0]);
    
    //print("oPatch.WorldPos_B021: \(oPatch.WorldPos_B021)")
    
    // Handle the center
    let Center = (oPatch.WorldPos_B003 + oPatch.WorldPos_B030 + oPatch.WorldPos_B300) * Float(1.0 / 3.0)
    oPatch.WorldPos_B111 = (oPatch.WorldPos_B021 + oPatch.WorldPos_B012 + oPatch.WorldPos_B102 +
      oPatch.WorldPos_B201 + oPatch.WorldPos_B210 + oPatch.WorldPos_B120) * Float(1.0 / 6.0)
    oPatch.WorldPos_B111 += (oPatch.WorldPos_B111 - Center) * Float(1.0 / 2.0)
    
    //print("oPatch.WorldPos_B111: \(oPatch.WorldPos_B111)")
    
    for x in 0...(multiplier-1) {
      for y in 0...(multiplier-x) {
        let u = Float(x)/Float(multiplier)
        let v = Float(y)/Float(multiplier)
        let w = 1.0 - u - v
        
        // calculate Normal
        //let normal111 = float3(u) * oPatch.Normal[0] + float3(v) * oPatch.Normal[1] + float3(w) * oPatch.Normal[2]
        
        let uPow3 = pow(u, 3);
        let vPow3 = pow(v, 3);
        let wPow3 = pow(w, 3);
        let uPow2 = pow(u, 2);
        let vPow2 = pow(v, 2);
        let wPow2 = pow(w, 2);
        
        let point111 = oPatch.WorldPos_B300 * wPow3 +
          oPatch.WorldPos_B030 * uPow3 +
          oPatch.WorldPos_B003 * vPow3 +
          oPatch.WorldPos_B210 * 3.0 * wPow2 * u +
          oPatch.WorldPos_B120 * 3.0 * w * uPow2 +
          oPatch.WorldPos_B201 * 3.0 * wPow2 * v +
          oPatch.WorldPos_B021 * 3.0 * uPow2 * v +
          oPatch.WorldPos_B102 * 3.0 * w * vPow2 +
          oPatch.WorldPos_B012 * 3.0 * u * vPow2 +
          oPatch.WorldPos_B111 * 6.0 * w * u * v
        
        if max(maxDistance2(point0: point0, point1: point111), maxDistance2(point0: point1, point1: point111), maxDistance2(point0: point2, point1: point111)) > scale {
          let vertice  = Vertex(x: point111.x, y: point111.y, z: point111.z, nX: 0, nY: 0, nZ: 0)
          let cubedVertex = self.getCubedVertice(vertex: vertice, scale: scale, min: min)
          if cubedMatrix[Int(cubedVertex.x), Int(cubedVertex.y), Int(cubedVertex.z)] == false {
            count += 1
            cubedMatrix[Int(cubedVertex.x), Int(cubedVertex.y), Int(cubedVertex.z)] = true
          }

        }
      }
    }
  }
  
  private func ProjectToPlane(_ Point: float3, _ PlanePoint: float3, _ PlaneNormal: float3) -> float3 {
    let v = Point - PlanePoint;
    let Len = dot(v, PlaneNormal);
    let d = Len * PlaneNormal;
    return (Point - d);
  }
  
  private func maxDistance2(point0:float3, point1:float3) -> Float {
    let v0 = point0 - point1
    return max(fabsf(v0.x), fabsf(v0.y), fabsf(v0.z))
  }
  
  private func maxDistance3(point0:float3, point1:float3, point2:float3) -> Float {
    return max(maxDistance2(point0: point0, point1: point1), maxDistance2(point0: point0, point1: point2), maxDistance2(point0: point1, point1: point2))
  }
  
}

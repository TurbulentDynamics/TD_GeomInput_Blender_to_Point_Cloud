import Foundation
import simd

class IncomingData: NSObject {
  
  let multiplier: Float32 = 1
  
  var verticesArray: [Vertex] = []
  
  var vertices: [float3] = []
  var normals: [float3] = []
  var faces: [[Int32]] = []
  
  let deleteCache = true
  
  // MARK: - func
  
  func readDataFromFile(contents: String) {
    autoreleasepool {
      let date = NSDate()
      
      var arrayOfLines = contents.components(separatedBy: "\n")
      
      self.vertices = self.getVertices(arrayOfLines: arrayOfLines)
      self.normals = self.getNormals(arrayOfLines: arrayOfLines)
      self.faces = self.getFaces(arrayOfLines: arrayOfLines)
      
      arrayOfLines = arrayOfLines.filter{$0.hasPrefix("f ")}
      self.createVerticesArray()
      
      print("Total read time: \(date.timeIntervalSinceNow)")
      print("self.faces.count = \(self.faces.count)")
      print("self.verticesArray.count = \(self.verticesArray.count)")
    }
  }
  
  func addVertice(point:float3, normal:float3) {
    verticesArray += [Vertex(x:point.x*multiplier, y:point.y*multiplier, z:point.z*multiplier, nX:normal.x, nY:normal.y, nZ:normal.z)]
  }
  
  // MARK: - private
  
  private func getVertices(arrayOfLines: [String]) -> [float3] {
    let date = NSDate()
    var array: [float3] = []
    
    autoreleasepool {
      
      var arrayOfLinesV = arrayOfLines.filter{$0.hasPrefix("v ")}
      array = [float3](repeating:float3(), count:arrayOfLinesV.count)
      
      print(array.count)
      
      array.withUnsafeMutableBufferPointer({ res in
        DispatchQueue.concurrentPerform(iterations: arrayOfLinesV.count, execute: { i in
          autoreleasepool {
            let points = arrayOfLinesV[i].components(separatedBy:" ").map{ Float32($0) }
            if points.count == 4, let x = points[1], let y = points[2], let z = points[3] {
              res[i] = float3(x, y, z)
            }
          }
        })
      })
    }
    
    print("getVertices time: \(date.timeIntervalSinceNow)")
    return array
  }
  
  
  private func getNormals(arrayOfLines: [String]) -> [float3] {
    let date = NSDate()
    var array: [float3] = []
    
    autoreleasepool {
      
      var arrayOfLinesN = arrayOfLines.filter{$0.hasPrefix("vn ")}
      array = [float3](repeating:float3(), count:arrayOfLinesN.count)
      
      array.withUnsafeMutableBufferPointer({ res in
        DispatchQueue.concurrentPerform(iterations: arrayOfLinesN.count, execute: { i in
          autoreleasepool {
            let normals = arrayOfLinesN[i].components(separatedBy:" ").map{ Float32($0) }
            if normals.count == 4, let xn = normals[1], let yn = normals[2], let zn = normals[3] {
              res[i] = float3(xn, yn, zn)
            }
          }
        })
      })
    }
    
    print("getNormals time: \(date.timeIntervalSinceNow)")
    return array
  }
  
  private func getFaces(arrayOfLines: [String]) -> [[Int32]] {
    let date = NSDate()
    var array: [[Int32]] = []
    
    autoreleasepool {
      
      var lines = arrayOfLines.filter{$0.hasPrefix("f ")}
      //print(lines)
      array = [[Int32]](repeating:[Int32](repeating: 0, count:3), count:lines.count)
      
      print("create faces.data")
      
      array.withUnsafeMutableBufferPointer({ res in
        DispatchQueue.concurrentPerform(iterations: lines.count, execute: { i in
          autoreleasepool {
            var faces: [[Int32]] = []
            let facesStings = lines[i].components(separatedBy:" ")
            for face in facesStings {
              if face == "f" { continue }
              let points = face.components(separatedBy:"/").map{ Int32($0) }
              if points.count == 3 {
                let a = points[0] ?? 0
                let b = points[1] ?? 0
                let c = points[2] ?? 0
                faces += [[a-1, b-1, c-1]]
              }
              //print(face)
              
            }
            
            if faces.count == 3 {
              var triangleResult: [Int32] = []
              for triangle in faces {
                triangleResult += [triangle[0], triangle[2]]
              }
              res[i] = triangleResult
            }
            
          }
        })
      })
    }
    
    print("faces: \(array.count) size: \(array.count * MemoryLayout<Float32>.size / 1024)")
    print("getFaces time: \(date.timeIntervalSinceNow)")
    return array
  }
  
  private func createVerticesArray() {
    var array = [Vertex]()
    
    autoreleasepool {
      let date = NSDate()
      
      for face in faces {
        autoreleasepool {
          var point = vertices[Int(face[0])]
          var normal = normals[Int(face[1])]
          array += [Vertex(x:point.x*multiplier, y:point.y*multiplier, z:point.z*multiplier, nX:normal.x, nY:normal.y, nZ:normal.z)]
          point = vertices[Int(face[2])]
          normal = normals[Int(face[3])]
          array += [Vertex(x:point.x*multiplier, y:point.y*multiplier, z:point.z*multiplier, nX:normal.x, nY:normal.y, nZ:normal.z)]
          point = vertices[Int(face[4])]
          normal = normals[Int(face[5])]
          array += [Vertex(x:point.x*multiplier, y:point.y*multiplier, z:point.z*multiplier, nX:normal.x, nY:normal.y, nZ:normal.z)]
        }
      }
      print("createVerticesArray time: \(date.timeIntervalSinceNow)")
      self.verticesArray = array
    }
    
    print("self.faces.count = \(self.faces.count)")
    print("self.verticesArray.count = \(self.verticesArray.count)")
  }
  
}


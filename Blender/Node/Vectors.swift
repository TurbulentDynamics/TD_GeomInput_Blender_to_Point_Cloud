import MetalKit

class Vectors: Node {
    
  init(vertices: [Vertex], device: MTLDevice, commandQ: MTLCommandQueue) {
        
        let verticesArray = (vertices.count != 0) ? vertices : [Vertex(x: 0, y: 0, z: 0, nX: 0, nY: 0, nZ: 0)]
        
        super.init(name: "Vectors", vertices: verticesArray, device: device)
    }
    
}

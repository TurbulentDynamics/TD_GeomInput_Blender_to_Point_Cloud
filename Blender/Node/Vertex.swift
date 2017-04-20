struct Vertex {
    
    var x,y,z: Float     // position data
    var nX,nY,nZ: Float  // normal
    
    func floatBuffer() -> [Float] {
        return [x,y,z,nX,nY,nZ]
    }
}

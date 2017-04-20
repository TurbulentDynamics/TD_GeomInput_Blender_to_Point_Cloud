//
//  Array3D.swift
//  Blender
//

import Cocoa

class Array3D {
  private let xMax: Int
  private let yMax: Int
  private let zMax: Int
  
  private var array: [Bool]
  
  init(x: Int, y: Int, z: Int) {
    self.xMax = x
    self.yMax = y
    self.zMax = z
    
    array = Array(repeating: false, count:x * y * z)
  }
  
  subscript(x: Int, y: Int, z: Int) -> Bool {
    get {
      return array[z * yMax * xMax + y * xMax + x]
    }
    set(newValue) {
      let xN = x < 0 ? 0 : x > xMax ? xMax : x
      let yN = y < 0 ? 0 : y > yMax ? yMax : y
      let zN = z < 0 ? 0 : z > zMax ? zMax : z
      array[zN * yMax * xMax + yN * xMax + xN] = newValue
    }
  }
  
}

//
//  ViewController.swift
//  HelloMetalMac
//

import Cocoa
import simd
import GLKit

class MacSceneViewController: MetalViewController, MetalViewControllerDelegate, NSTextFieldDelegate {
  
  var worldModelMatrix:float4x4!
  
  var incomingData: IncomingData!
  var vectorsObject: Vectors!
  var vertices: [Vertex]!
  
  var scaleCubes: Int = 20
  
  @IBOutlet weak var cubesCountTextField: NSTextField!
  
  // MARK: - view
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // adjist view
    view.acceptsTouchEvents = true
    cubesCountTextField.stringValue = String(scaleCubes)
 
    worldModelMatrix = float4x4()
    metalViewControllerDelegate = self
    
    // open file
    let path = Bundle.main.path(forResource: "Sails_full", ofType:"obj")
    let string = try? String(contentsOf: URL(fileURLWithPath: path!))
    incomingData = IncomingData()
    incomingData.readDataFromFile(contents: string!)
    
    vertices = CalculateCubes().getCubedVertices(incomingData: incomingData, cubes: scaleCubes)
    vectorsObject = Vectors(vertices: vertices, device: device, commandQ: commandQueue)
    
    print(vectorsObject.vertexCount)
    
    vectorsObject.scale = 0.03
    worldModelMatrix.translate(0.0, y: 0.0, z: -1)
    
    // create open file function
    NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "OpenFile"), object: nil, queue: .current) { notification in
      if let contents = notification.object as? String {
        let date = NSDate()

        self.cubesCountTextField.stringValue = String(self.scaleCubes)
        self.incomingData.readDataFromFile(contents: contents)
        
        self.vertices = CalculateCubes().getCubedVertices(incomingData: self.incomingData, cubes: self.scaleCubes)
        self.vectorsObject = Vectors(vertices: self.vertices, device: self.device, commandQ: self.commandQueue)
        
        self.vectorsObject.scale = 0.03
        self.worldModelMatrix.translate(0.0, y: 0.0, z: -1)
        print("Total: \(date.timeIntervalSinceNow)")
      }
    }
  }
  
  
  // MARK: button
  
  @IBAction func applyButton(_ sender: NSButton) {
    let cubes = Int(cubesCountTextField.intValue)
    
    if vectorsObject != nil && cubes > 0 {
      
      let scale = vectorsObject.scale
      let positionX = vectorsObject.positionX
      let positionY = vectorsObject.positionY
      let positionZ = vectorsObject.rotationZ
      let rotationX = vectorsObject.rotationX
      let rotationY = vectorsObject.rotationY
      let rotationZ = vectorsObject.rotationZ
      
      vertices = CalculateCubes().getCubedVertices(incomingData: incomingData, cubes: cubes)
      
      vectorsObject = Vectors(vertices: vertices, device: device, commandQ: commandQueue)
      
      vectorsObject.scale = scale
      vectorsObject.positionX = positionX
      vectorsObject.positionY = positionY
      vectorsObject.positionZ = positionZ
      vectorsObject.rotationX = rotationX
      vectorsObject.rotationY = rotationY
      vectorsObject.rotationZ = rotationZ
    }
  }
  
  override func controlTextDidEndEditing(_ obj: Notification) {
    applyButton(NSButton())
  }
  
  @IBAction func exportButton(_ sender: Any) {
    
    let name = "points.txt"
    
    let panel = NSSavePanel()
    panel.nameFieldStringValue = name
    let window = view.window
    
    panel.beginSheetModal(for: window!) { result in
      guard result == NSFileHandlingPanelOKButton  else {
        return
      }
      
      var txt = "POINT CLOUD TEXT\n"
      txt += "comment\n"
      txt += "comment\n"
      let count = self.vectorsObject.vertexCount
      txt += "nx \(count) ny \(count) nz \(count)\n"
      
      for vector in self.vertices {
        txt += "\(Int(vector.x)) \(Int(vector.y)) \(Int(vector.z))\n"
      }
      
      guard let url = panel.url  else {
        return
      }
      
      do {
        try txt.write(to: url, atomically: true, encoding: .utf8)
      } catch {
        print("save error \(error)")
      }
    }
  }
  
  //MARK: - MetalViewControllerDelegate
  func renderObjects(_ drawable:CAMetalDrawable) {
    if self.vectorsObject != nil {
      vectorsObject.render(commandQueue, pipelineState: pipelineState, drawable: drawable, parentModelViewMatrix: worldModelMatrix, projectionMatrix: projectionMatrix, clearColor: nil)
    }
  }
  
  func updateLogic(_ timeSinceLastUpdate: CFTimeInterval) {
    vectorsObject.updateWithDelta(timeSinceLastUpdate)
  }
  
}

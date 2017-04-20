//
//  AppDelegate.swift
//  HelloMetalMac
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {


    func applicationDidFinishLaunching(_ aNotification: Notification) {

        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    @IBAction func openFile(_ sender: AnyObject) {
        let openPanel = NSOpenPanel()
        openPanel.title = "Choose a obj file"
        
        openPanel.begin() { result in
            if result == NSFileHandlingPanelOKButton {
                let string = try? String.init(contentsOf: openPanel.urls.first!)
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "OpenFile"), object: string)
            }
        }
    }
}


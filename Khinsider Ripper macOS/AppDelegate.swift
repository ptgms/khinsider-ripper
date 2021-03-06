//
//  AppDelegate.swift
//  Khinsider Ripper macOS
//
//  Created by ptgms on 23.05.20.
//  Copyright © 2020 ptgms. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var downloadDirectlyToggle: NSMenuItem!
    @IBOutlet weak var getDownloadLinkToggle: NSMenuItem!
    

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    @IBAction func downloadSelected(_ sender: Any) {
        NotificationCenter.default.post(name: Notification.Name("downloadSelected"), object: nil)
    }
    
    @IBAction func downloadAll(_ sender: Any) {
        NotificationCenter.default.post(name: Notification.Name("downloadAllTitle"), object: nil)
    }
    
    @IBAction func openDownloadFolder(_ sender: Any) {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dataPath = documentsDirectory.appendingPathComponent("/Khinsider/")
        NSWorkspace.shared.open(dataPath)
    }
    
    @IBAction func downloadDirectlyPressed(_ sender: Any) {
        downloadDirectlyToggle.state = .on
        getDownloadLinkToggle.state = .off
        
        GlobalVar.downloadDirect = true
        
    }
    
    @IBAction func getDownloadPressed(_ sender: Any) {
        downloadDirectlyToggle.state = .off
        getDownloadLinkToggle.state = .on
        
        GlobalVar.downloadDirect = false
        
    }
    
}


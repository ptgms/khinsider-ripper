//
//  WindowController.swift
//  Khinsider Ripper macOS
//
//  Created by ptgms on 07.06.20.
//  Copyright © 2020 ptgms. All rights reserved.
//

import Cocoa

class WindowController: NSWindowController {

    @IBOutlet weak var downloadTrackButton: NSButton!
    @IBOutlet weak var DownloadAlbumButton: NSButton!
    @IBOutlet weak var playpauseButton: NSButton!
    
    
    override func windowDidLoad() {
        super.windowDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(updateBar), name: Notification.Name("updateBar"), object: nil)
        
    }
    
    @objc func updateBar() {
        //downloadTrackButton.isHidden = GlobalVar.touch_track
        //DownloadAlbumButton.isHidden = GlobalVar.touch_album
        
        if (GlobalVar.touch_playing == true) {
            playpauseButton.image = NSImage(named: "SF_touchbar_pause")
        } else {
            playpauseButton.image = NSImage(named: "SF_touchbar_play")
        }
    }
    
    @IBAction func touchbarPlayPause(_ sender: Any) {
        NotificationCenter.default.post(name: Notification.Name("playPause"), object: nil)
    }
    
    @IBAction func downloadAlbumPressed(_ sender: Any) {
        NotificationCenter.default.post(name: Notification.Name("downloadAll"), object: nil)
    }
    
    @IBAction func downloadTrackPressed(_ sender: Any) {
        NotificationCenter.default.post(name: Notification.Name("downloadSelected"), object: nil)
    }
    
    @IBAction func openDownloadsPressed(_ sender: Any) {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dataPath = documentsDirectory.appendingPathComponent("/Khinsider/")
        NSWorkspace.shared.open(dataPath)
    }
    
    
}

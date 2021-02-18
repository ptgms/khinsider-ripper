//
//  batchDownloaderViewController.swift
//  Khinsider Ripper macOS
//
//  Created by ptgms on 23.05.20.
//  Copyright © 2020 ptgms. All rights reserved.
//

import Cocoa
import Foundation

class batchDownloaderViewController: NSViewController, NSUserNotificationCenterDelegate {
    @IBOutlet weak var progressLabel: NSTextField!
    @IBOutlet weak var progressText: NSTextField!
    @IBOutlet weak var progressBar: NSProgressIndicator!
    
    var recdata = ""
    var total = GlobalVar.tracks.count
    var downloading = false
    var inte = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateRec), name: Notification.Name("progUp"), object: nil)
    }
    
    func showNotification(title: String, body: String) -> Void {
        let notification = NSUserNotification()
        notification.title = title
        notification.subtitle = body
        notification.soundName = NSUserNotificationDefaultSoundName
        NSUserNotificationCenter.default.delegate = self
        NSUserNotificationCenter.default.deliver(notification)
    }
    
    func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
        return true
    }
    
    @IBAction func cancelledPressed(_ sender: Any) {
        GlobalVar.cancelled = true
    }
    
    @objc func updateRec() {
        self.progressBar.maxValue = GlobalVar.progressVal
        self.progressBar.doubleValue = GlobalVar.progressValNow
        self.progressLabel.stringValue = GlobalVar.nowDownload
        self.progressText.stringValue = GlobalVar.nowDownloadDet
    }
}

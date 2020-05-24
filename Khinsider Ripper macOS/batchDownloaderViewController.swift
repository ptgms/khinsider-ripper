//
//  batchDownloaderViewController.swift
//  Khinsider Ripper macOS
//
//  Created by ptgms on 23.05.20.
//  Copyright © 2020 ptgms. All rights reserved.
//

import Cocoa
import Foundation

class batchDownloaderViewController: NSViewController {
    @IBOutlet weak var progressLabel: NSTextField!
    @IBOutlet weak var progressText: NSTextField!
    
    var recdata = ""
    var total = GlobalVar.tracks.count
    var downloading = false
    var inte = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dataPath = documentsDirectory.appendingPathComponent("/Khinsider/" + GlobalVar.AlbumName)
        
        do {
            try FileManager.default.createDirectory(atPath: dataPath.path, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            print("Error creating directory: \(error.localizedDescription)")
        }
        
        progressLabel.stringValue = "Downloading " + GlobalVar.AlbumName
        progressText.stringValue = "Downloading 1 / " + String(total)
        
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1;
        print(GlobalVar.download_queue)
        self.load(url: GlobalVar.download_queue, name: GlobalVar.tracks, type: GlobalVar.download_type)
    }
    
    func transitionToMain() {
        print("RETURN TO MAIN!")
        self.view.window?.close()
    }
    
    func load(url: [URL], name: [String], type: String) {
        print("Got here with request " + url[inte].absoluteString)
        
        let downloadTask = URLSession.shared.downloadTask(with: url[inte]) {
            urlOrNil, responseOrNil, errorOrNil in

            guard let fileURL = urlOrNil else { return }
            do {
                let documentsURL = try
                    FileManager.default.url(for: .documentDirectory,
                                            in: .userDomainMask,
                                            appropriateFor: nil,
                                            create: false)
                let savedURL = documentsURL.appendingPathComponent("/Khinsider/" + GlobalVar.AlbumName + "/" + name[self.inte] + GlobalVar.download_type)
                
                try FileManager.default.moveItem(at: fileURL, to: savedURL)
                self.downloading = true
                print("Done!")
                DispatchQueue.main.sync() {
                    self.progressText.stringValue = "Downloading " + String(self.inte + 2) + " / " + String(self.total)
                    self.downloading = false
                    self.inte += 1
                    if self.inte == GlobalVar.trackURL.count {
                        self.transitionToMain()
                        return
                    }
                    self.load(url: url, name: name, type: type)
                    
                }
            } catch {
                DispatchQueue.main.sync() {
                    self.progressText.stringValue = "Downloading " + String(self.inte + 2) + " / " + String(self.total)
                    self.downloading = false
                    self.inte += 1
                    if self.inte == GlobalVar.trackURL.count {
                        self.transitionToMain()
                        return
                    }
                    self.load(url: url, name: name, type: type)
                }
                print ("file error: \(error)")
            }
        }
        downloadTask.resume()
    }
    
}


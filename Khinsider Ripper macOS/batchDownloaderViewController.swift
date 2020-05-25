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
    @IBOutlet weak var closeButton: NSButton!
    @IBOutlet weak var progressBar: NSProgressIndicator!
    
    var recdata = ""
    var total = GlobalVar.tracks.count
    var downloading = false
    var inte = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        progressBar.maxValue = Double(total)
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dataPath = documentsDirectory.appendingPathComponent("/Khinsider/" + GlobalVar.AlbumName)
        
        do {
            try FileManager.default.createDirectory(atPath: dataPath.path, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            print("Error creating directory: \(error.localizedDescription)")
        }
        
        progressLabel.stringValue = "downloading".localized + GlobalVar.AlbumName
        progressText.stringValue = "downloading".localized + "1 / " + String(total + 1)
        
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1;
        print(GlobalVar.download_queue)
        self.load(url: GlobalVar.download_queue, name: GlobalVar.tracks, type: GlobalVar.download_type)
    }
    
    func transitionToMain() {
        print("RETURN TO MAIN!")
        DispatchQueue.main.async {
            self.view.window?.close()
        }
    }
    
    @IBAction func closePressed(_ sender: NSButton) {
        self.view.window?.close()
    }
    
    
    func load(url: [URL], name: [String], type: String) {
        print("Got here with request " + url[inte].absoluteString)
        // create your document folder url
        let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first! as URL
        let documentsFolderUrl = documentsUrl.appendingPathComponent("Khinsider/").appendingPathComponent(GlobalVar.AlbumName)
        // your destination file url
        let destinationUrl = documentsFolderUrl.appendingPathComponent(url[inte].lastPathComponent)
        
        print(destinationUrl)
        if FileManager().fileExists(atPath: destinationUrl.path) {
            print("file saved")
            self.progressText.stringValue = "downloading".localized + String(self.inte + 2) + " / " + String(self.total + 1)
            self.progressBar.increment(by: Double(2))
            self.downloading = false
            self.inte += 1
            if self.inte == GlobalVar.trackURL.count {
                self.closeButton.isEnabled = true
                return
            }
            self.load(url: url, name: name, type: type)
        } else {
            DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async(execute: {
                if let myAudioDataFromUrl = try? Data(contentsOf: url[self.inte]){
                    // after downloading your data you need to save it to your destination url
                    if (try? myAudioDataFromUrl.write(to: destinationUrl, options: [.atomic])) != nil {
                        print("file saved")
                        self.progressText.stringValue = "downloading".localized + String(self.inte + 2) + " / " + String(self.total + 1)
                        self.progressBar.increment(by: Double(2))
                        self.downloading = false
                        self.inte += 1
                        if self.inte == GlobalVar.trackURL.count {
                            self.closeButton.isEnabled = true
                            return
                        }
                        self.load(url: url, name: name, type: type)
                        
                    }
                } else {
                    print("error saving file")
                    self.progressText.stringValue = "downloading".localized + String(self.inte + 2) + " / " + String(self.total + 1)
                    self.progressBar.increment(by: Double(1))
                    self.downloading = false
                    self.inte += 1
                    if self.inte == GlobalVar.trackURL.count {
                        self.closeButton.isEnabled = true
                        return
                    }
                    self.load(url: url, name: name, type: type)
                    }
                })
            }
    }
}



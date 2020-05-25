//
//  BatchDownloadViewController.swift
//  Khinsider Ripper
//
//  Created by ptgms on 22.05.20.
//  Copyright © 2020 ptgms. All rights reserved.
//

import UIKit
import SwiftSoup

import Foundation

class BatchDownloadViewController: UIViewController, UITableViewDelegate {

    @IBOutlet weak var currentDownload: UILabel!
    @IBOutlet weak var progressText: UILabel!
    

    var recdata = ""
    var total = GlobalVar.tracks.count
    var downloading = false
    
    
    var inte = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.setHidesBackButton(true, animated: true);
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dataPath = documentsDirectory.appendingPathComponent(GlobalVar.AlbumName)
        
        do {
            try FileManager.default.createDirectory(atPath: dataPath.path, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            print("Error creating directory: \(error.localizedDescription)")
        }
        
        // initialization of download progress labels
        currentDownload.text = "Downloading " + GlobalVar.AlbumName
        progressText.text = "Downloading 1 / " + String(total)
        
        
        // create queue for downloads since normally its async, and we dont want that
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1;
        print(GlobalVar.download_queue)
        self.load(url: GlobalVar.download_queue, name: GlobalVar.tracks, type: GlobalVar.download_type)
        
        
    }
    
    func transitionToMain() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func printQueue(_ sender: Any) {
        print(GlobalVar.download_queue)
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
                let savedURL = documentsURL.appendingPathComponent(GlobalVar.AlbumName + "/" + String(self.inte + 1) + ": " + name[self.inte] + GlobalVar.download_type)
                
                try FileManager.default.moveItem(at: fileURL, to: savedURL)
                self.downloading = true
                print("Done!")
                DispatchQueue.main.async() {
                    self.progressText.text = "Downloading " + String(self.inte + 2) + " / " + String(self.total)
                    self.downloading = false
                    self.inte += 1
                    if self.inte == GlobalVar.trackURL.count {
                        self.transitionToMain()
                        return
                    }
                    self.load(url: url, name: name, type: type)
                    
                }
            } catch {
                DispatchQueue.main.async() {
                    self.progressText.text = "Downloading " + String(self.inte + 2) + " / " + String(self.total)
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

class DownloadTaskCell: UITableViewCell {
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var progressBar: UIProgressView!
}



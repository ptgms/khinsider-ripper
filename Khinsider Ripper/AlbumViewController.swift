//
//  AlbumViewController.swift
//  Khinsider Ripper
//
//  Created by ptgms on 22.05.20.
//  Copyright © 2020 ptgms. All rights reserved.
//

import UIKit
import SwiftSoup

class AlbumViewController: UIViewController {

    @IBOutlet weak var albumCover: UIImageView!
    @IBOutlet weak var albumName: UILabel!
    @IBOutlet weak var trackAmount: UILabel!
    @IBOutlet weak var navigControl: UINavigationItem!
    @IBOutlet weak var avaibleFormats: UILabel!
    @IBOutlet weak var viewButton: UIButton!
    @IBOutlet weak var downloadAll: UIButton!
    @IBOutlet weak var gatherLinkProg: UILabel!
    @IBOutlet weak var gatherLinkBar: UIProgressView!
    @IBOutlet weak var gatherLinkPanel: UIView!
    
    
    var currentTr = 0
    var recdata = ""
    //var count = 0
    var total = GlobalVar.trackURL.count
    
    override func viewDidLoad() {
        super.viewDidLoad()
        albumName.text = GlobalVar.AlbumName
        trackAmount.text = "Contains " + String(GlobalVar.tracks.count) + " Tracks"
        navigControl.title = GlobalVar.AlbumName
        currentTr = 0
        gatherLinkPanel.isHidden = true
        
        var avaible = "Available Formats: "
        
        if (GlobalVar.flac) {
            avaible += "FLAC "
        }
        if (GlobalVar.mp3){
            avaible += "MP3 "
        }
        if (GlobalVar.ogg){
            avaible += "OGG "
        }
        
        avaibleFormats.text = avaible
        
        print(GlobalVar.coverURL)
        do {
            getData(from: URL(string: GlobalVar.coverURL[0].addingPercentEncoding(withAllowedCharacters:NSCharacterSet.urlQueryAllowed)!)!) { data, response, error in
                guard let data = data, error == nil else { return }
                print(response?.suggestedFilename ?? URL(string: GlobalVar.coverURL[0].addingPercentEncoding(withAllowedCharacters:NSCharacterSet.urlQueryAllowed)!)!.lastPathComponent )
                print("Download Finished")
                DispatchQueue.main.async() {
                    self.albumCover.image = UIImage(data: data)
                }
            }
        }
    }
    
    func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
    }

    @IBAction func viewButton(_ sender: Any) {
        let url = GlobalVar.album_url
        UIApplication.shared.open(url!)
    }
    
    @IBAction func downloadAllPressed(_ sender: Any) {
        currentTr = 0
        let alert = UIAlertController(title: "Question", message: "As what format do you want to save the file?", preferredStyle: .alert)
        if (GlobalVar.mp3) {
            alert.addAction(UIAlertAction(title: "MP3", style: .default, handler: { action in
                GlobalVar.download_type = ".mp3"
                self.initDownloadAll(type: GlobalVar.download_type, toDownload: GlobalVar.trackURL, name: GlobalVar.tracks)
            }))
        }
        if (GlobalVar.flac) {
            alert.addAction(UIAlertAction(title: "FLAC", style: .default, handler: { action in
                GlobalVar.download_type = ".flac"
                self.initDownloadAll(type: GlobalVar.download_type, toDownload: GlobalVar.trackURL, name: GlobalVar.tracks)
            }))
        }
        if (GlobalVar.ogg) {
            alert.addAction(UIAlertAction(title: "ogg", style: .default, handler: { action in
                GlobalVar.download_type = ".ogg"
                self.initDownloadAll(type: GlobalVar.download_type, toDownload: GlobalVar.trackURL, name: GlobalVar.tracks)
            }))
        }
        self.present(alert, animated: true, completion: nil)
    }
    
    func initDownloadAll(type: String, toDownload: [String], name: [String]) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let batchDownload = storyboard.instantiateViewController(withIdentifier: "batchDownload")
        print("PRE-COUNT: " + String(GlobalVar.trackURL.count))
        self.downloadAll.setTitle("Gathering direct links...", for: .normal)
        gatherLinkBar.progress = 0.0
        self.gatherLinkPanel.isHidden = false
        let completed_url = URL(string: "https://downloads.khinsider.com" + toDownload[currentTr])!
        let task = URLSession.shared.dataTask(with: completed_url) {(data, response, error) in
            self.recdata = String(data: data!, encoding: .utf8)!
            DispatchQueue.main.async() {
                do {
                    let doc: Document = try SwiftSoup.parse(self.recdata)
                    let link: Element = try doc.getElementById("EchoTopic")!
                    
                    for link in try! link.select("a") {
                        let url_prev = try! link.attr("href")
                        if (url_prev.hasSuffix(type)) {
                            print(url_prev)
                            self.currentTr += 1
                            GlobalVar.download_queue.append(URL(string: url_prev)!)
                            self.gatherLinkProg.text = "Gathering direct links:" + String(self.currentTr) + " / " + String(GlobalVar.trackURL.count)
                            self.gatherLinkBar.progress = Float(GlobalVar.trackURL.count / GlobalVar.download_queue.count)
                            if (GlobalVar.download_queue.count == GlobalVar.trackURL.count) {
                                self.gatherLinkPanel.isHidden = true
                                print(GlobalVar.download_queue)
                                self.downloadAll.setTitle("Download all Tracks", for: .normal)
                                self.gatherLinkPanel.alpha = 0.0
                                self.navigationController?.pushViewController(batchDownload, animated: true)
                                break
                            }
                            self.initDownloadAll(type: type, toDownload: toDownload, name: name)
                        } else {
                            print("Invalid type!")
                        }
                    }
                } catch Exception.Error( _, let message) {
                    print(message)
                } catch {
                    print("error")
                }
            }
        }
        task.resume()
    }
}

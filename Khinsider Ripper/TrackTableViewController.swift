//
//  TrackTableViewController.swift
//  Khinsider Ripper
//
//  Created by ptgms on 22.05.20.
//  Copyright © 2020 ptgms. All rights reserved.
//

import UIKit
import SwiftSoup

class TrackTableViewController: UITableViewController {
    
    var recdata = ""
    var toDownload = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return GlobalVar.tracks.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "trackCell", for: indexPath)

        cell.textLabel?.text = String(indexPath.row + 1) + ": " + GlobalVar.tracks[indexPath.row]
        cell.detailTextLabel?.text = GlobalVar.trackURL[indexPath.row]

        return cell
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let openInBrowser = UITableViewRowAction(style: .normal, title: "open_browser".localized) { (action, indexPath) in
            let url = URL(string: GlobalVar.base_url + GlobalVar.trackURL[indexPath.row])
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url!)
            } else {
                UIApplication.shared.openURL(url!)
            }
        }
        let downloadTrack = UITableViewRowAction(style: .normal, title: "download_track".localized) { (action, indexPath) in
            let alert = UIAlertController(title: "question".localized, message: "format_ask".localized, preferredStyle: .alert)
            if GlobalVar.mp3 {
                alert.addAction(UIAlertAction(title: "MP3", style: .default, handler: { action in
                    self.download(type: ".mp3", toDownload: GlobalVar.trackURL[indexPath.row], name: GlobalVar.tracks[indexPath.row])
                }))
            }
            if GlobalVar.flac {
                alert.addAction(UIAlertAction(title: "FLAC", style: .default, handler: { action in
                    self.download(type: ".flac", toDownload: GlobalVar.trackURL[indexPath.row], name: GlobalVar.tracks[indexPath.row])
                }))
            }
            if GlobalVar.ogg {
                alert.addAction(UIAlertAction(title: "ogg", style: .default, handler: { action in
                    self.download(type: ".ogg", toDownload: GlobalVar.trackURL[indexPath.row], name: GlobalVar.tracks[indexPath.row])
                }))
            }
            self.present(alert, animated: true, completion: nil)
        }
        
        openInBrowser.backgroundColor = UIColor.blue
        downloadTrack.backgroundColor = UIColor.green
        return [openInBrowser, downloadTrack]
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        GlobalVar.nowplaying = GlobalVar.tracks[indexPath.row]
        let nowplaying = GlobalVar.trackURL[indexPath.row]
        let completed_url = URL(string: GlobalVar.base_url + nowplaying)
        let task = URLSession.shared.dataTask(with: completed_url!) {(data, response, error) in
            self.recdata = String(data: data!, encoding: .utf8)!
            //print(String(data: data!, encoding: .utf8)!)
            DispatchQueue.main.async {
                print(self.recdata)
                do {
                    let doc: Document = try SwiftSoup.parse(self.recdata)
                    let link: Element = try doc.getElementById("EchoTopic")!
                    
                    for link in try! link.select("a") {
                        let url_prev = try! link.attr("href")
                        if (url_prev.hasSuffix(".mp3")) {
                            GlobalVar.nowplayingurl = url_prev
                            self.tabBarController?.selectedIndex = 2
                            break
                        } else if (url_prev.hasSuffix(".ogg")) {
                            GlobalVar.nowplayingurl = url_prev
                            self.tabBarController?.selectedIndex = 2
                            break
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
    
    @IBAction func optionsPressed(_ sender: Any) {
        if(self.tableView.isEditing == true) {
            self.tableView.isEditing = false
            self.navigationItem.rightBarButtonItem?.title = "done".localized
        } else {
            self.tableView.isEditing = true
            self.navigationItem.rightBarButtonItem?.title = "options".localized
        }
    }
    
    
    func download(type: String, toDownload: String, name: String) {
        let completed_url = URL(string: "https://downloads.khinsider.com" + toDownload)!
        let task = URLSession.shared.dataTask(with: completed_url) {(data, response, error) in
            self.recdata = String(data: data!, encoding: .utf8)!
            DispatchQueue.main.async {
                do {
                    let doc: Document = try SwiftSoup.parse(self.recdata)
                    let link: Element = try doc.getElementById("EchoTopic")!
                    
                    for link in try! link.select("a") {
                        let url_prev = try! link.attr("href")
                        if (url_prev.hasSuffix(type)) {
                            print(url_prev)
                            self.load(url: URL(string: url_prev)!, name: name + type)
                            break
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
    
    func load(url: URL, name: String) {
        print("Got here with request " + url.absoluteString)
        let downloadTask = URLSession.shared.downloadTask(with: url) {
            urlOrNil, responseOrNil, errorOrNil in
            
            guard let fileURL = urlOrNil else { return }
            do {
                let documentsURL = try
                    FileManager.default.url(for: .documentDirectory,
                                            in: .userDomainMask,
                                            appropriateFor: nil,
                                            create: false)
                let savedURL = documentsURL.appendingPathComponent(name)
                try FileManager.default.moveItem(at: fileURL, to: savedURL)
                DispatchQueue.main.async {
                    let alertController = UIAlertController(title: "done".localized + "!", message: "trackdone".localized, preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "ok".localized, style: .default))
                    
                    self.present(alertController, animated: true, completion: nil)
                }
            } catch {
                print ("file error: \(error)")
            }
        }
        downloadTask.resume()
    }
}

//
//  ViewController.swift
//  Khinsider Ripper macOS
//
//  Created by ptgms on 23.05.20.
//  Copyright © 2020 ptgms. All rights reserved.
//

import Cocoa
import SwiftSoup
import AVKit
import AVFoundation

class ViewController: NSViewController, NSUserNotificationCenterDelegate {

    @IBOutlet weak var tableViewer: NSTableView!
    @IBOutlet weak var searchBar: NSSearchField!
    @IBOutlet weak var trackTableView: TrackViewController!
    @IBOutlet weak var albumArt: NSImageView!
    @IBOutlet weak var playPause: NSButton!
    @IBOutlet weak var duration: NSTextField!
    @IBOutlet weak var currentProg: NSTextField!
    @IBOutlet weak var currentTrack: NSTextField!
    @IBOutlet weak var progress: NSProgressIndicator!
    @IBOutlet weak var downloadWith: NSPopUpButton!
    @IBOutlet weak var vfxButton: NSVisualEffectView!
    
    private var trackingArea: NSTrackingArea?
    let defaults = UserDefaults.standard
    // --- Initialization of project specific variables
    
    let base_url = "https://downloads.khinsider.com/"
    let base_search_url = "search?search="
    let base_soundtrack_album_url = "game-soundtracks/album/"
    var currentTr = 0
    var debug = 0
    var inte = 0
    var downloading = false
    var recdata = ""
    var playing = false
    var album_name = ""
    var tracklist = [String]()
    var tracklisturl = [String]()
    var titlelength = [String]()
    
    var tags = [String]()
    
    var dataSource1: TrackViewController!
    var dataSource2: AlbumViewController!
    
    var downloadAllOn = false
    var downloadSelOn = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        vfxButton.alphaValue = 0.0
        
        GlobalVar.favs_name = defaults.stringArray(forKey: "favs_name") ?? [String]()
        GlobalVar.favs_link = defaults.stringArray(forKey: "favs_link") ?? [String]()
        
        NotificationCenter.default.addObserver(self, selector: #selector(downloadSelected), name: Notification.Name("downloadSelected"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(downloadAll), name: Notification.Name("downloadAllTitle"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(playPausePressed), name: Notification.Name("playPause"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(doubleClickOnResultRow), name: Notification.Name("reload"), object: nil)
        
        let area = NSTrackingArea.init(rect: vfxButton.bounds,
                                       options: [.mouseEnteredAndExited, .activeAlways],
                                       owner: self,
                                       userInfo: nil)
        vfxButton.addTrackingArea(area)
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dataPath = documentsDirectory.appendingPathComponent("Khinsider")
        
        do {
            try FileManager.default.createDirectory(atPath: dataPath.path, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            print("Error creating directory: \(error.localizedDescription)")
        }
        
        self.dataSource1 = TrackViewController()
        self.dataSource2 = AlbumViewController()
        self.tableViewer.delegate = self.dataSource2
        self.tableViewer.dataSource = self.dataSource2
        
        self.trackTableView.delegate = self.dataSource1
        self.trackTableView.dataSource = self.dataSource1

        tableViewer.doubleAction = #selector(ViewController.doubleClickOnResultRow)
        trackTableView.doubleAction = #selector(ViewController.ClickOnResultRow)
        trackTableView.action = #selector(ViewController.saveCurrentClick)
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "openBrowser".localized, action: #selector(ViewController.contextOnAlbum), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "downloadAlbum".localized, action: #selector(ViewController.downloadAlbumContext), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "AddRemFavs".localized, action: #selector(ViewController.addAlbumToFavs), keyEquivalent: ""))
        tableViewer.menu = menu
        
        let menutwo = NSMenu()
        menutwo.addItem(NSMenuItem(title: "openBrowser".localized, action: #selector(ViewController.contextOnTrack), keyEquivalent: ""))
        menutwo.addItem(NSMenuItem(title: "downloadTrack".localized, action: #selector(ViewController.downloadTrackContext), keyEquivalent: ""))
        trackTableView.menu = menutwo
    }
    
    override func mouseEntered(with event: NSEvent) {
        vfxButton.alphaValue = 1.0
    }
    
    override func mouseExited(with event: NSEvent) {
        vfxButton.alphaValue = 0.0
    }
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    @objc func downloadAlbumContext() {
        guard tableViewer.clickedRow >= 0 else { return }
        GlobalVar.downloadAfter = true
        doubleClickOnResultRow()
    }
    
    @objc func contextOnAlbum() {
        let item = tableViewer.clickedRow
        if (item >= 0) {
            let url = URL(string: GlobalVar.linkArray[item])!
            if NSWorkspace.shared.open(url) {
                return
            }
        } else {
            let url = URL(string: base_url)!
            if NSWorkspace.shared.open(url) {
                return
            }
        }
    }
    
    @objc func addAlbumToFavs() {
        guard tableViewer.clickedRow >= 0 else { return }
        let item = tableViewer.clickedRow
        if (GlobalVar.favs_link.contains(GlobalVar.linkArray[item])) {
            GlobalVar.favs_link.remove(at: GlobalVar.favs_link.firstIndex(of: GlobalVar.linkArray[item])!)
            GlobalVar.favs_name.remove(at: GlobalVar.favs_name.firstIndex(of: GlobalVar.textArray[item])!)
        } else {
            GlobalVar.favs_name.insert(GlobalVar.textArray[item], at: 0)
            GlobalVar.favs_link.insert(GlobalVar.linkArray[item], at: 0)
        }
        defaults.set(GlobalVar.favs_name, forKey: "favs_name")
        defaults.set(GlobalVar.favs_link, forKey: "favs_link")
    }
    
    @objc func downloadTrackContext() {
        guard trackTableView.clickedRow >= 0 else { return }
        GlobalVar.downloadAfter = true
        saveCurrentClick()
    }
    
    @objc func contextOnTrack() {
        let base = "https://downloads.khinsider.com"
        guard trackTableView.clickedRow >= 0 else { return }
        let item = trackTableView.clickedRow
        let url = URL(string: base + GlobalVar.trackURL[item])!
        if NSWorkspace.shared.open(url) {
            return
        }
    }
    
    @IBAction func searchPressed(_ sender: Any) {
        GlobalVar.linkArray.removeAll()
        GlobalVar.textArray.removeAll()
        let search = searchBar.stringValue.addingPercentEncoding(withAllowedCharacters:NSCharacterSet.urlQueryAllowed)!
        let completed_url = URL(string: base_url + base_search_url + search)
        let task = URLSession.shared.dataTask(with: completed_url!) {(data, response, error) in
            self.recdata = String(data: data!, encoding: .utf8)!
            DispatchQueue.main.async {
                //print(self.recdata)
                do {
                    let doc: Document = try SwiftSoup.parse(self.recdata)
                    let link: Element = try doc.getElementById("EchoTopic")!
                    
                    for row in try! link.select("p") {
                        for col in try! row.select("a") {
                            if (try col.attr("href").contains("game-soundtracks/browse/") || col.attr("href").contains("/forums/") || col.attr("href").contains("/game-soundtracks/windows")) {
                                continue
                            }
                            let colContent = try! col.text()
                            let colHref = try! col.attr("href")
                            if (GlobalVar.textArray.contains(colContent)) {
                                continue
                            }
                            GlobalVar.textArray.append(colContent)
                            GlobalVar.linkArray.append(colHref)
                        }
                    }
                    
                    print(GlobalVar.textArray.count)
                    print(GlobalVar.linkArray.count)
                    
                    self.update()
                    
                } catch Exception.Error( _, let message) {
                    print(message)
                } catch {
                    print("error")
                }
            }
        }
        task.resume()
    }
    @objc func ClickOnResultRow() {
        let clickedOn = trackTableView.clickedRow
        if (clickedOn == -1) {
            return
        }
        print(clickedOn)
        GlobalVar.nowplaying = GlobalVar.tracks[clickedOn]
        let nowplaying = GlobalVar.trackURL[clickedOn]
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
                            self.initplayer()
                            break
                        } else if (url_prev.hasSuffix(".ogg")) {
                            GlobalVar.nowplayingurl = url_prev
                            self.initplayer()
                            break
                        } else {
                            //TODO: Add error popup
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
    
    func setAlbumArt() {
        getData(from: URL(string: GlobalVar.coverURL[0].addingPercentEncoding(withAllowedCharacters:NSCharacterSet.urlQueryAllowed)!)!) { data, response, error in
            guard let data = data, error == nil else { return }
            print(response?.suggestedFilename ?? URL(string: GlobalVar.coverURL[0].addingPercentEncoding(withAllowedCharacters:NSCharacterSet.urlQueryAllowed)!)!.lastPathComponent)
            print("Download Finished")
            DispatchQueue.main.async {
                self.albumArt.image = NSImage(data: data)
            }
        }
    }
    
    func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
    }
    
    func initplayer() {
        self.setAlbumArt()
        self.currentTrack.stringValue = GlobalVar.nowplaying
        audioPlayer(url: GlobalVar.nowplayingurl)
        
    }
    
    var player: AVPlayer?
    func audioPlayer(url: String) {
        do {
            player = AVPlayer(url: URL.init(string: url)!)
            player?.play()
            playing = true
            GlobalVar.touch_playing = true
            NotificationCenter.default.post(name: Notification.Name("updateBar"), object: nil)
            playPause.image = NSImage(named: "pause")
            
            self.duration.stringValue = (self.player?.currentItem?.asset.duration.positionalTime)!
            player?.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(1/30.0, preferredTimescale: Int32(NSEC_PER_SEC)), queue: nil) { time in
                let duration = CMTimeGetSeconds((self.player?.currentItem?.asset.duration)!)
                self.progress.doubleValue = (CMTimeGetSeconds(time) / duration)
                //self.progress.floatValue = Float((CMTimeGetSeconds(time) / duration))
                self.currentProg.stringValue = time.positionalTime
            }
        }
    }
    
    @objc func playPauseEvent() {
        playpause()
    }
    
    func playpause() {
        if (playing == true) {
            playing = false
            playPause.image = NSImage(named: "play")
            player?.pause()
            GlobalVar.touch_playing = false
            NotificationCenter.default.post(name: Notification.Name("updateBar"), object: nil)
        } else {
            playing = true
            playPause.image = NSImage(named: "pause")
            player?.play()
            GlobalVar.touch_playing = true
            NotificationCenter.default.post(name: Notification.Name("updateBar"), object: nil)
        }
    }

    @IBAction func playPausePressed(_ sender: Any) {
        playpause()
    }
    
    @objc func downloadSelected(_ sender: Any) {
        if (downloadSelOn != true) {
            return
        }
        if (GlobalVar.currentLink == "") {
            return
        } else {
            //downloadSelect.stringValue = "downloadingdot".localized
            let a = NSAlert()
            a.messageText = "question".localized
            a.informativeText = "formatconfirm".localized
            if (GlobalVar.mp3) {
                a.addButton(withTitle: "MP3")
            }
            if (GlobalVar.flac) {
                a.addButton(withTitle: "FLAC")
            }
            if (GlobalVar.ogg) {
                a.addButton(withTitle: "OGG")
            }
            a.alertStyle = NSAlert.Style.informational
            
            a.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) -> Void in
                if modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn {
                    GlobalVar.download_type = ".mp3"
                    self.downloadOne(type: ".mp3", toDownload: GlobalVar.currentLink, name: GlobalVar.currentName)
                } else if modalResponse == NSApplication.ModalResponse.alertSecondButtonReturn {
                    GlobalVar.download_type = ".flac"
                    self.downloadOne(type: ".flac", toDownload: GlobalVar.currentLink, name: GlobalVar.currentName)
                } else if modalResponse == NSApplication.ModalResponse.alertThirdButtonReturn {
                    GlobalVar.download_type = ".ogg"
                    self.downloadOne(type: ".ogg", toDownload: GlobalVar.currentLink, name: GlobalVar.currentName)
                }
            })
            
        }
    }
    
    @objc func downloadAll(_ sender: Any) {
        if (downloadAllOn != true) {
            return
        }
        GlobalVar.download_queue = []
        GlobalVar.progressValNow = Double(0)
        GlobalVar.progressVal = Double(GlobalVar.trackURL.count)
        GlobalVar.nowDownload = "Downloading " + GlobalVar.AlbumName
        GlobalVar.nowDownloadDet = "Please wait..."
        NotificationCenter.default.post(name: Notification.Name("progUp"), object: nil)
        currentTr = 0
        let a = NSAlert()
        a.messageText = "question".localized
        a.informativeText = "formatconfirm".localized
        if (GlobalVar.mp3) {
            a.addButton(withTitle: "MP3")
        }
        if (GlobalVar.flac) {
            a.addButton(withTitle: "FLAC")
        }
        if (GlobalVar.ogg) {
            a.addButton(withTitle: "OGG")
        }
        a.alertStyle = NSAlert.Style.informational
        
        a.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) -> Void in
            if modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn {
                GlobalVar.download_type = ".mp3"
                self.initDownloadAll(type: GlobalVar.download_type, toDownload: GlobalVar.trackURL, name: GlobalVar.tracks)
            } else if modalResponse == NSApplication.ModalResponse.alertSecondButtonReturn {
                GlobalVar.download_type = ".flac"
                self.initDownloadAll(type: GlobalVar.download_type, toDownload: GlobalVar.trackURL, name: GlobalVar.tracks)
            } else if modalResponse == NSApplication.ModalResponse.alertThirdButtonReturn {
                GlobalVar.download_type = ".ogg"
                self.initDownloadAll(type: GlobalVar.download_type, toDownload: GlobalVar.trackURL, name: GlobalVar.tracks)
            }
        })
    }
    
    func initDownloadAll(type: String, toDownload: [String], name: [String]) {
        let completed_url = URL(string: "https://downloads.khinsider.com" + toDownload[currentTr])!
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
                            self.currentTr += 1
                            self.view.window?.title = "gatheringlinks".localized + String(GlobalVar.download_queue.count) + " / " +
                                String(GlobalVar.trackURL.count)
                            GlobalVar.progressValNow += 1
                            GlobalVar.nowDownloadDet = url_prev
                            NotificationCenter.default.post(name: Notification.Name("progUp"), object: nil)
                            GlobalVar.download_queue.append(URL(string: url_prev)!)
                            if (GlobalVar.download_queue.count == GlobalVar.trackURL.count) {
                                self.view.window?.title = "khinsiderripper".localized
                                if (self.downloadWith.titleOfSelectedItem == "downloaddirect".localized) {
                                    self.downloadAllRec()
                                    
                                } else {
                                    var toExport = ""
                                    let exportFile = self.getDocumentsDirectory().appendingPathComponent("Khinsider").appendingPathComponent("").appendingPathComponent(GlobalVar.AlbumName + ".txt")
                                    print(exportFile.absoluteString)
                                    for item in GlobalVar.download_queue {
                                        if toExport.contains(item.absoluteString) {
                                            continue
                                        }
                                        toExport += item.absoluteString + "\n"
                                    }
                                    do {
                                        try toExport.data(using: .utf8)!.write(to: exportFile)
                                        self.showNotification(title: "done".localized, body: "filesaved".localized)
                                    } catch {
                                        print("Failed to save the file!")
                                        self.showNotification(title: "error".localized, body: "savefail".localized)
                                    }
                                }
                                break
                            }
                            
                            self.initDownloadAll(type: type, toDownload: toDownload, name: name)
                            //self.loadOne(url: URL(string: url_prev)!, name: name + type)
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
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func downloadOne(type: String, toDownload: String, name: String) {
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
                            self.loadOne(url: URL(string: url_prev)!, name: name + type)
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
    
    func loadOne(url: URL, name: String) {
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
                let savedURL = documentsURL.appendingPathComponent("Khinsider/" + name)
                try FileManager.default.moveItem(at: fileURL, to: savedURL)
                DispatchQueue.main.sync {
                    self.showNotification(title: "done".localized, body: "filesaved".localized)
                }
            } catch {
                print ("file error: \(error)")
            }
        }
        downloadTask.resume()
    }
    
    @objc func saveCurrentClick() {
        let clickedOn = trackTableView.clickedRow
        print(clickedOn)
        print(GlobalVar.trackURL.count - 1)
        if (clickedOn == -1) {
            return
        }
        GlobalVar.currentLink = GlobalVar.trackURL[clickedOn]
        GlobalVar.currentName = GlobalVar.tracks[clickedOn]
        downloadSelOn = true
        GlobalVar.touch_track = true
        NotificationCenter.default.post(name: Notification.Name("updateBar"), object: nil)
        
        if (GlobalVar.downloadAfter == true) {
            GlobalVar.downloadAfter = false
            downloadSelected(self)
        }
        
        print("Selected: " + GlobalVar.currentLink + " from " + GlobalVar.currentName)
    }
    
    @objc func doubleClickOnResultRow() {
        var clickedOn = -1
        if (GlobalVar.favPressedNow != -1) {
            
        } else {
            clickedOn = tableViewer.clickedRow
            if (clickedOn == -1) {
                return
            }
        }
        //print("doubleClickOnResultRow \(tableViewer.clickedRow)")
        GlobalVar.currentLink = ""
        //TODO
        downloadAllOn = true
        downloadSelOn = false
        GlobalVar.touch_track = false
        GlobalVar.mp3 = false
        GlobalVar.flac = false
        GlobalVar.ogg = false
        
        NotificationCenter.default.post(name: Notification.Name("updateBar"), object: nil)
        
        GlobalVar.coverURL = [String]()
        tags = [String]()
        tracklist = [String]()
        tracklisturl = [String]()
        titlelength = [String]()
        GlobalVar.AlbumName = ""
        GlobalVar.tags = [String]()
        GlobalVar.tracks = [String]()
        GlobalVar.trackURL = [String]()
        
        var completed_url = URL(string: "") // build the URL to process
        
        if (GlobalVar.favPressedNow != -1 && GlobalVar.favs_link[GlobalVar.favPressedNow] != "") {
            completed_url = URL(string: base_url + GlobalVar.favs_link[GlobalVar.favPressedNow].replacingOccurrences(of: base_url, with: "")) // build the URL to process
        } else {
            completed_url = URL(string: base_url + GlobalVar.linkArray[tableViewer.clickedRow].replacingOccurrences(of: base_url, with: "")) // build the URL to process
        }
        GlobalVar.album_url = completed_url
        let task = URLSession.shared.dataTask(with: completed_url!) {(data, response, error) in
            self.recdata = String(data: data!, encoding: .utf8)! // store the received data as a string to be processed
            DispatchQueue.main.async {
                do {
                    let doc: Document = try SwiftSoup.parse(self.recdata) // start swiftsoup tasks
                    
                    for element in try doc.select("img").array(){ // for every image on the site store the URL
                        let imgurl = try! element.attr("src")
                        if (imgurl.hasPrefix("/album_views.php")){
                            GlobalVar.coverURL.append("https://i.ibb.co/cgRJ97N/unknown.png")
                        } else {
                            GlobalVar.coverURL.append(try! element.attr("src"))
                        }
                    }
                    
                    let link: Element = try doc.getElementById("songlist")!
                    for row in try! link.select("tbody") {
                        for col in try! row.select("tr") {
                            for title in try! col.select("tr") {
                                if (title.id() == "songlist_header" || title.id() == "songlist_footer") {
                                    for tag in try! title.select("th") {
                                        self.tags.append(try! tag.text())
                                    }
                                    print("TAGS: ")
                                    print(self.tags)
                                    if (self.tags.contains("FLAC")) {
                                        GlobalVar.flac = true
                                        print("FLAC: true")
                                    }
                                    if (self.tags.contains("MP3")){
                                        GlobalVar.mp3 = true
                                        print("MP3: true")
                                    }
                                    if (self.tags.contains("OGG")){
                                        GlobalVar.ogg = true
                                        print("OGG: true")
                                    }
                                    GlobalVar.tags = self.tags
                                }
                                var temptag = [String]()
                                let songname = self.tags.firstIndex(of: "Song Name")!
                                for titlename in try! title.select("td") {
                                    temptag.append(try! titlename.text())
                                    let titleurl = try! titlename.select("a").attr("href")
                                    if (titleurl != "" && !self.tracklisturl.contains(titleurl)) {
                                        print(titleurl)
                                        self.tracklisturl.append(titleurl)
                                    }
                                    if (temptag.count == self.tags.count + 1) {
                                        //print(temptag)
                                        self.titlelength.append(temptag[songname + 1])
                                        self.tracklist.append(temptag[songname])
                                    }
                                }
                            }
                        }
                    }
                    
                    GlobalVar.tracks = self.tracklist
                    GlobalVar.trackURL = self.tracklisturl
                    print(GlobalVar.textArray.count)
                    if (GlobalVar.favPressedNow != -1) {
                        GlobalVar.AlbumName = GlobalVar.favs_name[GlobalVar.favPressedNow]
                    } else {
                        GlobalVar.AlbumName = GlobalVar.textArray[clickedOn]
                    }
                    self.trackTableView.reloadData()
                    self.setAlbumArt()
                    print(self.tracklist.count)
                    print(self.tracklisturl.count)
                    
                    if (GlobalVar.downloadAfter == true) {
                        GlobalVar.downloadAfter = false
                        self.downloadAll(self)
                    }
                    
                    var available = "availableformat".localized
                    if (GlobalVar.mp3) {
                        available += "MP3 "
                    }
                    if (GlobalVar.flac) {
                        available += "FLAC "
                    }
                    if (GlobalVar.ogg) {
                        available += "OGG "
                    }
                    
                    GlobalVar.favPressedNow = -1
                    
                } catch Exception.Error( _, let message) {
                    print(message)
                    GlobalVar.favPressedNow = -1
                } catch {
                    print("error")
                    GlobalVar.favPressedNow = -1
                }
            }
        }
        task.resume()
        
    }
    
    @objc func downloadAllRec() {
        inte = 0
        GlobalVar.progressVal = Double(GlobalVar.tracks.count)
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dataPath = documentsDirectory.appendingPathComponent("/Khinsider/" + GlobalVar.AlbumName)
        
        do {
            try FileManager.default.createDirectory(atPath: dataPath.path, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            print("Error creating directory: \(error.localizedDescription)")
        }
        
        GlobalVar.nowDownload = "downloading".localized + GlobalVar.AlbumName
        GlobalVar.nowDownloadDet = "downloading".localized + "1 / " + String(GlobalVar.tracks.count + 1)
        
        NotificationCenter.default.post(name: Notification.Name("progUp"), object: nil)
        
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1;
        print(GlobalVar.download_queue)
        self.load(url: GlobalVar.download_queue, name: GlobalVar.tracks, type: GlobalVar.download_type)
    }
    
    
    func load(url: [URL], name: [String], type: String) {
        print(inte)
        print("Got here with request " + url[inte].absoluteString)
        // create your document folder url
        let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first! as URL
        let documentsFolderUrl = documentsUrl.appendingPathComponent("Khinsider/").appendingPathComponent(GlobalVar.AlbumName)
        // your destination file url
        let destinationUrl = documentsFolderUrl.appendingPathComponent(url[inte].lastPathComponent)
        
        print(destinationUrl)
        if FileManager().fileExists(atPath: destinationUrl.path) {
            print("file saved")
            GlobalVar.nowDownloadDet = "downloading".localized + String(self.inte + 2) + " / " + String(GlobalVar.tracks.count + 1)
            self.downloading = false
            self.inte += 1
            GlobalVar.progressValNow = Double(inte)
            NotificationCenter.default.post(name: Notification.Name("progUp"), object: nil)
            if self.inte == GlobalVar.trackURL.count {
                return
            }
            self.load(url: url, name: name, type: type)
        } else {
            DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async(execute: {
                if let myAudioDataFromUrl = try? Data(contentsOf: url[self.inte]){
                    // after downloading your data you need to save it to your destination url
                    if (try? myAudioDataFromUrl.write(to: destinationUrl, options: [.atomic])) != nil {
                        print("file saved")
                        DispatchQueue.main.async() {
                            GlobalVar.nowDownloadDet = "downloading".localized + String(self.inte + 2) + " / " + String(GlobalVar.tracks.count + 1)
                            GlobalVar.progressValNow = Double(self.inte)
                            NotificationCenter.default.post(name: Notification.Name("progUp"), object: nil)
                        }
                        self.downloading = false
                        self.inte += 1
                        if self.inte == GlobalVar.trackURL.count {
                            self.showNotification(title: "done".localized, body: "filesaved".localized)
                            return
                        }
                        self.load(url: url, name: name, type: type)
                        
                    }
                } else {
                    print("error saving file")
                    DispatchQueue.main.async() {
                        GlobalVar.nowDownloadDet = "downloading".localized + String(self.inte + 1) + " / " + String(GlobalVar.tracks.count + 1)
                        GlobalVar.progressValNow = Double(self.inte)
                    }
                    self.downloading = false
                    self.inte += 1
                    if self.inte == GlobalVar.trackURL.count {
                        self.showNotification(title: "done".localized, body: "filesaved".localized)
                        return
                    }
                    self.load(url: url, name: name, type: type)
                }
            })
        }
    }
    
    @objc func update() {
        if (GlobalVar.linkArray.count == GlobalVar.textArray.count) {
            tableViewer.reloadData()
        } else {
            print("Mismatch on both arrays, this shouldn't happen!")
        }
    }
    
}

extension CMTime {
    var roundedSeconds: TimeInterval {
        return seconds.rounded()
    }
    var hours:  Int { return Int(roundedSeconds / 3600) }
    var minute: Int { return Int(roundedSeconds.truncatingRemainder(dividingBy: 3600) / 60) }
    var second: Int { return Int(roundedSeconds.truncatingRemainder(dividingBy: 60)) }
    var positionalTime: String {
        return hours > 0 ?
            String(format: "%d:%02d:%02d",
                   hours, minute, second) :
            String(format: "%02d:%02d",
                   minute, second)
    }
}


struct GlobalVar {
    static var tracks = [String]()
    static var AlbumName = ""
    static var trackURL = [String]()
    static var coverURL = [String]()
    static var tags = [String]()
    
    static let base_url = "https://downloads.khinsider.com"
    
    static var ogg = false
    static var mp3 = false
    static var flac = false
    
    static var nowplaying = ""
    static var nowplayingurl = ""
    
    static var download_type = ""
    
    static var album_url = URL(string: "")
    
    static var download_queue: [URL] = []
    
    static var linkArray = [String]()
    static var textArray = [String]()
    
    static var currentLink = ""
    static var currentName = ""
    
    static var progressVal = Double(1)
    static var progressValNow = Double(0)
    static var nowDownload = ""
    static var nowDownloadDet = ""

    static var touch_album = true
    static var touch_track = true
    static var touch_playing = false
    
    static var downloadAfter = false
    
    static var favs_name = [String]()
    static var favs_link = [String]()
    
    static var favPressedNow = -1
}

extension String {
    var localized: String {
        return NSLocalizedString(self, tableName: nil, bundle: Bundle.main, value: "", comment: "")
    }
}

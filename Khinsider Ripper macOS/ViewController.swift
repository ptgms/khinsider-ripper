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

class ViewController: NSViewController {

    @IBOutlet weak var tableViewer: NSTableView!
    @IBOutlet weak var searchBar: NSSearchField!
    @IBOutlet weak var trackTableView: TrackViewController!
    @IBOutlet weak var albumArt: NSImageView!
    @IBOutlet weak var albumBlurred: NSImageView!
    @IBOutlet weak var playPause: NSButton!
    @IBOutlet weak var duration: NSTextField!
    @IBOutlet weak var currentProg: NSTextField!
    @IBOutlet weak var currentTrack: NSTextField!
    @IBOutlet weak var progress: NSSlider!
    @IBOutlet weak var downloadSelect: NSButton!
    @IBOutlet weak var downloadAll: NSButton!
    @IBOutlet weak var availableFormats: NSTextField!
    @IBOutlet weak var downloadWith: NSPopUpButton!
    @IBOutlet weak var progressIndic: NSProgressIndicator!
    @IBOutlet weak var blurArt: NSVisualEffectView!
    
    // --- Initialization of project specific variables
    
    let base_url = "https://downloads.khinsider.com/"
    let base_search_url = "search?search="
    let base_soundtrack_album_url = "game-soundtracks/album/"
    var currentTr = 0
    var debug = 0
    var downloading = false
    var recdata = ""
    var playing = false
    var album_name = ""
    var tracklist = [String]()
    var tracklisturl = [String]()
    var titlelength = [String]()
    
    var tags = [String]()
    
    var dataSource1 : TrackViewController!
    var dataSource2 : AlbumViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        blurArt.blendingMode = .behindWindow
        
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
        menu.addItem(NSMenuItem(title: "Open in Browser", action: #selector(ViewController.contextOnAlbum), keyEquivalent: ""))
        tableViewer.menu = menu
    }
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    @objc func contextOnAlbum() {
        let clickedOn = trackTableView.clickedRow
        print(clickedOn)
        let url = URL(string: "https://www.downloads.khinsider.com")!
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
            DispatchQueue.main.async() {
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
            DispatchQueue.main.async() {
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
        blurArt.blendingMode = .withinWindow
        getData(from: URL(string: GlobalVar.coverURL[0].addingPercentEncoding(withAllowedCharacters:NSCharacterSet.urlQueryAllowed)!)!) { data, response, error in
            guard let data = data, error == nil else { return }
            print(response?.suggestedFilename ?? URL(string: GlobalVar.coverURL[0].addingPercentEncoding(withAllowedCharacters:NSCharacterSet.urlQueryAllowed)!)!.lastPathComponent)
            print("Download Finished")
            DispatchQueue.main.async() {
                self.albumArt.image = NSImage(data: data)
                self.albumBlurred.image = NSImage(data: data)
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
            playPause.image = NSImage(named: "pause")
            
            self.duration.stringValue = (self.player?.currentItem?.asset.duration.positionalTime)!
            player?.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(1/30.0, preferredTimescale: Int32(NSEC_PER_SEC)), queue: nil) { time in
                let duration = CMTimeGetSeconds((self.player?.currentItem?.asset.duration)!)
                self.progress.floatValue = Float((CMTimeGetSeconds(time) / duration))
                self.currentProg.stringValue = time.positionalTime
                self.progress.isEnabled = true
            }
        }
    }

    @IBAction func playPausePressed(_ sender: Any) {
        if (playing == true) {
            playing = false
            playPause.image = NSImage(named: "play")
            player?.pause()
            self.progress.isEnabled = false
        } else {
            playing = true
            playPause.image = NSImage(named: "pause")
            player?.play()
            self.progress.isEnabled = true
        }
    }
    
    @IBAction func downloadSelected(_ sender: Any) {
        if (GlobalVar.currentLink == "") {
            return
        } else {
            downloadSelect.stringValue = "downloadingdot".localized
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
    
    @IBAction func downloadAll(_ sender: Any) {
        GlobalVar.download_queue = []
        progressIndic.doubleValue = Double(0)
        progressIndic.maxValue = Double(GlobalVar.trackURL.count)
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
            DispatchQueue.main.async() {
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
                            self.progressIndic!.increment(by: 1)
                            GlobalVar.download_queue.append(URL(string: url_prev)!)
                            if (GlobalVar.download_queue.count == GlobalVar.trackURL.count) {
                                self.view.window?.title = "khinsiderripper".localized
                                if (self.downloadWith.titleOfSelectedItem == "downloaddirect".localized) {
                                    let batch = NSStoryboard(name: "Main", bundle: nil).instantiateController(withIdentifier: "downloaderWindow") as! NSWindowController
                                    batch.showWindow(self)
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
                                        let a = NSAlert()
                                        a.messageText = "done".localized
                                        a.informativeText = "filesaved".localized
                                        a.addButton(withTitle: "ok".localized)
                                        a.alertStyle = NSAlert.Style.informational
                                        a.beginSheetModal(for: self.view.window!, completionHandler: nil)
                                    } catch {
                                        print("Failed to save the file!")
                                        let a = NSAlert()
                                        a.messageText = "error".localized
                                        a.informativeText = "savefail".localized
                                        a.addButton(withTitle: "ok".localized)
                                        a.alertStyle = NSAlert.Style.critical
                                        a.beginSheetModal(for: self.view.window!, completionHandler: nil)
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
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func downloadOne(type: String, toDownload: String, name: String) {
        let completed_url = URL(string: "https://downloads.khinsider.com" + toDownload)!
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
        self.downloadSelect.stringValue = "Downloading"
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
                DispatchQueue.main.sync() {
                    self.downloadSelect.stringValue = "downloadselected".localized
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
        downloadSelect.isHidden = false
        print("Selected: " + GlobalVar.currentLink + " from " + GlobalVar.currentName)
    }
    
    @objc func doubleClickOnResultRow() {
        let clickedOn = tableViewer.clickedRow
        if (clickedOn == -1) {
            return
        }
        print("doubleClickOnResultRow \(tableViewer.clickedRow)")
        GlobalVar.currentLink = ""
        //TODO
        downloadAll.isHidden = false
        downloadSelect.isHidden = true
        GlobalVar.mp3 = false
        GlobalVar.flac = false
        GlobalVar.ogg = false
        
        GlobalVar.coverURL = [String]()
        tags = [String]()
        tracklist = [String]()
        tracklisturl = [String]()
        titlelength = [String]()
        GlobalVar.AlbumName = ""
        GlobalVar.tags = [String]()
        GlobalVar.tracks = [String]()
        GlobalVar.trackURL = [String]()
        
        let completed_url = URL(string: base_url + GlobalVar.linkArray[tableViewer.clickedRow].replacingOccurrences(of: base_url, with: "")) // build the URL to process
        GlobalVar.album_url = completed_url
        let task = URLSession.shared.dataTask(with: completed_url!) {(data, response, error) in
            self.recdata = String(data: data!, encoding: .utf8)! // store the received data as a string to be processed
            DispatchQueue.main.async() {
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
                                let songname = self.tags.index(of: "Song Name")!
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
                    print(clickedOn)
                    print(GlobalVar.textArray.count)
                    GlobalVar.AlbumName = GlobalVar.textArray[clickedOn]
                    self.trackTableView.reloadData()
                    self.setAlbumArt()
                    print(self.tracklist.count)
                    print(self.tracklisturl.count)
                    
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
                    self.availableFormats.stringValue = available
                    
                    
                } catch Exception.Error( _, let message) {
                    print(message)
                } catch {
                    print("error")
                }
            }
        }
        task.resume()
        
    }
    
    func update() {
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
}

extension String {
    var localized: String {
        return NSLocalizedString(self, tableName: nil, bundle: Bundle.main, value: "", comment: "")
    }
}


//
//  HomeTableViewController.swift
//  Khinsider Ripper
//
//  Created by ptgms on 22.05.20.
//  Copyright © 2020 ptgms. All rights reserved.
//

import UIKit
import SwiftSoup

class HomeTableViewController: UITableViewController, UISearchBarDelegate {

    @IBOutlet var tableViewer: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    // --- Initialization of project specific variables
    var linkArray = [String]()
    var textArray = [String]()
    
    let base_url = "https://downloads.khinsider.com/"
    let base_search_url = "search?search="
    let base_soundtrack_album_url = "game-soundtracks/album/"
    
    var debug = 0
    
    var recdata = ""
    
    var album_name = ""
    var tracklist = [String]()
    var tracklisturl = [String]()
    var titlelength = [String]()
    
    var tags = [String]()
    // ----
    override func viewDidLoad() {
        super.viewDidLoad()

        searchBar.showsScopeBar = true
        searchBar.delegate = self
        
        //update()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return textArray.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "khinCell", for: indexPath)
        
        cell.textLabel?.text = textArray[indexPath.row]
        cell.detailTextLabel?.text = "Path: " + linkArray[indexPath.row].replacingOccurrences(of: base_url, with: "")
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let preView = storyboard.instantiateViewController(withIdentifier: "albumDetails")
        
        // resseting all Variables to empty in case another album got selected before
        
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
        
        // ---
        
        let completed_url = URL(string: base_url + linkArray[indexPath.row].replacingOccurrences(of: base_url, with: "")) // build the URL to process
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
                    GlobalVar.AlbumName = self.textArray[indexPath.row]
                    self.navigationController?.pushViewController(preView, animated: true)
                    
                    print(self.tracklist.count)
                    print(self.tracklisturl.count)
                    
                    
                } catch Exception.Error( _, let message) {
                    print(message)
                } catch {
                    print("error")
                }
            }
        }
        task.resume()
        
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        linkArray.removeAll()
        textArray.removeAll()
        searchBar.resignFirstResponder()
        let search = searchBar.text!.addingPercentEncoding(withAllowedCharacters:NSCharacterSet.urlQueryAllowed)!
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
                            if (try col.attr("href").contains("game-soundtracks/browse/") || col.attr("href").contains("/forums/")) {
                                continue
                            }
                            let colContent = try! col.text()
                            let colHref = try! col.attr("href")
                            
                            self.textArray.append(colContent)
                            self.linkArray.append(colHref)
                        }
                    }
                    
                    print(self.textArray.count)
                    print(self.linkArray.count)
                    
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
    
    func update() {
        if (linkArray.count == textArray.count) {
            tableViewer.reloadData()
        } else {
            print("Mismatch on both arrays, this shouldn't happen!")
        }
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
}

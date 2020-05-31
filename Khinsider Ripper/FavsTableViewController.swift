//
//  FavsTableViewController.swift
//  Khinsider Ripper
//
//  Created by ptgms on 31.05.20.
//  Copyright © 2020 ptgms. All rights reserved.
//

import UIKit
import SwiftSoup

class FavsTableViewController: UITableViewController {

    
    let base_url = "https://downloads.khinsider.com/"
    let base_search_url = "search?search="
    let base_soundtrack_album_url = "game-soundtracks/album/"
    
    var recdata = ""
    
    var tags = [String]()
    var album_name = ""
    var tracklist = [String]()
    var tracklisturl = [String]()
    var titlelength = [String]()
    var linkArray = [String]()
    var textArray = [String]()
    let defaults = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.tableView.reloadData()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return GlobalVar.fav_name.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "favCell", for: indexPath)

        cell.textLabel?.text = GlobalVar.fav_name[indexPath.row]
        cell.detailTextLabel?.text = GlobalVar.fav_link[indexPath.row]

        return cell
    }
    

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let preView = storyboard.instantiateViewController(withIdentifier: "albumDetails")
        
        recdata = ""
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
        
        let completed_url = URL(string: base_url + GlobalVar.fav_link[indexPath.row].replacingOccurrences(of: base_url, with: "")) // build the URL to process
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
                    GlobalVar.AlbumName = GlobalVar.fav_name[indexPath.row]
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
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let remove = UITableViewRowAction(style: .destructive, title: "Remove") { (action, indexPath) in
            GlobalVar.fav_name.remove(at: indexPath.row)
            GlobalVar.fav_link.remove(at: indexPath.row)
            self.defaults.set(GlobalVar.fav_name, forKey: "fav_name")
            self.defaults.set(GlobalVar.fav_link, forKey: "fav_link")
            self.tableView.reloadData()
        }
        return [remove]
    }

}

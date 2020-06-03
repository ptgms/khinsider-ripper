//
//  DownloadsTableViewController.swift
//  Khinsider Ripper
//
//  Created by ptgms on 03.06.20.
//  Copyright © 2020 ptgms. All rights reserved.
//

import UIKit

class DownloadsTableViewController: UITableViewController {

    /* Here lies code I'd like do dedicate to the people
    *  that helped me with programming up to this point.
    *  If you know me and you're reading this, I mean you.
    *  Yes. you!*/
    
    var Tpath = ""
    
    var files = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        update()
    }


    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return files.count
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        if (files[indexPath.row] != "..") {
            let remove = UITableViewRowAction(style: .destructive, title: "rmv".localized) { (action, indexPath) in
                let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
                let url = NSURL(fileURLWithPath: path)
                var pathComponent = url.appendingPathComponent(self.files[indexPath.row])
                if (self.Tpath != "") {
                    pathComponent = url.appendingPathComponent(self.Tpath)!.appendingPathComponent(self.files[indexPath.row])
                }
                if (pathComponent != nil) {
                    let filePath = pathComponent!.path
                    let fileManager = FileManager.default
                    do {
                        try fileManager.removeItem(at: URL(fileURLWithPath: filePath))
                    } catch {
                        print("error!")
                    }
                    self.update()
                }
            }
            return [remove]
        }
        return nil
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "downCell", for: indexPath)

        cell.textLabel?.text = files[indexPath.row]
        cell.detailTextLabel?.text = "base_dir".localized + Tpath
        if (files[indexPath.row] == "..") {
            cell.detailTextLabel?.text = "gobackdir".localized
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (files[indexPath.row] == "..") {
            Tpath = ""
            update()
            return
        }
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let url = NSURL(fileURLWithPath: path)
        var pathComponent = url.appendingPathComponent(files[indexPath.row])
        if (Tpath != "") {
            pathComponent = url.appendingPathComponent(Tpath)!.appendingPathComponent(files[indexPath.row])
        }
        if (pathComponent != nil) {
            let filePath = pathComponent!.path
            let fileManager = FileManager.default
            var isDir : ObjCBool = false
            print(filePath)
            if fileManager.fileExists(atPath: filePath, isDirectory:&isDir) {
                if isDir.boolValue {
                    Tpath = files[indexPath.row]
                    update()
                } else {
                    var filesToShare = [Any]()
                    filesToShare.append(NSURL(fileURLWithPath: filePath))
                    let activityViewController = UIActivityViewController(activityItems: filesToShare, applicationActivities: nil)
                    self.present(activityViewController, animated: true, completion: nil)
                }
            } else {
                print("File not found, even though it should.")
            }
        }
    }
    
    func update() {
        files = listFiles()!
        if (Tpath != "") {
            files.insert("..", at: 0)
        }
        tableView.reloadData()
    }
    
    func listFiles() -> [String]? {
        let fileMngr = FileManager.default;
        var docs = fileMngr.urls(for: .documentDirectory, in: .userDomainMask)[0].path
        if Tpath != "" {
            docs = fileMngr.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(Tpath).path
        }
        return try? fileMngr.contentsOfDirectory(atPath:docs).sorted()
    }

}

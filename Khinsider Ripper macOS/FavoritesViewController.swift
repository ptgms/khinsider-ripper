//
//  FavoritesViewController.swift
//  Khinsider Ripper macOS
//
//  Created by ptgms on 08.06.20.
//  Copyright © 2020 ptgms. All rights reserved.
//

import Cocoa

class FavoritesViewController: NSViewController, NSTableViewDelegate {

    @IBOutlet weak var tableViewer: NSTableView!
    
    var dataSource: FavoritesTableView!
    let defaults = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.dataSource = FavoritesTableView()
        self.tableViewer.delegate = self.dataSource
        self.tableViewer.dataSource = self.dataSource
        tableViewer.reloadData()
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Open in Browser", action: #selector(self.openInBrowser), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Remove from Favorites", action: #selector(self.removeFromFavs), keyEquivalent: ""))
        tableViewer.menu = menu
        
        tableViewer.doubleAction = #selector(self.doubleClickedFavs)
    }
    
    @objc func openInBrowser() {
        guard tableViewer.clickedRow >= 0 else { return }
        let item = tableViewer.clickedRow
        let url = URL(string: GlobalVar.favs_link[item])!
        if NSWorkspace.shared.open(url) {
            return
        }
    }
 
    @objc func removeFromFavs() {
        guard tableViewer.clickedRow >= 0 else { return }
        let item = tableViewer.clickedRow
        GlobalVar.favs_link.remove(at: item)
        GlobalVar.favs_name.remove(at: item)
        defaults.set(GlobalVar.favs_name, forKey: "favs_name")
        defaults.set(GlobalVar.favs_link, forKey: "favs_link")
        tableViewer.reloadData()
    }
    
    @objc func doubleClickedFavs() {
        guard tableViewer.clickedRow >= 0 else { return }
        let item = tableViewer.clickedRow
        GlobalVar.favPressedNow = item
        NotificationCenter.default.post(name: Notification.Name("reload"), object: nil)
    }
    
    override func viewDidAppear() {
        tableViewer.reloadData()
        print(GlobalVar.favs_name)
    }
    
    
    
}

class FavoritesTableView: NSTableView, NSTableViewDataSource, NSTableViewDelegate {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return GlobalVar.favs_name.count
    }
    
    fileprivate enum CellIdentifiers {
        static let NameCell = "favCell"
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        var text: String = ""
        var cellIdentifier: String = ""
        
        // 1
        //let item = GlobalVar.textArray[safe: row]
        
        guard let item = GlobalVar.favs_name[safe: row] else {
            return nil
        }
        
        // 2
        if tableColumn == tableView.tableColumns[0] {
            text = item
            cellIdentifier = CellIdentifiers.NameCell
        }
        // 3
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellIdentifier), owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = text
            return cell
        }
        return nil
    }
}

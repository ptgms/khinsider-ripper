//
//  TrackViewController.swift
//  Khinsider Ripper macOS
//
//  Created by ptgms on 25.05.20.
//  Copyright © 2020 ptgms. All rights reserved.
//

import Cocoa

class TrackViewController: NSTableView, NSTableViewDataSource, NSTableViewDelegate {
    
    
    fileprivate enum CellIdentifiers {
        static let NameCell = "trackCell"
        static let pathCell = "pathCell"
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        var text: String = ""
        var _: String = ""
        var cellIdentifier: String = ""
        
        
        // 1
        let item = String(row + 1) + ": " + GlobalVar.tracks[row]
        let item2 = GlobalVar.trackURL[row]
        
        // 2
        if tableColumn == tableView.tableColumns[0] {
            text = item
            cellIdentifier = CellIdentifiers.NameCell
        } else if tableColumn == tableView.tableColumns[1] {
            text = item2
            cellIdentifier = CellIdentifiers.pathCell
        }
        // 3
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellIdentifier), owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = text
            return cell
        }
        return nil
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return GlobalVar.tracks.count
    }
    
}


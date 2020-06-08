//
//  AlbumViewController.swift
//  Khinsider Ripper macOS
//
//  Created by ptgms on 25.05.20.
//  Copyright © 2020 ptgms. All rights reserved.
//

import Cocoa

class AlbumViewController: NSTableView, NSTableViewDataSource, NSTableViewDelegate {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return GlobalVar.textArray.count
    }
    
    fileprivate enum CellIdentifiers {
        static let NameCell = "albumCell"
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        var text: String = ""
        var cellIdentifier: String = ""
        
        
        // 1
        //let item = GlobalVar.textArray[safe: row]
        
        guard let item = GlobalVar.textArray[safe: row] else {
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

extension Collection where Indices.Iterator.Element == Index {
    subscript (safe index: Index) -> Iterator.Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

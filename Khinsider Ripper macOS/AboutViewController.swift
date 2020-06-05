//
//  AboutViewController.swift
//  Khinsider Ripper macOS
//
//  Created by ptgms on 05.06.20.
//  Copyright © 2020 ptgms. All rights reserved.
//

import Cocoa

class AboutViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    @IBAction func emailPressed(_ sender: Any) {
        let url = URL(string: "mailto:hello@ptgms.xyz?subject=Khinsider-ripper:%20SUBJECT%20HERE")!
        if NSWorkspace.shared.open(url) {
            return
        }
    }
    
    @IBAction func githubPressed(_ sender: Any) {
        let url = URL(string: "https://github.com/ptgms/khinsider-ripper")!
        if NSWorkspace.shared.open(url) {
            return
        }
    }
    
    
}

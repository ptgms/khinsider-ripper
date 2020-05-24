//
//  TestUIViewController.swift
//  Khinsider Ripper
//
//  Created by ptgms on 22.05.20.
//  Copyright © 2020 ptgms. All rights reserved.
//

import UIKit

class TestUIViewController: UIViewController {
    
    @IBOutlet weak var progBar: UIProgressView!
    @IBOutlet weak var stepponator: UIStepper!
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    @IBAction func stepper(_ sender: Any) {
        progBar.progress = Float(stepponator.value / 17)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

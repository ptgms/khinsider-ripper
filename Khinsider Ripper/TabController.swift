//
//  TabController.swift
//  Khinsider Ripper
//
//  Created by ptgms on 01.06.20.
//  Copyright © 2020 ptgms. All rights reserved.
//

import UIKit
import SwipeableTabBarController

class TabController: SwipeableTabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        swipeAnimatedTransitioning?.animationType = SwipeAnimationType.sideBySide
        tapAnimatedTransitioning?.animationDuration = 0.3
        minimumNumberOfTouches = 2
    }
    
}

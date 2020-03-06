//
//  ViewController.swift
//  demo
//
//  Created by Arian Hadi on 3/4/20.
//  Copyright © 2020 Arian Hadi. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
   
    
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var progress: UIProgressView!
    @IBOutlet weak var unitlabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        let test = DownloadManager(downloadAddress: URL(string:"http://s7.picofile.com/file/8390080576/IMG_4049.JPG")!, segments: 64, downloadSpeedLabel: label, downloadUnitLabel: unitlabel, dedicatedViewController: self, progress: progress)
        test.startDownload()

    }
}


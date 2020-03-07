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
        let test = DownloadManager(downloadAddress: URL(string:"http://dl2.soft98.ir/soft/g/Google.Chrome.80.0.3987.132.x86.zip?1583485079")!, segments: 8, downloadSpeedLabel: label, downloadUnitLabel: unitlabel, dedicatedViewController: self, progress: progress)
        test.startDownload()

    }
}


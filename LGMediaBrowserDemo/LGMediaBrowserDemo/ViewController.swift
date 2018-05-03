//
//  ViewController.swift
//  LGMediaBrowserDemo
//
//  Created by 龚杰洪 on 2018/5/2.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import UIKit
import LGMediaBrowser
import SnapKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let player = LGPlayer(frame: self.view.bounds, mediaURL: URL(string: "https://devstreaming-cdn.apple.com/videos/wwdc/2017/102xyar2647hak3e/102/hls_vod_mvp.m3u8")!)
        player.mediaType = LGMediaType.video
        self.view.addSubview(player)
        
        player.snp.makeConstraints { (maker) in
            maker.edges.equalTo(self.view)
        }
        
//        player.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
//        player.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
//        player.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
//        player.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}


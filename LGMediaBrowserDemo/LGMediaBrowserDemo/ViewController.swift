//
//  ViewController.swift
//  LGMediaBrowserDemo
//
//  Created by 龚杰洪 on 2018/5/2.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import UIKit
import LGMediaBrowser
import AVFoundation

class ViewController: UIViewController {

//    var player: LGPlayerControlView!
    
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        

//        player = LGPlayerControlView(frame: CGRect.zero,
//                                     mediaURL: URL(string: "https://devstreaming-cdn.apple.com/videos/wwdc/2017/102xyar2647hak3e/102/hls_vod_mvp.m3u8")!,
//                                     isMuted: false)
//
//        player.mediaType = LGMediaType.video
//        self.view.addSubview(player)
        let tap = UITapGestureRecognizer(target: self, action: #selector(imageTaped(_:)))
        self.imageView.addGestureRecognizer(tap)
    }
    
    @objc func imageTaped(_ sender: UITapGestureRecognizer) {
        let media = LGMediaBrowser()
        media.targetView = self.imageView
        media.animationImage = UIImage(named: "1510480481")
        media.mediaArray = [LGVideo(mediaLocation: "https://devstreaming-cdn.apple.com/videos/wwdc/2017/102xyar2647hak3e/102/hls_vod_mvp.m3u8",
                                    mediaType: LGMediaType.video,
                                    isLocalFile: false,
                                    placeholderImage: nil),LGVideo(mediaLocation: "https://devstreaming-cdn.apple.com/videos/wwdc/2017/102xyar2647hak3e/102/hls_vod_mvp.m3u8",
                                                                   mediaType: LGMediaType.video,
                                                                   isLocalFile: false,
                                                                   placeholderImage: nil)]
        self.present(media, animated: true) {
            
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
//        player.frame = self.view.bounds
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}


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
//        let audioPath = Bundle.main.path(forResource: "Lenka - Trouble Is a Friend.", ofType: <#T##String?#>)
        media.mediaArray = [LGMediaModel(mediaLocation: "https://s3-us-west-2.amazonaws.com/julyforcd/100/1510480481.jpg",
                                         mediaType: LGMediaType.generalPhoto,
                                         isLocalFile: false,
                                         placeholderImage: UIImage(named: "1510480481")),
                            LGMediaModel(mediaLocation: "http://staticfile.cxylg.com/Lenka%20-%20Trouble%20Is%20a%20Friend.mp3",
                                         mediaType: LGMediaType.audio,
                                         isLocalFile: false,
                                         placeholderImage: nil),
                            LGMediaModel(mediaLocation: "http://staticfile.cxylg.com/94NWfqRSWgta-SCVideo.2.mp4",
                                         mediaType: LGMediaType.video,
                                         isLocalFile: false,
                                         placeholderImage: UIImage(named: "1510480481")),
                            LGMediaModel(mediaLocation: "https://devstreaming-cdn.apple.com/videos/wwdc/2017/102xyar2647hak3e/102/hls_vod_mvp.m3u8",
                                         mediaType: LGMediaType.video,
                                         isLocalFile: false,
                                         placeholderImage: UIImage(named: "1510480481"))]
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


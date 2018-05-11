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
        print("1")
        let media = LGMediaBrowser()
        media.targetView = self.imageView
        media.animationImage = UIImage(named: "1510480481")
        
        var dataArray = [String]()
        print("2")
        dataArray.append("https://s3-us-west-2.amazonaws.com/julyforcd/100/mew_interlaced.png")
        dataArray.append("https://s3-us-west-2.amazonaws.com/julyforcd/100/1510480450.jp2")
        dataArray.append("https://s3-us-west-2.amazonaws.com/julyforcd/100/1510480481.jpg")
        dataArray.append("https://s3-us-west-2.amazonaws.com/julyforcd/100/1518065289.tiff")
        dataArray.append("https://s3-us-west-2.amazonaws.com/julyforcd/100/5ad6b3c630e69.bmp")
        dataArray.append("https://s3-us-west-2.amazonaws.com/julyforcd/100/AnimatedPortableNetworkGraphics.png")
        dataArray.append("https://s3-us-west-2.amazonaws.com/julyforcd/100/C3ZwL.png")
        dataArray.append("https://s3-us-west-2.amazonaws.com/julyforcd/100/Pikachu.gif")
        dataArray.append("https://s3-us-west-2.amazonaws.com/julyforcd/100/animated.webp")
        dataArray.append("https://s3-us-west-2.amazonaws.com/julyforcd/100/bitbug_favicon.ico")
        dataArray.append("https://s3-us-west-2.amazonaws.com/julyforcd/100/google%402x.webp")
        dataArray.append("https://s3-us-west-2.amazonaws.com/julyforcd/100/lime-cat.JPEG")
        dataArray.append("https://s3-us-west-2.amazonaws.com/julyforcd/100/normal_png.png")
        dataArray.append("https://s3-us-west-2.amazonaws.com/julyforcd/100/static_gif.gif")
        dataArray.append("https://s3-us-west-2.amazonaws.com/julyforcd/100/twitter_fav_icon_300.png")
        
        // Only supports iOS11 and above
        dataArray.append("http://staticfile.cxylg.com/IMG_0392.heic")
        
        
        var modelArray = [LGMediaModel]()
        print("3")
        dataArray.forEach { (stringResult) in
            modelArray.append(LGMediaModel(mediaLocation: stringResult,
                                           mediaType: LGMediaType.generalPhoto,
                                           isLocalFile: false,
                                           placeholderImage: UIImage(named: "1510480481")))
        }
        print("4")
        modelArray += [LGMediaModel(mediaLocation: "https://s3-us-west-2.amazonaws.com/julyforcd/100/1510480481.jpg",
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
        
        media.mediaArray = modelArray
        print("5")
        
        print(media)
        self.present(media, animated: true) {
            print("7")
        }
        print("6")
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


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

class MediaBrowserEntranceController: UIViewController {
    
    
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let tap = UITapGestureRecognizer(target: self, action: #selector(imageTaped(_:)))
        self.imageView.addGestureRecognizer(tap)
    }

    
    @objc func imageTaped(_ sender: UITapGestureRecognizer) {
        var dataArray = [String]()
        dataArray.append("https://dtaw5kick3bfu.cloudfront.net/100/%E6%97%A0%E7%A0%81%E5%A4%A7%E5%9B%BE.jpg")
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
        dataArray.forEach { (stringResult) in
            if let model = try? LGMediaModel(thumbnailImageURL: stringResult,
                                             mediaURL: stringResult,
                                             mediaAsset: nil,
                                             mediaType: LGMediaModel.MediaType.generalPhoto,
                                             mediaPosition: LGMediaModel.Position.remoteFile,
                                             thumbnailImage: nil)
            {
                modelArray.append(model)

            }
        }
//        modelArray += [LGMediaModel(thumbnailImageURL: "https://s3-us-west-2.amazonaws.com/julyforcd/100/1510480481.jpg",
//                                    mediaURL: "https://s3-us-west-2.amazonaws.com/julyforcd/100/1510480481.jpg",
//                                    mediaAsset: nil,
//                                    mediaType: LGMediaModel.MediaType.generalPhoto,
//                                    mediaPosition: LGMediaModel.Position.remoteFile),
//                       LGMediaModel(thumbnailImageURL: nil,
//                                    mediaURL: "http://staticfile.cxylg.com/Lenka%20-%20Trouble%20Is%20a%20Friend.mp3",
//                                    mediaAsset: nil,
//                                    mediaType: LGMediaModel.MediaType.audio,
//                                    mediaPosition: LGMediaModel.Position.remoteFile),
//                       LGMediaModel(thumbnailImageURL: nil,
//                                    mediaURL: "http://staticfile.cxylg.com/94NWfqRSWgta-SCVideo.2.mp4",
//                                    mediaAsset: nil,
//                                    mediaType: LGMediaModel.MediaType.video,
//                                    mediaPosition: LGMediaModel.Position.remoteFile),
//                       LGMediaModel(thumbnailImageURL: nil,
//                                    mediaURL: "https://devstreaming-cdn.apple.com/videos/wwdc/2017/102xyar2647hak3e/102/hls_vod_mvp.m3u8",
//                                    mediaAsset: nil,
//                                    mediaType: LGMediaModel.MediaType.video,
//                                    mediaPosition: LGMediaModel.Position.remoteFile)]
        
        let media = LGMediaBrowser(mediaArray: modelArray,
                                   status: LGMediaBrowserStatus.browsingAndEditing,
                                   currentIndex: 0)
        media.targetView = self.imageView
        media.delegate = self
        self.present(media, animated: true) {
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

extension MediaBrowserEntranceController: LGMediaBrowserDelegate {
    func removeMedia(_ browser: LGMediaBrowser, index: Int, reload: @escaping (() -> Void)) {
        reload()
    }
}


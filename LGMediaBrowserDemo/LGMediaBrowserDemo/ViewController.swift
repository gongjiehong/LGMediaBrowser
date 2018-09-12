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

class ViewController: UIViewController, UINavigationBarDelegate {
    
//    var fpsLabel
    
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
        
        testNavigationBar()
        
    }
    
    func testNavigationBar() {
        let navigationBar = UINavigationBar(frame: CGRect(x: 0,
                                                          y: 0,
                                                          width: UIScreen.main.bounds.width,
                                                          height: 64.0))
        navigationBar.delegate = self
        navigationBar.translatesAutoresizingMaskIntoConstraints = false
        
        let titleItem = UINavigationItem(title: "Title")
        navigationBar.items?.append(titleItem)
        
        self.view.addSubview(navigationBar)
        navigationBar.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        navigationBar.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        
        
        if #available(iOS 11.0, *) {
            navigationBar.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor).isActive = true
        } else {
            navigationBar.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        }
    }
    
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return UIBarPosition.topAttached
    }
    
    @objc func imageTaped(_ sender: UITapGestureRecognizer) {
//        let picker = LGCameraCapture()
//        picker.outputSize = CGSize(width: 1, height: 1)
//        picker.maximumVideoRecordingDuration = 20.0
//        picker.videoType = .mp4
//        self.present(picker, animated: true) {
//
//        }
//        let auth = LGUnauthorizedController()
//        self.present(auth, animated: true) {
//
//        }
        

        var config = LGMediaPicker.Configuration.default
        config.resultMediaTypes = .image
        let picker = LGMediaPicker()
        picker.config = config
        self.present(picker, animated: true) {

        }

        let fpsLabel = LGFPSLabel(frame: CGRect(x: UIScreen.main.bounds.width - 80, y: UIScreen.main.bounds.height - 20.0, width: 60, height: 20))
        UIApplication.shared.keyWindow?.addSubview(fpsLabel)
        return
        
        var dataArray = [String]()
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
            modelArray.append(LGMediaModel(thumbnailImageURL: stringResult,
                                           mediaURL: stringResult,
                                           mediaAsset: nil,
                                           mediaType: LGMediaModel.MediaType.generalPhoto,
                                           mediaPosition: LGMediaModel.Position.remoteFile,
                                           thumbnailImage: UIImage(named: "1510480481")))
        }
        modelArray += [LGMediaModel(thumbnailImageURL: "https://s3-us-west-2.amazonaws.com/julyforcd/100/1510480481.jpg",
                                    mediaURL: "https://s3-us-west-2.amazonaws.com/julyforcd/100/1510480481.jpg",
                                    mediaAsset: nil,
                                    mediaType: LGMediaModel.MediaType.generalPhoto,
                                    mediaPosition: LGMediaModel.Position.remoteFile,
                                    thumbnailImage: UIImage(named: "1510480481")),
                       LGMediaModel(thumbnailImageURL: nil,
                                    mediaURL: "http://staticfile.cxylg.com/Lenka%20-%20Trouble%20Is%20a%20Friend.mp3",
                                    mediaAsset: nil,
                                    mediaType: LGMediaModel.MediaType.audio,
                                    mediaPosition: LGMediaModel.Position.remoteFile,
                                    thumbnailImage: UIImage(named: "1510480481")),
                       LGMediaModel(thumbnailImageURL: nil,
                                    mediaURL: "http://staticfile.cxylg.com/94NWfqRSWgta-SCVideo.2.mp4",
                                    mediaAsset: nil,
                                    mediaType: LGMediaModel.MediaType.video,
                                    mediaPosition: LGMediaModel.Position.remoteFile,
                                    thumbnailImage: UIImage(named: "1510480481")),
                       LGMediaModel(thumbnailImageURL: nil,
                                    mediaURL: "https://devstreaming-cdn.apple.com/videos/wwdc/2017/102xyar2647hak3e/102/hls_vod_mvp.m3u8",
                                    mediaAsset: nil,
                                    mediaType: LGMediaModel.MediaType.video,
                                    mediaPosition: LGMediaModel.Position.remoteFile,
                                    thumbnailImage: UIImage(named: "1510480481"))]
        
        let media = LGMediaBrowser(mediaArray: modelArray,
                                   configs: LGMediaBrowserSettings(),
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

extension ViewController: LGMediaBrowserDelegate {
    func removeMedia(_ browser: LGMediaBrowser, index: Int, reload: @escaping (() -> Void)) {
        reload()
    }
}


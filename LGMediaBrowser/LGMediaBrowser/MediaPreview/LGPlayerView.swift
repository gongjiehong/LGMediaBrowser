//
//  LGAudioAndVideoPlayerView.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/5/2.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

/// 播放视频和音频的视图
open class LGPlayerView: UIView, LGMediaPreviewerProtocol {
    
    public var mediaModel: LGMediaModel? {
        didSet {
            mediaModelDidSet()
        }
    }
    
    /// 播放器对象
    public lazy var player: LGPlayer = {
        return LGPlayer()
    }()
    
    /// 是否静音，默认不静音
    open var isMuted: Bool {
        get {
            return self.player.isMuted
        } set {
            self.player.isMuted = newValue
        }
    }
    
    /// 指定当前视图的layerclass，方便播放
    open override class var layerClass: Swift.AnyClass {
        return AVPlayerLayer.self
    }
    
    /// 是否自动播放，默认否
    open var isAutoPlay: Bool = false
    
    public var isPlayVideoAfterDownloadEndsOrExportEnds: Bool = false
    
    /// 通过frame和媒体文件URL进行初始化，可选静音播放
    ///
    /// - Parameters:
    ///   - frame: 视图位置和大小
    ///   - mediaURL: 媒体文件URL，可以是remote URL，也可以是本地文件URL
    ///   - isMuted: 是否如静音，默认不静音
    public convenience init(frame: CGRect, mediaURL: URL? = nil, isMuted: Bool = false) {
        var mediaPlayerItem: AVPlayerItem?
        if let mediaURL = mediaURL {
            mediaPlayerItem = AVPlayerItem(url: mediaURL)
        }
        self.init(frame: frame, mediaPlayerItem: mediaPlayerItem, isMuted: isMuted)
    }
    
    /// 通过frame和媒体文件组装成的AVPlayerItem进行初始化，可选静音播放
    ///
    /// - Parameters:
    ///   - frame: 视图位置和大小
    ///   - mediaPlayerItem: AVPlayerItem
    ///   - isMuted: 是否如静音，默认不静音
    public init(frame: CGRect, mediaPlayerItem: AVPlayerItem? = nil, isMuted: Bool = false) {
        super.init(frame: frame)
        self.isMuted = isMuted
        self.player.replaceCurrentItem(with: mediaPlayerItem)
        constructPlayerAndPlay()
        
        self.backgroundColor = UIColor.clear
    }
    
    /// 通过frame和媒体模型进行初始化，默认不静音
    ///
    /// - Parameters:
    ///   - frame: 视图位置和大小
    ///   - mediaModel: LGMediaModel
    required public init(frame: CGRect, mediaModel: LGMediaModel) {
        super.init(frame: frame)
        self.layer.contents = mediaModel.thumbnailImage?.cgImage
        self.mediaModel = mediaModel
        constructPlayerAndPlay()
    }
    
    /// 设置player并播放
    ///
    /// - Parameter player: 初始化完成的AVPlayer
    private func constructPlayerAndPlay() {
        self.layer.contentsGravity = CALayerContentsGravity.resizeAspect
        if let playerLayer = self.layer as? AVPlayerLayer {
            playerLayer.player = self.player
        }
        self.backgroundColor = UIColor.black
        
        if !isMuted {
            do {
                try AVAudioSession.sharedInstance().setActive(true,
                                                              options: .notifyOthersOnDeactivation)
                try AVAudioSession.sharedInstance().setMode(AVAudioSession.Mode.moviePlayback)
            } catch {
                println(error)
            }
        }
    }
    
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func mediaModelDidSet() {
        if let media = mediaModel {
            self.player.replaceCurrentItem(with: nil)
            self.layer.contents = media.thumbnailImage?.cgImage
        }
    }
    
    func playIfCanPlay() {
        if let media = mediaModel {
            do {
                self.player.replaceCurrentItem(with: nil)
                self.layer.contents = media.thumbnailImage?.cgImage
                
                try media.fetchMoviePlayerItem(withProgress: { (progress, identify) in
                    
                }) { [weak self] (playerItem, identify) in
                    guard let weakSelf = self, weakSelf.mediaModel?.identify == identify else {return}
                    guard let playerItem = playerItem else {return}
                    weakSelf.player.replaceCurrentItem(with: playerItem)
                }
            } catch {
                println(error)
            }
        }
    }
    
    /// 开始播放
    public func play() {
        self.player.play()
    }
    
    /// 暂停播放
    public func pause() {
        self.player.pause()
        self.player.seek(to: CMTime.zero)
    }
    
    /// 自动播放和暂停
    override open func didMoveToSuperview() {
        super.didMoveToSuperview()
        if self.superview == nil {
            pause()
        } else {
            if self.isAutoPlay {
                play()
            }
        }
    }
    
    deinit {
        pause()
        self.player.replaceCurrentItem(with: nil)
    }
}


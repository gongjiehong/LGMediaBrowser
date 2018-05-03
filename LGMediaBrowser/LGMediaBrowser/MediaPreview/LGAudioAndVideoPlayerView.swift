//
//  LGAudioAndVideoPlayerView.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/5/2.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import UIKit
import AVFoundation

/// 播放视频和音频的视图
open class LGAudioAndVideoPlayerView: UIView {
    
    /// 播放器对象
    open weak var player: AVPlayer?
    
    /// 指定当前视图的layerclass，方便播放
    open override class var layerClass: Swift.AnyClass {
        return AVPlayerLayer.self
    }
    
    /// 是否自动播放，默认是
    open var isAutoPlay: Bool = true
    
    /// 通过frame和媒体文件URL进行初始化，可选静音播放
    ///
    /// - Parameters:
    ///   - frame: 视图位置和大小
    ///   - mediaURL: 媒体文件URL，可以是remote URL，也可以是本地文件URL
    ///   - isMuted: 是否如静音，默认不静音
    public convenience init(frame: CGRect, mediaURL: URL, isMuted: Bool = false) {
        let mediaPlayerItem = AVPlayerItem(url: mediaURL)
        self.init(frame: frame, mediaPlayerItem: mediaPlayerItem, isMuted: isMuted)
    }
    
    /// 通过frame和媒体文件组装成的AVPlayerItem进行初始化，可选静音播放
    ///
    /// - Parameters:
    ///   - frame: 视图位置和大小
    ///   - mediaPlayerItem: AVPlayerItem
    ///   - isMuted: 是否如静音，默认不静音
    public init(frame: CGRect, mediaPlayerItem: AVPlayerItem, isMuted: Bool = false) {
        super.init(frame: frame)
        let player = AVPlayer(playerItem: mediaPlayerItem)
        player.isMuted = isMuted
        constructPlayerAndPlay(player)
    }
    
    /// 设置player并播放
    ///
    /// - Parameter player: 初始化完成的AVPlayer
    private func constructPlayerAndPlay(_ player: AVPlayer) {
        self.player = player
        if let playerLayer = self.layer as? AVPlayerLayer {
            playerLayer.player = player
        }
        self.backgroundColor = UIColor.black
    }
    
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    /// 开始播放
    public func play() {
        self.player?.play()
    }
    
    /// 暂停播放
    public func pause() {
        self.player?.pause()
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
        self.player = nil
    }
}


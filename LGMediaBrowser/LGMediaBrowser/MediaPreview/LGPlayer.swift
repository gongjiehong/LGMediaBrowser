//
//  LGPlayer.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/5/2.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import UIKit
import AVFoundation

/// 播放器播放的相关状态回调
public protocol LGPlayerDelegate: NSObjectProtocol {
    func player(_ palyer: LGPlayer, didPlay currentTime: CMTime, loopsCount: Int)
    
    func player(_ player: LGPlayer, didChange item: AVPlayerItem?)
    
    func player(_ player: LGPlayer, didReachEndFor item: AVPlayerItem?)
    
    func player(_ player: LGPlayer, itemReadyToPlay item: AVPlayerItem?)
    
    func player(_ player: LGPlayer, didUpdateLoadedTimeRanges timeRange: CMTimeRange)
    
    func player(_ player: LGPlayer, itemPlaybackBufferIsEmpty item: AVPlayerItem?)
    
    func player(_ player: LGPlayer, playStateDidChanged rate: Float)
}


/// 视频和音频播放器
open class LGPlayer: AVPlayer {
    /// KVO相关context定义
    fileprivate struct KVOContext {
        static var statusChanged = "StatusContext"
        static var itemChanged = "CurrentItemContext"
        static var playbackBufferEmpty = "PlaybackBufferEmptyContext"
        static var loadedTimeRanges = "LoadedTimeRangesContext"
        static var rateChanged = "RateContext"
    }
    
    /// 用于存储上一个AVPlayerItem
    fileprivate var _oldItem: AVPlayerItem?
    fileprivate var _itemsLoopLength: Float64 = 1.0
    fileprivate var _timeObserver: Any?
    
    /// 是否正在播放
    public var isPlaying: Bool {
        return self.rate > 0.0
    }
    
    /// 回调
    public weak var delegate: LGPlayerDelegate?
    
    /// 是否开启了循环播放，开启后播放结束将自动循环
    public var isLoopEnabled: Bool = true {
        didSet {
            self.actionAtItemEnd = isLoopEnabled ? .none : .pause
        }
    }
    
    /// 是否打开了播放时间回调
    public var isSendingPlayMessages: Bool {
        return _timeObserver != nil
    }
    
    
    /// 获取当前总时长
    public var itemDuration: CMTime {
        let ratio = 1.0 / _itemsLoopLength
        if let duration = self.currentItem?.duration {
            return CMTimeMultiply(duration, multiplier: Int32(ratio))
        } else {
            return CMTime.zero
        }
    }
    
    
    /// 可以播放的时长
    public var playableDuration: CMTime {
        if let item = self.currentItem {
            var playableDuration = CMTime.zero
            if item.status != .failed {
                for value in item.loadedTimeRanges {
                    let timeRange = value.timeRangeValue
                    playableDuration = CMTimeAdd(playableDuration, timeRange.duration)
                }
            }
            return playableDuration
        } else {
            return CMTime.zero
        }
    }
    
    /// 初始化并开启播放时间回调
    override public init() {
        super.init()
        addCurrentItemObserver()
    }
    
    /// 通过AVPlayerItem舒适化
    ///
    /// - Parameter item: AVPlayerItem
    override public init(playerItem item: AVPlayerItem?) {
        super.init(playerItem: item)
    }
    
    
    /// 通过URL初始化，支持本地和网络文件
    ///
    /// - Parameter URL: 文件URL
    override public init(url URL: URL) {
        super.init(url: URL)
    }
    
    /// 添加currentItem和rateKVO监听
    func addCurrentItemObserver() {
        self.addObserver(self,
                         forKeyPath: "currentItem",
                         options: .new,
                         context: &KVOContext.itemChanged)
        self.addObserver(self,
                         forKeyPath: "rate",
                         options: .new,
                         context: &KVOContext.rateChanged)
    }
    
    /// 在currentItem生效后添加status，playbackBufferEmpty，loadedTimeRangesKVO监听和播放结束通知监听
    func initObserver() {
        removeOldObserver()
        if let currentItem = self.currentItem {
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(playReachedEnd(_:)),
                                                   name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                                   object: currentItem)
            _oldItem = currentItem
            
            currentItem.addObserver(self,
                                    forKeyPath: "status",
                                    options: .new,
                                    context: &KVOContext.statusChanged)
            
            currentItem.addObserver(self,
                                    forKeyPath: "playbackBufferEmpty",
                                    options: .new,
                                    context: &KVOContext.playbackBufferEmpty)
            
            currentItem.addObserver(self,
                                    forKeyPath: "loadedTimeRanges",
                                    options: .new,
                                    context: &KVOContext.loadedTimeRanges)
        }
        delegate?.player(self, didChange: self.currentItem)
    }
    
    /// 移除KVO监听和播放结束监听
    func removeOldObserver() {
        NotificationCenter.default.removeObserver(self)
        if let oldItem = _oldItem {
            oldItem.removeObserver(self, forKeyPath: "status")
            oldItem.removeObserver(self, forKeyPath: "playbackBufferEmpty")
            oldItem.removeObserver(self, forKeyPath: "loadedTimeRanges")
        }
        _oldItem = nil
    }
    
    deinit {
        self.removeObserver(self, forKeyPath: "currentItem")
        self.removeObserver(self, forKeyPath: "rate")
        self.removeOldObserver()
        self.endSendingPlayMessages()
    }
    
    override open func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?)
    {
        if context == &KVOContext.itemChanged {
            self.initObserver()
        } else if context == &KVOContext.statusChanged {
            func invokeDelegate() {
                delegate?.player(self, itemReadyToPlay: self.currentItem)
            }
            if Thread.isMainThread {
                invokeDelegate()
            } else {
                DispatchQueue.main.async {
                    invokeDelegate()
                }
            }
        } else if context == &KVOContext.loadedTimeRanges {
            func invokeDelegate() {
                if let ranges = self.currentItem?.loadedTimeRanges, ranges.count > 0 {
                    if let range: CMTimeRange = ranges.first?.timeRangeValue {
                        delegate?.player(self, didUpdateLoadedTimeRanges: range)
                    }
                }
            }
            if Thread.isMainThread {
                invokeDelegate()
            } else {
                DispatchQueue.main.async {
                    invokeDelegate()
                }
            }
        } else if context == &KVOContext.playbackBufferEmpty {
            func invokeDelegate() {
                delegate?.player(self, itemPlaybackBufferIsEmpty: self.currentItem)
            }
            if Thread.isMainThread {
                invokeDelegate()
            } else {
                DispatchQueue.main.async {
                    invokeDelegate()
                }
            }
        } else if context == &KVOContext.rateChanged {
            func invokeDelegate() {
                delegate?.player(self, playStateDidChanged: self.rate)
            }
            if Thread.isMainThread {
                invokeDelegate()
            } else {
                DispatchQueue.main.async {
                    invokeDelegate()
                }
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    /// 开始播放过程中的播放时间监听，每秒回调24次
    func beginSendingPlayMessages() {
        if !isSendingPlayMessages {
            _timeObserver = self.addPeriodicTimeObserver(forInterval: CMTime(value: 1,
                                                                             timescale: 24),
                                                         queue: DispatchQueue.main,
                                                         using:
                {[weak self] (resultTime) in
                    guard let weakSelf = self else {
                        return
                    }
                    
                    if resultTime.seconds.isNaN {
                        return
                    }
                    
                    if let delegate = weakSelf.delegate {
                        var itemsLoopLength = 1.0
                        itemsLoopLength = weakSelf._itemsLoopLength
                        let ratio = 1.0 / itemsLoopLength
                        let currentTime = CMTimeMultiplyByFloat64(resultTime, multiplier: ratio)
                        if let durationSeconds = weakSelf.currentItem?.duration.seconds, !durationSeconds.isNaN {
                            let loopCount = resultTime.seconds / durationSeconds / itemsLoopLength
                            delegate.player(weakSelf, didPlay: currentTime, loopsCount: Int(loopCount))
                        }
                    }
            })
        }
    }
    
    /// 关闭播放时间监听
    public func endSendingPlayMessages() {
        if let timeObserver = _timeObserver {
            self.removeTimeObserver(timeObserver)
            _timeObserver = nil
        }
    }
    
    // MARK: -  设置AVPlayerItem
    public func setItemBy(_ stringPath: String?) {
        if let path = stringPath {
            if  let _ = path.range(of: "://") {
                let url = URL(string: path)
                setItemBy(url)
            } else {
                let url = URL(fileURLWithPath: path)
                setItemBy(url)
            }
        } else {
            setItem(nil)
        }
    }
    
    public func setItemBy(_ url: URL?) {
        if let url = url {
            setItem(AVPlayerItem(url: url))
        } else {
            setItem(nil)
        }
    }
    
    
    public func setItemBy(_ asset: AVAsset?) {
        if let asset = asset {
            setItem(AVPlayerItem(asset: asset))
        } else {
            setItem(nil)
        }
    }
    
    public func setItem(_ item: AVPlayerItem?) {
        self.replaceCurrentItem(with: item)
    }
    
    // MARK: -  平滑的循环播放，自动时移到开始位置
    public func setSmoothLoopItemByStringPath(_ stringPath: String?, smoothLoopCount loopCount: Int) {
        guard let path = stringPath else {
            return
        }
        if path.range(of: "://") != nil {
            setSmoothLoopItemBy(URL(string: path), smoothLoopCount: loopCount)
        } else {
            setSmoothLoopItemBy(URL(fileURLWithPath: path), smoothLoopCount: loopCount)
        }
    }
    

    public func setSmoothLoopItemBy(_ url: URL?, smoothLoopCount loopCount: Int) {
        guard let url = url else {
            return
        }
        setSmoothLoopItemBy(AVAsset(url: url), smoothLoopCount: loopCount)
    }

    public func setSmoothLoopItemBy(_ asset: AVAsset?, smoothLoopCount loopCount: Int) {
        guard let asset = asset else {
            return
        }
        let composition = AVMutableComposition()
        let timeRange = CMTimeRange(start: CMTime.zero, duration: asset.duration)
        do {
            for _ in 0..<loopCount {
                try composition.insertTimeRange(timeRange, of: asset, at: composition.duration)
            }
        } catch {
            
        }
        self.setItemBy(composition)
        _itemsLoopLength = Float64(loopCount)
    }
    
    /// 播放结束处理
    ///
    /// - Parameter noti: 播放结束Notification
    @objc func playReachedEnd(_ noti: Notification) {
        if let object = noti.object as? AVPlayerItem, self.currentItem == object {
            if self.isLoopEnabled {
                self.seek(to: CMTime.zero)
                if self.isPlaying {
                    self.play()
                }
            }
            delegate?.player(self, didReachEndFor: self.currentItem)
        }
    }
}



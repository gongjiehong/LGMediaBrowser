//
//  LGPlayer.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/5/2.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import UIKit
import AVFoundation

public protocol LGPlayerDelegate: NSObjectProtocol {
    func player(_ palyer: LGPlayer, didPlay currentTime: CMTime, loopsCount: Int)
    
    func player(_ player: LGPlayer, didChange item: AVPlayerItem?)
    
    func player(_ player: LGPlayer, didReachEndFor item: AVPlayerItem?)
    
    func player(_ player: LGPlayer, itemReadyToPlay item: AVPlayerItem?)
    
    func player(_ player: LGPlayer, didUpdateLoadedTimeRanges timeRange: CMTimeRange)
    
    func player(_ player: LGPlayer, itemPlaybackBufferIsEmpty item: AVPlayerItem?)
    
    func player(_ player: LGPlayer, playStateDidChanged rate: Float)
}


open class LGPlayer: AVPlayer {
    fileprivate struct KVOContext {
        static var statusChanged = "StatusContext"
        static var itemChanged = "CurrentItemContext"
        static var playbackBufferEmpty = "PlaybackBufferEmptyContext"
        static var loadedTimeRanges = "LoadedTimeRangesContext"
        static var rateChanged = "RateContext"
    }
    
    fileprivate var _oldItem: AVPlayerItem?
    fileprivate var _itemsLoopLength: Float64 = 1.0
    fileprivate var _timeObserver: Any?
    
    public var isPlaying: Bool {
        return self.rate > 0.0
    }
    
    
    public weak var delegate: LGPlayerDelegate?
    public var isLoopEnabled: Bool = false {
        didSet {
            self.actionAtItemEnd = isLoopEnabled ? .none : .pause
        }
    }
    public var isSendingPlayMessages: Bool {
        return _timeObserver != nil
    }
    
    
    /// 获取当前总时长
    public var itemDuration: CMTime {
        let ratio = 1.0 / _itemsLoopLength
        if let duration = self.currentItem?.duration {
            return CMTimeMultiply(duration, Int32(ratio))
        } else {
            return kCMTimeZero
        }
    }
    
    
    /// 可以播放的时长
    public var playableDuration: CMTime {
        if let item = self.currentItem {
            var playableDuration = kCMTimeZero
            if item.status != .failed {
                for value in item.loadedTimeRanges {
                    let timeRange = value.timeRangeValue
                    playableDuration = CMTimeAdd(playableDuration, timeRange.duration)
                }
            }
            return playableDuration
        } else {
            return kCMTimeZero
        }
    }
    
    override public init() {
        super.init()
        addCurrentItemObserver()
    }
    
    override public init(playerItem item: AVPlayerItem?) {
        super.init(playerItem: item)
    }
    
    override public init(url URL: URL) {
        super.init(url: URL)
    }
    
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
                        let currentTime = CMTimeMultiplyByFloat64(resultTime, ratio)
                        if let durationSeconds = weakSelf.currentItem?.duration.seconds, !durationSeconds.isNaN {
                            let loopCount = resultTime.seconds / durationSeconds / itemsLoopLength
                            delegate.player(weakSelf, didPlay: currentTime, loopsCount: Int(loopCount))
                        }
                    }
            })
        }
    }
    
    public func endSendingPlayMessages() {
        if let timeObserver = _timeObserver {
            self.removeTimeObserver(timeObserver)
            _timeObserver = nil
        }
    }
    
    
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
        let timeRange = CMTimeRangeMake(kCMTimeZero, asset.duration)
        do {
            for _ in 0..<loopCount {
                try composition.insertTimeRange(timeRange, of: asset, at: composition.duration)
            }
        } catch {
            
        }
        self.setItemBy(composition)
        _itemsLoopLength = Float64(loopCount)
    }
    
    @objc func playReachedEnd(_ noti: Notification) {
        if let object = noti.object as? AVPlayerItem, self.currentItem == object {
            if self.isLoopEnabled {
                self.seek(to: kCMTimeZero)
                if self.isPlaying {
                    self.play()
                }
            }
            delegate?.player(self, didReachEndFor: self.currentItem)
        }
    }
}



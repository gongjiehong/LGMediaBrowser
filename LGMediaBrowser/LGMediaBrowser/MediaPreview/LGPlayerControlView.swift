//
//  LGPlayerViewInterface.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/5/4.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

/// 播放工具条的背景视图
open class LGPlayToolGradientView: UIView {
    /// 渐变模式
    ///
    /// - topToBottom: 从上到下颜色加深
    /// - center: 中间颜色深，上下浅
    public enum Mode {
        case topToBottom
        case center
    }
    
    /// 设置layerClass为CAGradientLayer
    open override class var layerClass: Swift.AnyClass {
        return CAGradientLayer.self
    }
    
    /// 渐变模式，默认从上到下颜色加深topToBottom
    public var mode: Mode = .topToBottom
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        if let layer = self.layer as? CAGradientLayer {
            switch self.mode {
            case .topToBottom:
                layer.colors = [UIColor.clear.cgColor,
                                UIColor.black.withAlphaComponent(0.1).cgColor,
                                UIColor.black.withAlphaComponent(0.2).cgColor]
                layer.locations = [NSNumber(value: 0.0), NSNumber(value: 0.5), NSNumber(value: 1.0)]
                layer.startPoint = CGPoint(x: 0.5, y: 0)
                layer.endPoint = CGPoint(x: 0.5, y: 1)
                break
            case .center:
                layer.colors = [UIColor.black.withAlphaComponent(0.05).cgColor,
                                UIColor.black.withAlphaComponent(0.2).cgColor,
                                UIColor.black.withAlphaComponent(0.05).cgColor]
                layer.locations = [NSNumber(value: 0.0), NSNumber(value: 0.5), NSNumber(value: 1.0)]
                layer.startPoint = CGPoint(x: 0.5, y: 0)
                layer.endPoint = CGPoint(x: 0.5, y: 1)
                break
            }
        }
    }
}

/// <#Description#>
open class LGPlayerControlView: LGPlayerView {
    fileprivate struct ControlsConfig {
        static var labelWidth: CGFloat = 50.0
        static var labelHeight: CGFloat = 20.0
        static var labelFontSize: CGFloat = 12.0
        static var padding: CGFloat = 15.0
        static var smallPlayButtonWidth: CGFloat = 20.0
        static var smallPlayButtonHeight: CGFloat = 20.0
        static var bigPlayButtonWidth: CGFloat = 60.0
        static var bigPlayButtonHeight: CGFloat = 60.0
        static var sliderHeight: CGFloat = 20.0
        static var toolbarHeight: CGFloat = ControlsConfig.sliderHeight + ControlsConfig.padding * 2
    }
    
    lazy var centerPlayButton: UIButton = {
        let button = UIButton(type: UIButton.ButtonType.custom)
        button.setBackgroundImage(UIImage(named: "play_center_big",
                                          in: Bundle(for: LGPlayer.self),
                                          compatibleWith: nil),
                                  for: UIControl.State.normal)
        button.bounds = CGRect(x: 0,
                               y: 0,
                               width: ControlsConfig.bigPlayButtonWidth,
                               height: ControlsConfig.bigPlayButtonHeight)
        button.addTarget(self, action: #selector(centerPlayButtonPressed(_:)), for: UIControl.Event.touchUpInside)
        return button
    }()
    
    lazy var playOrPauseButton: UIButton = {
        let button = UIButton(type: UIButton.ButtonType.custom)
        button.setBackgroundImage(UIImage(named: "menu_play",
                                          in: Bundle(for: LGPlayer.self),
                                          compatibleWith: nil),
                                  for: UIControl.State.normal)
        button.bounds = CGRect(x: 0,
                               y: 0,
                               width: ControlsConfig.smallPlayButtonWidth,
                               height: ControlsConfig.smallPlayButtonHeight)
        button.addTarget(self, action: #selector(playOrPauseButtonPressed(_:)), for: UIControl.Event.touchUpInside)
        return button
    }()
    
    var isSliderTouching: Bool = false
    var isSeeking: Bool = false
    lazy var progressSlider: UISlider = {
        let slider = UISlider(frame: CGRect.zero)
        slider.thumbTintColor = UIColor.white
        slider.setThumbImage(UIImage(named: "slider_handle",
                                     in: Bundle(for: LGPlayerControlView.self),
                                     compatibleWith: nil),
                             for: UIControl.State.normal)
        slider.setThumbImage(UIImage(named: "slider_handle",
                                     in: Bundle(for: LGPlayerControlView.self),
                                     compatibleWith: nil),
                             for: UIControl.State.highlighted)
        slider.addTarget(self, action: #selector(sliderTouchDown(_:)), for: UIControl.Event.touchDown)
        slider.addTarget(self, action: #selector(sliderTouchCancel(_:)), for: UIControl.Event.touchCancel)
        slider.addTarget(self, action: #selector(sliderTouchUpInside(_:)), for: UIControl.Event.touchUpInside)
        slider.addTarget(self, action: #selector(sliderTouchUpOutside(_:)), for: UIControl.Event.touchUpOutside)
        slider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: UIControl.Event.valueChanged)
        return slider
    }()
    
    lazy var totalTimeLabel: UILabel = {
        let label = UILabel(frame: CGRect.zero)
        label.numberOfLines = 1
        label.font = UIFont.systemFont(ofSize: ControlsConfig.labelFontSize)
        label.textColor = UIColor.white
        label.textAlignment = NSTextAlignment.left
        label.text = "00:00"
        return label
    }()
    
    lazy var currentTimeLabel: UILabel = {
        let label = UILabel(frame: CGRect.zero)
        label.numberOfLines = 1
        label.font = UIFont.systemFont(ofSize: ControlsConfig.labelFontSize)
        label.textColor = UIColor.white
        label.text = "00:00"
        label.textAlignment = NSTextAlignment.right
        return label
    }()
    
    var isHiddenTools: Bool = false
    var isAnimating: Bool = false
    
    public var isShowBottomSlideControls: Bool = true
    
    lazy var tapGesture: UITapGestureRecognizer = {
        let tap = UITapGestureRecognizer(target: self, action: #selector(showOrHideControls))
        return tap
    }()
    
    lazy var toolBackgroundView: LGPlayToolGradientView = {
        let toolView = LGPlayToolGradientView(frame: CGRect.zero)
        return toolView
    }()
    
    lazy var progressView: LGSectorProgressView = {
        let temp = LGSectorProgressView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        return temp
    }()
    
    public override init(frame: CGRect, mediaPlayerItem: AVPlayerItem? = nil, isMuted: Bool = false) {
        super.init(frame: frame, mediaPlayerItem: mediaPlayerItem, isMuted: isMuted)
        self.player.delegate = self
        self.player.beginSendingPlayMessages()
        self.addGestureRecognizer(tapGesture)
    }
    
    public required convenience init(frame: CGRect, mediaModel: LGMediaModel)  {
        self.init(frame: frame, mediaURL: nil, isMuted: false)
        self.layer.contents = mediaModel.thumbnailImage?.cgImage
        self.mediaModel = mediaModel
        layoutControlsIfNeeded()
    }
    
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func mediaModelDidSet() {
        let sentinel = fetchSetter.cancel(withNewMediaModel: mediaModel)
        self.player.replaceCurrentItem(with: nil)
        self.layer.contents = mediaModel?.thumbnailImage?.cgImage
        
        if let mediaModel = mediaModel {
            self.progressView.isHidden = false
            self.progressView.isShowError = false
            self.centerPlayButton.isHidden = true
            self.progressView.progress = 0.0
            LGMediaModelFetchSetter.setterQueue.async { [weak self] in
                guard let weakSelf = self else {return}
                var newSentinel = sentinel
                newSentinel = weakSelf.fetchSetter.setOperation(with: sentinel,
                                                                mediaModel: mediaModel,
                                                                progress:
                    { [weak self] (progress) in
                        guard let weakSelf = self, weakSelf.fetchSetter.sentinel == newSentinel else {return}
                        weakSelf.progressView.progress = CGFloat(progress.fractionCompleted)
                    }, videoCompletion: { [weak self] (playerItem, finished, error) in
                        guard let weakSelf = self, weakSelf.fetchSetter.sentinel == newSentinel else {return}
                        guard let playerItem = playerItem else {
                            weakSelf.progressView.isShowError = true
                            return
                        }
                        
                        weakSelf.player.replaceCurrentItem(with: playerItem)
                        weakSelf.progressView.isHidden = true
                        
                        if weakSelf.isAutoPlay && weakSelf.isActive {
                            weakSelf.play()
                        } else {
                            weakSelf.centerPlayButton.isHidden = false
                        }
                })
                
            }
        } else {
            self.progressView.isShowError = true
        }
    }
    
    deinit {
    }
    
    
    public var mediaType: LGMediaModel.MediaType {
        return self.mediaModel?.mediaType ?? .other
    }
    
    private func layoutControlsIfNeeded() {
        func layoutControls() {
            if mediaType == .audio {
                constructAudioPlayerControls()
            } else if mediaType == .video {
                constructVideoPlayerControls()
            } else {
                fatalError("LGPlayer can not support media type: \(mediaType)")
            }
        }
        
        self.addSubview(self.progressView)
        self.progressView.center = self.center
        
        layoutControls()
    }
    
    private func constructAudioPlayerControls() {
        self.addSubview(toolBackgroundView)
        toolBackgroundView.addSubview(playOrPauseButton)
        toolBackgroundView.addSubview(progressSlider)
        toolBackgroundView.addSubview(totalTimeLabel)
        toolBackgroundView.addSubview(currentTimeLabel)
    }
    
    private func constructVideoPlayerControls() {
        self.addSubview(centerPlayButton)
        
        if !isShowBottomSlideControls {
            return
        }
        
        self.addSubview(toolBackgroundView)
        toolBackgroundView.addSubview(playOrPauseButton)
        toolBackgroundView.addSubview(progressSlider)
        toolBackgroundView.addSubview(totalTimeLabel)
        toolBackgroundView.addSubview(currentTimeLabel)
        progressSlider.maximumValue = 0.0
        progressSlider.minimumValue = 0.0
    }
    
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        self.tintColor = UIColor.white
        if self.mediaType == .video {
            layoutVideoControls()
        } else {
            layoutAudioControls()
        }
        
    }
    
    func layoutAudioControls() {
        toolBackgroundView.mode = .center
        toolBackgroundView.frame = CGRect(x: 0,
                                          y: (self.lg_height - ControlsConfig.toolbarHeight) / 2,
                                          width: self.lg_width,
                                          height: ControlsConfig.toolbarHeight)
        
        
        self.playOrPauseButton.frame = CGRect(x: ControlsConfig.padding,
                                              y: ControlsConfig.padding,
                                              width:  ControlsConfig.smallPlayButtonWidth,
                                              height:  ControlsConfig.smallPlayButtonHeight)
        
        self.currentTimeLabel.frame = CGRect(x: ControlsConfig.padding * 2 + ControlsConfig.smallPlayButtonWidth,
                                             y: ControlsConfig.padding,
                                             width: ControlsConfig.labelWidth,
                                             height: ControlsConfig.labelHeight)
        
        var progressSliderOriginX = ControlsConfig.padding * 3
        progressSliderOriginX += ControlsConfig.smallPlayButtonWidth
        progressSliderOriginX += ControlsConfig.labelWidth
        
        var progressSliderWidth = self.bounds.width - (5.0 * ControlsConfig.padding)
        progressSliderWidth -= ControlsConfig.smallPlayButtonWidth
        progressSliderWidth -= (ControlsConfig.labelWidth * 2.0)
        
        self.progressSlider.frame = CGRect(x: progressSliderOriginX,
                                           y: ControlsConfig.padding,
                                           width: progressSliderWidth,
                                           height: ControlsConfig.sliderHeight)
        
        self.totalTimeLabel.frame = CGRect(x: self.bounds.width - ControlsConfig.padding - ControlsConfig.labelWidth,
                                           y: ControlsConfig.padding,
                                           width: ControlsConfig.labelWidth,
                                           height: ControlsConfig.labelHeight)
    }
    
    func layoutVideoControls() {
        self.centerPlayButton.center = self.center
        
        toolBackgroundView.mode = .topToBottom
        toolBackgroundView.frame = CGRect(x: 0,
                                          y: self.lg_height - ControlsConfig.toolbarHeight,
                                          width: self.lg_width,
                                          height: ControlsConfig.toolbarHeight)
        
        self.playOrPauseButton.frame = CGRect(x: ControlsConfig.padding,
                                              y: ControlsConfig.padding,
                                              width:  ControlsConfig.smallPlayButtonWidth,
                                              height:  ControlsConfig.smallPlayButtonHeight)
        
        self.currentTimeLabel.frame = CGRect(x: ControlsConfig.padding * 2 + ControlsConfig.smallPlayButtonWidth,
                                             y: ControlsConfig.padding,
                                             width: ControlsConfig.labelWidth,
                                             height: ControlsConfig.labelHeight)
        
        var progressSliderOriginX = ControlsConfig.padding * 3
        progressSliderOriginX += ControlsConfig.smallPlayButtonWidth
        progressSliderOriginX += ControlsConfig.labelWidth
        
        var progressSliderWidth = self.bounds.width - (5.0 * ControlsConfig.padding)
        progressSliderWidth -= ControlsConfig.smallPlayButtonWidth
        progressSliderWidth -= (ControlsConfig.labelWidth * 2.0)
        
        self.progressSlider.frame = CGRect(x: progressSliderOriginX,
                                           y: ControlsConfig.padding,
                                           width: progressSliderWidth,
                                           height: ControlsConfig.sliderHeight)
        
        self.totalTimeLabel.frame = CGRect(x: self.bounds.width - ControlsConfig.padding - ControlsConfig.labelWidth,
                                           y: ControlsConfig.padding,
                                           width: ControlsConfig.labelWidth,
                                           height: ControlsConfig.labelHeight)
    }
    
    // MARK: -  actions
    @objc func centerPlayButtonPressed(_ sender: UIButton) {
        self.play()
    }
    
    @objc func playOrPauseButtonPressed(_ sender: UIButton) {
        if self.player.rate == 0.0 {
            self.play()
        } else {
            self.pause()
        }
    }
    
    @objc func sliderTouchDown(_ sender: UISlider) {
        isSliderTouching = true
    }
    
    @objc func sliderTouchCancel(_ sender: UISlider) {
        isSliderTouching = false
    }
    
    @objc func sliderTouchUpInside(_ sender: UISlider) {
        isSliderTouching = false
        let value = sender.value
        isSeeking = true
        self.player.seek(to: CMTime(seconds: Double(value), preferredTimescale: 1),
                         completionHandler:
            {[weak self] (isFinished) in
                if Thread.isMainThread {
                    self?.isSeeking = false
                } else {
                    DispatchQueue.main.async { [weak self] in
                        self?.isSeeking = false
                    }
                }
        })
    }
    
    @objc func sliderTouchUpOutside(_ sender: UISlider) {
        isSliderTouching = false
    }
    
    @objc func sliderValueChanged(_ sender: UISlider) {
        if !isSliderTouching {
            return
        }
        let value = Int(sender.value)
        let minutes = value / 60
        let seconds = value % 60
        let formatTime = String(format: "%02d:%02d", minutes, seconds)
        self.currentTimeLabel.text = formatTime
    }
    
    @objc func showOrHideControls() {
        NotificationCenter.default.post(name: LGMediaBrowser.needHideControlsNotification, object: nil)
        if self.mediaType == .audio {
            return
        }
        
        if isAnimating { return }
        if isHiddenTools {
            isAnimating = true
            self.toolBackgroundView.alpha = 0.0
            self.toolBackgroundView.isHidden = false
            UIView.animate(withDuration: 0.3,
                           animations:
                {
                    self.toolBackgroundView.alpha = 1.0
            }) { (isFinished) in
                self.isAnimating = false
                self.isHiddenTools = false
            }
        } else {
            isAnimating = true
            self.toolBackgroundView.alpha = 1.0
            self.toolBackgroundView.isHidden = false
            UIView.animate(withDuration: 0.3,
                           animations:
                {
                    self.toolBackgroundView.alpha = 0.0
            }) { (isFinished) in
                self.isAnimating = false
                self.toolBackgroundView.isHidden = true
                self.isHiddenTools = true
            }
        }
        
    }
    
    func stopPlay() {
        self.player.pause()
        self.player.seek(to: CMTime.zero)
        self.progressSlider.value = 0.0
        self.currentTimeLabel.text = "00:00"
    }
    
    // MARK: -  KVO监听
    
}

extension LGPlayerControlView: LGPlayerDelegate {
    public func player(_ player: LGPlayer, playStateDidChanged rate: Float) {
        if rate > 0 {
            if self.mediaType == .video {
                self.centerPlayButton.isHidden = true
            }
            self.playOrPauseButton.setBackgroundImage(UIImage(named: "menu_pause",
                                                              in: Bundle(for: LGPlayerControlView.self),
                                                              compatibleWith: nil),
                                                      for: UIControl.State.normal)
        } else {
            if self.mediaType == .video {
                self.centerPlayButton.isHidden = false
            }
            self.playOrPauseButton.setBackgroundImage(UIImage(named: "menu_play",
                                                              in: Bundle(for: LGPlayerControlView.self),
                                                              compatibleWith: nil),
                                                      for: UIControl.State.normal)
        }
    }
    
    public func player(_ palyer: LGPlayer, didPlay currentTime: CMTime, loopsCount: Int) {
        if isSliderTouching {
            return
        }
        
        if isSeeking == true {
            return
        }
        
        if currentTime.seconds.isNaN {
            return
        }
        
        let currnetSeconds = Int(currentTime.seconds)
        let minutes = currnetSeconds / 60
        let seconds = currnetSeconds % 60
        let formatTime = String(format: "%02d:%02d", minutes, seconds)
        self.currentTimeLabel.text = formatTime
        
        self.progressSlider.setValue(Float(currnetSeconds), animated: true)
    }
    
    public func player(_ player: LGPlayer, didChange item: AVPlayerItem?) {
        if self.mediaType == .video {
            self.centerPlayButton.isHidden = false
        }
        
        if item == nil {
            self.centerPlayButton.isHidden = true
        }
    }
    
    public func player(_ player: LGPlayer, didReachEndFor item: AVPlayerItem?) {
        
    }
    
    public func player(_ player: LGPlayer, itemReadyToPlay item: AVPlayerItem?) {
        guard let duration = item?.duration else {
            return
        }
        
        if duration.seconds.isNaN {
            return
        }
        if isAutoPlay {
            player.play()
        }
        
        
        
        let totalSeconds = Int(duration.seconds)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        let formatTime = String(format: "%02d:%02d", minutes, seconds)
        self.totalTimeLabel.text = formatTime
        
        self.progressSlider.minimumValue = 0.0
        self.progressSlider.maximumValue = Float(totalSeconds)
    }
    
    public func player(_ player: LGPlayer, didUpdateLoadedTimeRanges timeRange: CMTimeRange) {
        
    }
    
    public func player(_ player: LGPlayer, itemPlaybackBufferIsEmpty item: AVPlayerItem?) {
        
    }
}

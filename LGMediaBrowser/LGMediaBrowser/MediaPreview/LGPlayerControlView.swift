//
//  LGPlayerViewInterface.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/5/4.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import UIKit
import AVFoundation

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
    }
    
    lazy var centerPlayButton: UIButton = {
        let button = UIButton(type: UIButtonType.custom)
        button.setBackgroundImage(UIImage(named: "play_center_big",
                                          in: Bundle(for: LGPlayer.self),
                                          compatibleWith: nil),
                                  for: UIControlState.normal)
        button.bounds = CGRect(x: 0,
                               y: 0,
                               width: ControlsConfig.bigPlayButtonWidth,
                               height: ControlsConfig.bigPlayButtonHeight)
        button.addTarget(self, action: #selector(centerPlayButtonPressed(_:)), for: UIControlEvents.touchUpInside)
        return button
    }()

    lazy var playOrPauseButton: UIButton = {
        let button = UIButton(type: UIButtonType.custom)
        button.setBackgroundImage(UIImage(named: "menu_play",
                                          in: Bundle(for: LGPlayer.self),
                                          compatibleWith: nil),
                                  for: UIControlState.normal)
        button.bounds = CGRect(x: 0,
                               y: 0,
                               width: ControlsConfig.smallPlayButtonWidth,
                               height: ControlsConfig.smallPlayButtonHeight)
        button.addTarget(self, action: #selector(playOrPauseButtonPressed(_:)), for: UIControlEvents.touchUpInside)
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
                             for: UIControlState.normal)
        slider.setThumbImage(UIImage(named: "slider_handle",
                                     in: Bundle(for: LGPlayerControlView.self),
                                     compatibleWith: nil),
                             for: UIControlState.highlighted)
        slider.addTarget(self, action: #selector(sliderTouchDown(_:)), for: UIControlEvents.touchDown)
        slider.addTarget(self, action: #selector(sliderTouchCancel(_:)), for: UIControlEvents.touchCancel)
        slider.addTarget(self, action: #selector(sliderTouchUpInside(_:)), for: UIControlEvents.touchUpInside)
        slider.addTarget(self, action: #selector(sliderTouchUpOutside(_:)), for: UIControlEvents.touchUpOutside)
        slider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: UIControlEvents.valueChanged)
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

    public override init(frame: CGRect, mediaPlayerItem: AVPlayerItem, isMuted: Bool) {
        super.init(frame: frame, mediaPlayerItem: mediaPlayerItem, isMuted: isMuted)
        self.player?.delegate = self
        self.player?.beginSendingPlayMessages()
    }

    /// 通过媒体类型和数据类型进行初始化
    ///
    /// - Parameters:
    ///   - frame: 视图位置和大小
    ///   - mediaLocation: 媒体文件位置
    ///   - mediaType: 媒体文件类型
    ///   - isLocalFile: 是否为本地文件
    ///   - placeholderImage: 占位图
    /// - Throws: 转换URL时出现异常
    public required convenience init(frame: CGRect,
                                     mediaLocation: LGMediaLocation,
                                     mediaType: LGMediaType,
                                     isLocalFile: Bool,
                                     placeholderImage: UIImage?) throws
    {
        let url = try mediaLocation.asURL()
        self.init(frame: frame, mediaURL: url, isMuted: false)
        self.layer.contents = placeholderImage?.cgImage
        self.mediaType = mediaType
        layoutControlsIfNeeded()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    deinit {
    }


    public var mediaType: LGMediaType = LGMediaType.other {
        didSet {
            layoutControlsIfNeeded()
        }
    }

    private func layoutControlsIfNeeded() {
        if mediaType == LGMediaType.audio {
            constructAudioPlayerControls()
        } else if mediaType == LGMediaType.video {
            constructVideoPlayerControls()
        } else {
            fatalError("LGPlayer can not support media type: \(mediaType)")
        }
    }

    private func constructAudioPlayerControls() {
        self.addSubview(playOrPauseButton)
        self.addSubview(progressSlider)
        self.addSubview(totalTimeLabel)
        self.addSubview(currentTimeLabel)
    }

    private func constructVideoPlayerControls() {
        self.addSubview(centerPlayButton)
        self.addSubview(playOrPauseButton)
        self.addSubview(progressSlider)
        self.addSubview(totalTimeLabel)
        self.addSubview(currentTimeLabel)
        progressSlider.maximumValue = 0.0
        progressSlider.minimumValue = 0.0
    }


    override open func layoutSubviews() {
        super.layoutSubviews()
        self.tintColor = UIColor.white
        if self.mediaType == LGMediaType.video {
            layoutVideoControls()
        } else {
            layoutAudioControls()
        }
        
    }
    
    func layoutAudioControls() {
        let labelOriginY = (self.bounds.height - ControlsConfig.labelHeight) / 2.0
        let buttonOriginY = (self.bounds.height - ControlsConfig.smallPlayButtonHeight) / 2.0
        let sliderOriginY = (self.bounds.height - ControlsConfig.sliderHeight) / 2.0
        
        self.playOrPauseButton.frame = CGRect(x: ControlsConfig.padding,
                                              y: buttonOriginY,
                                              width:  ControlsConfig.smallPlayButtonWidth,
                                              height:  ControlsConfig.smallPlayButtonHeight)
        
        self.currentTimeLabel.frame = CGRect(x: ControlsConfig.padding * 2 + ControlsConfig.smallPlayButtonWidth,
                                             y: labelOriginY,
                                             width: ControlsConfig.labelWidth,
                                             height: ControlsConfig.labelHeight)
        
        var progressSliderOriginX = ControlsConfig.padding * 3
        progressSliderOriginX += ControlsConfig.smallPlayButtonWidth
        progressSliderOriginX += ControlsConfig.labelWidth
        
        var progressSliderWidth = self.bounds.width - (5.0 * ControlsConfig.padding)
        progressSliderWidth -= ControlsConfig.smallPlayButtonWidth
        progressSliderWidth -= (ControlsConfig.labelWidth * 2.0)
        
        self.progressSlider.frame = CGRect(x: progressSliderOriginX,
                                           y: sliderOriginY,
                                           width: progressSliderWidth,
                                           height: ControlsConfig.sliderHeight)
        
        self.totalTimeLabel.frame = CGRect(x: self.bounds.width - ControlsConfig.padding - ControlsConfig.labelWidth,
                                           y: labelOriginY,
                                           width: ControlsConfig.labelWidth,
                                           height: ControlsConfig.labelHeight)
    }
    
    func layoutVideoControls() {
        self.centerPlayButton.center = self.center
        
        let smallButtonOriginY = self.bounds.size.height - ControlsConfig.padding - ControlsConfig.smallPlayButtonHeight
        self.playOrPauseButton.frame = CGRect(x: ControlsConfig.padding,
                                              y: smallButtonOriginY,
                                              width:  ControlsConfig.smallPlayButtonWidth,
                                              height:  ControlsConfig.smallPlayButtonHeight)
        
        let currentTimeLabelOriginY = self.bounds.height - ControlsConfig.padding - ControlsConfig.labelHeight
        self.currentTimeLabel.frame = CGRect(x: ControlsConfig.padding * 2 + ControlsConfig.smallPlayButtonWidth,
                                             y: currentTimeLabelOriginY,
                                             width: ControlsConfig.labelWidth,
                                             height: ControlsConfig.labelHeight)
        
        let progressSliderOriginY = self.bounds.height - ControlsConfig.padding - ControlsConfig.sliderHeight
        var progressSliderOriginX = ControlsConfig.padding * 3
        progressSliderOriginX += ControlsConfig.smallPlayButtonWidth
        progressSliderOriginX += ControlsConfig.labelWidth
        
        var progressSliderWidth = self.bounds.width - (5.0 * ControlsConfig.padding)
        progressSliderWidth -= ControlsConfig.smallPlayButtonWidth
        progressSliderWidth -= (ControlsConfig.labelWidth * 2.0)
        
        self.progressSlider.frame = CGRect(x: progressSliderOriginX,
                                           y: progressSliderOriginY,
                                           width: progressSliderWidth,
                                           height: ControlsConfig.sliderHeight)
        
        self.totalTimeLabel.frame = CGRect(x: self.bounds.width - ControlsConfig.padding - ControlsConfig.labelWidth,
                                           y: currentTimeLabelOriginY,
                                           width: ControlsConfig.labelWidth,
                                           height: ControlsConfig.labelHeight)
    }

    // MARK: -  actions
    @objc func centerPlayButtonPressed(_ sender: UIButton) {
        self.play()
    }

    @objc func playOrPauseButtonPressed(_ sender: UIButton) {
        if self.player?.rate == 0.0 {
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
        self.player?.seek(to: CMTime(seconds: Double(value), preferredTimescale: 1),
                          completionHandler: {[weak self] (isFinished) in
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

    // MARK: -  KVO监听

}

extension LGPlayerControlView: LGPlayerDelegate {
    public func player(_ player: LGPlayer, playStateDidChanged rate: Float) {
        if rate > 0 {
            if self.mediaType == LGMediaType.video {
                self.centerPlayButton.isHidden = true
            }
            self.playOrPauseButton.setBackgroundImage(UIImage(named: "menu_pause",
                                                              in: Bundle(for: LGPlayerControlView.self),
                                                              compatibleWith: nil),
                                                      for: UIControlState.normal)
        } else {
            if self.mediaType == LGMediaType.video {
                self.centerPlayButton.isHidden = false
            }
            self.playOrPauseButton.setBackgroundImage(UIImage(named: "menu_play",
                                                              in: Bundle(for: LGPlayerControlView.self),
                                                              compatibleWith: nil),
                                                      for: UIControlState.normal)
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
        self.centerPlayButton.isHidden = false
    }
    
    public func player(_ player: LGPlayer, didReachEndFor item: AVPlayerItem?) {
        
    }
    
    public func player(_ player: LGPlayer, itemReadyToPlay item: AVPlayerItem?) {
        player.play()
        guard let duration = item?.duration else {
            return
        }
        if duration.seconds.isNaN {
            return
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

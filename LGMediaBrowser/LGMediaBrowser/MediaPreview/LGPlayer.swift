//
//  LGPlayer.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/5/2.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import UIKit
import AVFoundation

open class LGPlayer: LGAudioAndVideoPlayerView {
    lazy var centerPlayButton: UIButton = {
        let button = UIButton(type: UIButtonType.custom)
        button.setBackgroundImage(UIImage(named: "play_center_big",
                                          in: Bundle(for: LGPlayer.self),
                                          compatibleWith: nil),
                                  for: UIControlState.normal)
        button.bounds = CGRect(x: 0, y: 0, width: 60.0, height: 60.0)
        button.addTarget(self, action: #selector(centerPlayButtonPressed(_:)), for: UIControlEvents.touchUpInside)
        return button
    }()
    
    lazy var playOrPauseButton: UIButton = {
        let button = UIButton(type: UIButtonType.custom)
        button.setBackgroundImage(UIImage(named: "menu_play",
                                          in: Bundle(for: LGPlayer.self),
                                          compatibleWith: nil),
                                  for: UIControlState.normal)
        button.bounds = CGRect(x: 0, y: 0, width: 20.0, height: 20.0)
        button.addTarget(self, action: #selector(playOrPauseButtonPressed(_:)), for: UIControlEvents.touchUpInside)
        return button
    }()
    
    lazy var progressSlider: UISlider = {
        let slider = UISlider(frame: CGRect.zero)
        slider.thumbTintColor = UIColor.white
        return slider
    }()
    
    lazy var totalTimeLabel: UILabel = {
        let label = UILabel(frame: CGRect.zero)
        label.numberOfLines = 1
        label.font = UIFont.systemFont(ofSize: 14.0)
        label.textColor = UIColor.white
        return label
    }()
    
    lazy var currentTimeLabel: UILabel = {
        let label = UILabel(frame: CGRect.zero)
        label.numberOfLines = 1
        label.font = UIFont.systemFont(ofSize: 14.0)
        label.textColor = UIColor.white
        return label
    }()
    
    private var rateKvoContext: Int = 0
    
    public override init(frame: CGRect, mediaPlayerItem: AVPlayerItem, isMuted: Bool) {
        super.init(frame: frame, mediaPlayerItem: mediaPlayerItem, isMuted: isMuted)
        addObserver()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    deinit {
    }
    
    private func addObserver() {
        guard let player = self.player else {
            return
        }
        let _ = player.observe(\.rate) { (player, value) in
            print(value.newValue)
            let new = value.newValue
            if new == 0.0 {
                if self.mediaType == LGMediaType.video {
                    self.centerPlayButton.isHidden = false
                } else if self.mediaType == LGMediaType.audio {
                    
                } else {
                    // not work
                }
            } else {
                if self.mediaType == LGMediaType.video {
                    self.centerPlayButton.isHidden = true
                } else if self.mediaType == LGMediaType.audio {
                    
                } else {
                    // not work
                }
            }
        }
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
        
        let duration = self.player?.currentItem?.duration
        let currentTime = self.player?.currentItem?.currentTime()
        self.player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1.0,
                                                                 preferredTimescale: CMTimeScale),
                                             queue: DispatchQueue.main,
                                             using: { (time) in
                                                
        })
        print(duration?.seconds, currentTime?.seconds)

    }
    
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        self.centerPlayButton.center = self.center
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
    
    // MARK: -  KVO监听

}

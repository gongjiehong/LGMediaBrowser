//
//  LGAudioConfiguration.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/5/24.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import Foundation
import CoreAudio
import AVFoundation

open class LGAudioConfiguration: LGMediaTypeConfiguration {
    
    public struct DefaultSettings {
        public static var bitrate: UInt64 = 120_000
        public static var numberOfChannels: Int = 2
        public static var sampleRate: Float64 = 44100
        public static var audioFormat: AudioFormatID = 120_000
    }
    
    public var sampleRate: Float64 = DefaultSettings.sampleRate

    public var channelsCount: Int = DefaultSettings.numberOfChannels

    public var format: AudioFormatID = DefaultSettings.audioFormat

    public var audioMix: AVAudioMix?
    
    override public init() {
        super.init()
        self.bitrate = DefaultSettings.bitrate
        self.format = DefaultSettings.audioFormat
        self.channelsCount = DefaultSettings.numberOfChannels
    }
    
    override open func createAssetWriterOptions(using sampleBuffer: CMSampleBuffer?) -> LGOptionsDictionary? {
        if let options = self.options {
            return options
        }

        var sampleRate = self.sampleRate
        var channels = self.channelsCount
        
        switch preset {
        case .low:
            bitrate = 64_000
            channels = 1
            break
        case .medium:
            bitrate = 128_000
            break
        case .high:
            bitrate = 320_000
            break
        default:
            bitrate = 128_000
            break
        }
        
        if let buffer = sampleBuffer {
            if let formatDescription = CMSampleBufferGetFormatDescription(buffer) {
                if let streamBasicDescription = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription) {
                    if sampleRate == 0 {
                        sampleRate = streamBasicDescription.pointee.mSampleRate
                    }
                    
                    if channels == 0 {
                        channels = Int(streamBasicDescription.pointee.mChannelsPerFrame)
                    }
                }
            }
        }
        
        
        if sampleRate == 0 {
            sampleRate = DefaultSettings.sampleRate
        }
        
        if channels == 0 {
            channels = DefaultSettings.numberOfChannels
        }
        
        return [AVFormatIDKey: format,
                AVEncoderBitRateKey: bitrate,
                AVNumberOfChannelsKey: channels,
                AVSampleRateKey: sampleRate]
    }
}

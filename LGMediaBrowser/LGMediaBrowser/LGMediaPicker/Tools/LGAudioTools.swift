//
//  LGAudioTools.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/5/27.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import Foundation
import AVFoundation

public class LGAudioTools {
    public class func overrideCategoryMixWithOthers() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(AVAudioSessionCategoryPlayback, with: AVAudioSessionCategoryOptions.mixWithOthers)
        } catch {
            println(error)
        }
    }
    
    public class func mixAudio(with audioAsset: AVAsset,
                               startTime: CMTime,
                               withVideo videoURL: URL,
                               affineTransform: CGAffineTransform,
                               toURL outputUrl: URL,
                               outputFileType: AVFileType,
                               maxDuration: CMTime,
                               completionBlock block: @escaping (Error?) -> Void)
    {
        let composition = AVMutableComposition()
        let videoTrackComposition = composition.addMutableTrack(withMediaType: AVMediaType.video,
                                                                preferredTrackID: kCMPersistentTrackID_Invalid)
        
        let audioTrackComposition = composition.addMutableTrack(withMediaType: AVMediaType.audio,
                                                                preferredTrackID: kCMPersistentTrackID_Invalid)
        
        let fileAsset = AVURLAsset(url: videoURL, options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
        let videoTracks = fileAsset.tracks(withMediaType: AVMediaType.video)
        
        var duration: CMTime

        if let temp = videoTracks.first?.timeRange.duration {
            if temp > maxDuration {
                duration = maxDuration
            } else {
                duration = temp
            }
        } else {
            duration = kCMTimeZero
        }
        
        for track in audioAsset.tracks(withMediaType: AVMediaType.audio) {
            do {
                try audioTrackComposition?.insertTimeRange(CMTimeRangeMake(startTime, duration),
                                                           of: track,
                                                           at: kCMTimeZero)
            } catch {
                block(error)
                return
            }
        }
        
        for track in videoTracks {
            do {
                try videoTrackComposition?.insertTimeRange(CMTimeRangeMake(startTime, duration),
                                                           of: track,
                                                           at: kCMTimeZero)
            } catch {
                block(error)
            }
        }
        
        videoTrackComposition?.preferredTransform = affineTransform
        let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetPassthrough)
        exportSession?.outputFileType = outputFileType
        exportSession?.shouldOptimizeForNetworkUse = true
        exportSession?.outputURL = outputUrl
        
        exportSession?.exportAsynchronously(completionHandler: {
            if let error = exportSession?.error {
                block(error)
            } else {
                block(nil)
            }
        })
    }
}

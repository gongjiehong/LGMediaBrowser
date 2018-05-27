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
        
        AVFileType.mov
    }
    
    public class func mixAudio(with audioAsset: AVAsset,
                               startTime: CMTime,
                               withVideo videoURL: URL,
                               affineTransform: CGAffineTransform,
                               toURL outputUrl: URL,
                               outputFileType: AVFileType,
                               maxDuration: CMTime,
                               completionBlock block: (Error) -> Void)
    {
        let composition = AVMutableComposition()
        let videoTrackComposition = composition.addMutableTrack(withMediaType: AVMediaType.video,
                                                                preferredTrackID: kCMPersistentTrackID_Invalid)
        
        NSError * error = nil;
        AVMutableComposition * composition = [[AVMutableComposition alloc] init];
        
        AVMutableCompositionTrack * videoTrackComposition = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        
        AVMutableCompositionTrack * audioTrackComposition = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        
        AVURLAsset * fileAsset = [AVURLAsset URLAssetWithURL:inputUrl options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:AVURLAssetPreferPreciseDurationAndTimingKey]];
        
        NSArray * videoTracks = [fileAsset tracksWithMediaType:AVMediaTypeVideo];
        
        CMTime duration = ((AVAssetTrack*)[videoTracks objectAtIndex:0]).timeRange.duration;
        
        // We check if the recorded time if more than the limit
        if (CMTIME_COMPARE_INLINE(duration, >, maxDuration)) {
            duration = maxDuration;
        }
        
        for (AVAssetTrack * track in [audioAsset tracksWithMediaType:AVMediaTypeAudio]) {
            [audioTrackComposition insertTimeRange:CMTimeRangeMake(startTime, duration) ofTrack:track atTime:kCMTimeZero error:&error];
            
            if (error != nil) {
                completionBlock(error);
                return;
            }
        }
        
        for (AVAssetTrack * track in videoTracks) {
            [videoTrackComposition insertTimeRange:CMTimeRangeMake(kCMTimeZero, duration) ofTrack:track atTime:kCMTimeZero error:&error];
            
            if (error != nil) {
                completionBlock(error);
                return;
            }
        }
        
        videoTrackComposition.preferredTransform = affineTransform;
        
        AVAssetExportSession * exportSession = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetPassthrough];
        exportSession.outputFileType = outputFileType;
        exportSession.shouldOptimizeForNetworkUse = YES;
        exportSession.outputURL = outputUrl;
        
        [exportSession exportAsynchronouslyWithCompletionHandler:^ {
            NSError * error = nil;
            if (exportSession.error != nil) {
            NSMutableDictionary * userInfo = [NSMutableDictionary dictionaryWithDictionary:exportSession.error.userInfo];
            NSString * subLocalizedDescription = [userInfo objectForKey:NSLocalizedDescriptionKey];
            [userInfo removeObjectForKey:NSLocalizedDescriptionKey];
            [userInfo setObject:@"Failed to mix audio and video" forKey:NSLocalizedDescriptionKey];
            [userInfo setObject:exportSession.outputFileType forKey:@"OutputFileType"];
            [userInfo setObject:exportSession.outputURL forKey:@"OutputUrl"];
            [userInfo setObject:subLocalizedDescription forKey:@"CauseLocalizedDescription"];
            
            [userInfo setObject:[AVAssetExportSession allExportPresets] forKey:@"AllExportSessions"];
            
            error = [NSError errorWithDomain:@"SCAudioVideoRecorder" code:500 userInfo:userInfo];
            }
            
            completionBlock(error);
            }];
    }
}

//
//  LGAssetExportSession.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/5/28.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import Foundation
import AVFoundation
import CoreVideo

public protocol LGAssetExportSessionDelegate: NSObjectProtocol {
    func assetExportSessionDidUpdateProgress(_ assetExportSession: LGAssetExportSession)
    
    func assetExportSession(_ assetExportSession: LGAssetExportSession,
                            shouldReginReadWriteOn writerInput: AVAssetWriterInput,
                            from output: AVAssetReaderOutput) -> Bool
    
    func assetExportSessionNeedsInputPixelBufferAdaptor(_ assetExportSession: LGAssetExportSession) -> Bool
}

public enum LGAssetExportSessionError: Error {
    case outputURLInvalid
    case outputFileTypeInvalid
    case inputAssetInvalid
    case canNotAddAudioReaderOutput
    case canNotAddVideoReaderOutput
}

public class LGAssetExportSession {
    public var inputAsset: AVAsset?
    
    public var outputURL: URL?
    
    public var outputFileType: AVFileType?
    
    public var videoConfiguration: LGVideoConfiguration = LGVideoConfiguration()
    
    public var audioConfiguration: LGAudioConfiguration = LGAudioConfiguration()
    
    public var error: Error?
    
    public var isCancelled: Bool = false
    
    public var timeRange: CMTimeRange = CMTimeRangeMake(kCMTimeZero, kCMTimePositiveInfinity)
    
    
    public var isTranslatesFilterIntoComposition: Bool = true
    
    public var shouldOptimizeForNetworkUse: Bool = true
    
    public var progress: CGFloat = 0.0
    
    public weak var delegate: LGAssetExportSessionDelegate?
    
    public init(inputAsset: AVAsset) {
        self.inputAsset = inputAsset
    }
    
    public func cancel() {
        
    }
    
    deinit {
        
    }
    
    public func exportAsynchronously(completionHandler handler: @escaping () -> Swift.Void) throws {
        isCancelled = false
        nextAllowedVideoFrame = kCMTimeZero
        
        guard let outputURL = self.outputURL else {
            throw LGAssetExportSessionError.outputURLInvalid
        }
        
        guard let outputFileType = self.outputFileType else {
            throw LGAssetExportSessionError.outputFileTypeInvalid
        }
        
        try FileManager.default.removeItem(at: outputURL)
        
        writer = try AVAssetWriter(outputURL: outputURL, fileType: outputFileType)
        writer.shouldOptimizeForNetworkUse = self.shouldOptimizeForNetworkUse
        writer.metadata = LGRecorderTools.assetWriterMetadata
        
        guard let inputAsset = self.inputAsset else {
            throw LGAssetExportSessionError.inputAssetInvalid
        }
        
        reader = try AVAssetReader(asset: inputAsset)
        reader.timeRange = self.timeRange
        
    }
    
    // MARK: -  private
    var writer: AVAssetWriter!
    var reader: AVAssetReader!
    var videoPixelAdaptor: AVAssetWriterInputPixelBufferAdaptor!

    let audioQueue = DispatchQueue(label: "LGAssetExportSession.AudioQueue")
    let videoQueue = DispatchQueue(label: "LGAssetExportSession.VideoQueue")
    let dispatchGroup = DispatchGroup()
    
    var animationsWereEnabled: Bool = true
    var totalDuration: Float64 = 0.0
    var inputBufferSize: CGSize = CGSize.zero
    var outputBufferSize: CGSize = CGSize.zero
    var outputBufferDiffersFromInput: Bool = false
    
    var videoOutput: AVAssetReaderOutput?
    var audioOutput: AVAssetReaderOutput?
    var videoInput: AVAssetWriterInput?
    var audioInput: AVAssetWriterInput?
    var needsLeaveAudio: Bool = false
    var needsLeaveVideo: Bool = false
    var nextAllowedVideoFrame: CMTime = kCMTimeZero
}

extension LGAssetExportSession {
    func setupAudio(usingTracks audioTracks: [AVAssetTrack]) throws {
        if audioTracks.count > 0, self.audioConfiguration.isEnabled, !self.audioConfiguration.shouldIgnore {
            let audioSettings = audioConfiguration.createAssetWriterOptions(using: nil)
            audioInput = addWriter(mediaType: AVMediaType.audio, withSettings: audioSettings)
            
            var tempReaderOutput: AVAssetReaderOutput
            
            let audioMix = self.audioConfiguration.audioMix
            let settings = [AVFormatIDKey: kAudioFormatLinearPCM]
            if let audioMix = audioMix {
                let audioMixOutput = AVAssetReaderAudioMixOutput(audioTracks: audioTracks, audioSettings: settings)
                audioMixOutput.audioMix = audioMix
                tempReaderOutput = audioMixOutput
            } else {
                tempReaderOutput = AVAssetReaderTrackOutput(track: audioTracks.first!,
                                                  outputSettings: settings)
            }
            tempReaderOutput.alwaysCopiesSampleData = false
            if self.reader.canAdd(tempReaderOutput) {
                self.reader.add(tempReaderOutput)
            } else {
                throw LGAssetExportSessionError.canNotAddAudioReaderOutput
            }
        } else {
            self.audioOutput = nil
            throw LGAssetExportSessionError.canNotAddAudioReaderOutput
        }
    }
    
    func setupVideo(usingTracks videoTracks: [AVAssetTrack]) throws {
        self.inputBufferSize = CGSize.zero
        if videoTracks.count > 0 && self.videoConfiguration.isEnabled && !self.videoConfiguration.shouldIgnore {
            let videoTrack = videoTracks[0]
            let videoSettings = videoConfiguration.createAssetWriterOptions(withVideoSize: videoTrack.naturalSize)
            
            videoInput = self.addWriter(mediaType: AVMediaType.video, withSettings: videoSettings)
            if videoConfiguration.keepInputAffineTransform {
                videoInput?.transform = videoTrack.preferredTransform
            } else {
                videoInput?.transform = self.videoConfiguration.affineTransform
            }
            
            if let videoComposition = self.videoConfiguration.composition {
                self.inputBufferSize = videoComposition.renderSize
            } else {
                self.inputBufferSize = videoTrack.naturalSize
            }
            
            var tempOutputBufferSize = inputBufferSize
            if !self.videoConfiguration.bufferSize.equalTo(CGSize.zero) {
                tempOutputBufferSize = self.videoConfiguration.bufferSize
            }
            
            self.outputBufferSize = tempOutputBufferSize
            
            self.outputBufferDiffersFromInput = self.outputBufferSize.equalTo(self.inputBufferSize)
            
//            ju
            
        } else {
            self.videoOutput = nil
            throw LGAssetExportSessionError.canNotAddVideoReaderOutput
        }
    }
    

//
//    CGSize outputBufferSize = _inputBufferSize;
//    if (!CGSizeEqualToSize(self.videoConfiguration.bufferSize, CGSizeZero)) {
//    outputBufferSize = self.videoConfiguration.bufferSize;
//    }
//
//    _outputBufferSize = outputBufferSize;
//    _outputBufferDiffersFromInput = !CGSizeEqualToSize(_inputBufferSize, outputBufferSize);
//
//    _filter = [self _generateRenderingFilterForVideoSize:outputBufferSize];
//
//    if (videoComposition == nil && _filter != nil && self.translatesFilterIntoComposition) {
//    videoComposition = [_filter videoCompositionWithAsset:_inputAsset];
//    if (videoComposition != nil) {
//    _filter = nil;
//    }
//    }
//
//    NSDictionary *settings = nil;
//    if (_filter != nil || self.videoConfiguration.overlay != nil) {
//    settings = @{
//    (id)kCVPixelBufferPixelFormatTypeKey     : [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA],
//    (id)kCVPixelBufferIOSurfacePropertiesKey : [NSDictionary dictionary]
//    };
//    } else {
//    settings = @{
//    (id)kCVPixelBufferPixelFormatTypeKey     : [NSNumber numberWithUnsignedInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange],
//    (id)kCVPixelBufferIOSurfacePropertiesKey : [NSDictionary dictionary]
//    };
//    }
//
//    AVAssetReaderOutput *reader = nil;
//    if (videoComposition == nil) {
//    reader = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:videoTrack outputSettings:settings];
//    } else {
//    AVAssetReaderVideoCompositionOutput *videoCompositionOutput = [AVAssetReaderVideoCompositionOutput assetReaderVideoCompositionOutputWithVideoTracks:videoTracks videoSettings:settings];
//    videoCompositionOutput.videoComposition = videoComposition;
//    reader = videoCompositionOutput;
//    }
//    reader.alwaysCopiesSampleData = NO;
//
//    if ([_reader canAddOutput:reader]) {
//    [_reader addOutput:reader];
//    _videoOutput = reader;
//    } else {
//    NSLog(@"Unable to add video reader output");
//    }
//
//    [self _setupPixelBufferAdaptorIfNeeded:_filter != nil || self.videoConfiguration.overlay != nil];
//    [self _setupContextIfNeeded];
//    } else {
//    _videoOutput = nil;
//    }
//    }
//
    func addWriter(mediaType: AVMediaType, withSettings settings: [String: Any]) -> AVAssetWriterInput {
        let writerInput = AVAssetWriterInput(mediaType: mediaType, outputSettings: settings)
        if self.writer.canAdd(writerInput) {
            self.writer.add(writerInput)
        }
        return writerInput
    }
    
//    - (AVAssetWriterInput *)addWriter:(NSString *)mediaType withSettings:(NSDictionary *)outputSettings {
//    AVAssetWriterInput *writer = [AVAssetWriterInput assetWriterInputWithMediaType:mediaType outputSettings:outputSettings];
//
//    if ([_writer canAddInput:writer]) {
//    [_writer addInput:writer];
//    }
//
//    return writer;
//    }
}

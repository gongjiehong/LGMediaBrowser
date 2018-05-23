//
//  LGAVEncoder.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/5/23.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import Foundation
import AVFoundation
import CoreVideo

class LGVideoEncoder {
    var videoPath: String
    var writer: AVAssetWriter
    var writerInput: AVAssetWriterInput
    var writerAdaptor: AVAssetWriterInputPixelBufferAdaptor

    
    public init(writePath path: String,
                videoHeight: CGFloat,
                videoWidth: CGFloat,
                videoType: LGCameraCapture.VideoType) throws
    {
        self.videoPath = path
        
        if FileManager.default.fileExists(atPath: path) {
            try FileManager.default.removeItem(atPath: path)
        }
        
        let videoFileURL = URL(fileURLWithPath: path)
        
        var type: AVFileType
        switch videoType {
        case .mov:
            type = AVFileType.mov
            break
        case .mp4:
            type = AVFileType.mp4
            break
//        default:
//            type = AVFileType.mp4
//            break
        }

        writer = try AVAssetWriter(outputURL: videoFileURL, fileType: type)
        let settings: [String: Any] = [AVVideoCodecKey: AVVideoCodecH264,
                                       AVVideoWidthKey: videoWidth,
                                       AVVideoHeightKey: videoHeight,
                                       AVVideoCompressionPropertiesKey: [AVVideoAllowFrameReorderingKey: true]]

        writerInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: settings)
        writerInput.expectsMediaDataInRealTime = true
        
        writerAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writerInput,
                                                       sourcePixelBufferAttributes: nil)
        
        if writer.canAdd(writerInput) {
            writer.add(writerInput)
        }
    }
    
    func finishWithCompletionHandler(_ handler: @escaping () -> Void) {
        writer.finishWriting(completionHandler: handler)
    }
    
    @discardableResult
    func encodeFrame(_ sampleBuffer: CMSampleBuffer) -> Bool{
        if CMSampleBufferDataIsReady(sampleBuffer) {
            switch writer.status {
            case .unknown:
                let startTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                writer.startWriting()
                writer.startSession(atSourceTime: startTime)
                break
            case .failed:
                println("wirter error", writer.error?.localizedDescription as Any)
                break
            default:
                break
            }
            
            if writerInput.isReadyForMoreMediaData == true {
                return writerInput.append(sampleBuffer)
            } else {
                return false
            }
        } else {
            return false
        }
    }
    
    @discardableResult
    func encodePixelBuffer(_ buffer: CVPixelBuffer, frameTime: CMTime) -> Bool {
        switch writer.status {
        case .unknown:
            writer.startWriting()
            writer.startSession(atSourceTime: frameTime)
            break
        case .failed:
            println("wirter error", writer.error?.localizedDescription as Any)
            break
        default:
            break
        }
        
        if writerInput.isReadyForMoreMediaData == true {
            return writerAdaptor.append(buffer, withPresentationTime: frameTime)
        } else {
            return false
        }
    }
}

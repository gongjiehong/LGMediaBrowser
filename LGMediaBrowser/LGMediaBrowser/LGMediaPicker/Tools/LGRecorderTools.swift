//
//  LGSCRecorderTools.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 27/5/18.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import Foundation
import AVFoundation

public class LGRecorderTools {
    public static var bestCaptureSessionPresetCompatibleWithAllDevices: AVCaptureSession.Preset {
        let videoDevices = AVCaptureDevice.devices(for: AVMediaType.video)
        var highestCompatibleDimension: CMVideoDimensions = CMVideoDimensions(width: 0, height: 0)
        var lowestSet = false
        
        for device in videoDevices {
            var highestDeviceDimension = CMVideoDimensions(width: 0, height: 0)
            for format in device.formats {
                let dimension = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
                if dimension.width * dimension.height > highestDeviceDimension.width * highestDeviceDimension.height {
                    highestDeviceDimension = dimension
                }
            }
            
            if !lowestSet ||
                (highestCompatibleDimension.width * highestCompatibleDimension.height >
                highestDeviceDimension.width * highestDeviceDimension.height)
            {
                lowestSet = true
                highestCompatibleDimension = highestDeviceDimension
            }
        }
        
        return captureSessionPresetForDimension(highestCompatibleDimension)
    }
    
    class func captureSessionPresetForDimension(_ videoDimension: CMVideoDimensions) -> AVCaptureSession.Preset {
        if #available(iOS 9.0, *) {
            if videoDimension.width >= 3840 && videoDimension.height > 2160 {
                return AVCaptureSession.Preset.hd4K3840x2160
            }
        } else {
            return AVCaptureSession.Preset.hd1920x1080
        }
        
        if videoDimension.width >= 1920 && videoDimension.height > 1080 {
            return AVCaptureSession.Preset.hd1920x1080
        }
        
        if videoDimension.width >= 1280 && videoDimension.height >= 720 {
            return AVCaptureSession.Preset.hd1280x720
        }
        
        if videoDimension.width >= 960 && videoDimension.height >= 540 {
            return AVCaptureSession.Preset.iFrame960x540
        }
        
        if videoDimension.width >= 640 && videoDimension.height >= 480 {
            return AVCaptureSession.Preset.vga640x480
        }
        
        if videoDimension.width >= 352 && videoDimension.height >= 288 {
            return AVCaptureSession.Preset.cif352x288
        }
        
        return AVCaptureSession.Preset.low
    }
        
    public class func bestCaptureSessionPresetForDevice(_ device: AVCaptureDevice?,
                                                        maxSize: CGSize) -> AVCaptureSession.Preset
    {
        
    }
    
    public class func bestCaptureSessionPresetForDevicePosition(_ position: AVCaptureDevice.Position,
                                                                maxSize: CGSize) -> AVCaptureSession.Preset
    {
        
    }
    
    public class func formatInRange(format: AVCaptureDevice.Format,
                                    frameRate: CMTimeScale,
                                    videoDimensions: CMVideoDimensions = CMVideoDimensions(width: 0, height: 0)) -> Bool
    {
        
    }
    
    public static var assetWriterMetadata: [AVMutableMetadataItem] {
        let creationDate = AVMutableMetadataItem()
        creationDate.keySpace = AVMetadataKeySpace.common
        creationDate.key = AVMetadataKey.commonKeyCreationDate
        creationDate.value = Date().ios8601
        
        let software = AVMutableMetadataItem()
        software.keySpace = AVMetadataKeySpace.common
        software.key = AVMetadataKey.commonKeySoftware
        software.value = "LGCameraCapture"
        
        return [software, creationDate]
    }
    
    public class func videoDeviceForPosition(_ position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        
    }
    
    public class func maxFrameRateForFormat(_ format: AVCaptureDevice.Format?,
                                            minFrameRate: CMTimeScale) -> CMTimeScale
    {
        
    }
}

extension Date {
    static let formatter: DateFormatter = {
        let dateFormatter: DateFormatter = DateFormatter()
        let enUSPOSIXLocal = Locale(identifier: "en_US_POSIX")
        dateFormatter.locale = enUSPOSIXLocal
        dateFormatter.setLocalizedDateFormatFromTemplate("yyyy-MM-dd'T'HH:mm:ssZZZZZ")
        return dateFormatter
    }()
    
    var ios8601: String {
        return Date.formatter.string(from: self)
    }
    
    func fromISO8601(_ ios8601: String) -> Date {
        return Date.formatter.date(from: ios8601)
    }
}

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
    /// 所有输入设备支持的最高质量预设值
    public static var bestCaptureSessionPresetCompatibleWithAllDevices: AVCaptureSession.Preset {
        let deviceTypes = [AVCaptureDevice.DeviceType.builtInWideAngleCamera,
                           AVCaptureDevice.DeviceType.builtInUltraWideCamera,
                           AVCaptureDevice.DeviceType.builtInTelephotoCamera,
                           AVCaptureDevice.DeviceType.builtInDualCamera,
                           AVCaptureDevice.DeviceType.builtInDualWideCamera,
                           AVCaptureDevice.DeviceType.builtInTripleCamera,
                           AVCaptureDevice.DeviceType.builtInTrueDepthCamera]
        
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: deviceTypes,
                                                                      mediaType: AVMediaType.video,
                                                                      position: AVCaptureDevice.Position.unspecified)
        let videoDevices = deviceDiscoverySession.devices
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
    
    /// 从视频尺寸获取最高预设值
    ///
    /// - Parameter videoDimension: 视频尺寸
    /// - Returns: AVCaptureSession.Preset 预设值
    class func captureSessionPresetForDimension(_ videoDimension: CMVideoDimensions) -> AVCaptureSession.Preset {
        if #available(iOS 9.0, *) {
            if videoDimension.width >= 3840 && videoDimension.height >= 2160 {
                return AVCaptureSession.Preset.hd4K3840x2160
            }
        }
        
        if videoDimension.width >= 1920 && videoDimension.height >= 1080 {
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
        
    /// 根据输入设备获取最高预设值
    ///
    /// - Parameters:
    ///   - device: 输入设备
    ///   - maxSize: 允许的最大视频大小
    /// - Returns: AVCaptureSession.Preset 预设值
    public class func bestCaptureSessionPresetForDevice(_ device: AVCaptureDevice?,
                                                        maxSize: CGSize) -> AVCaptureSession.Preset
    {
        if let device = device {
            var highestDeviceDimension = CMVideoDimensions(width: 0, height: 0)
            for format in device.formats {
                let dimension = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
                if dimension.width <= Int32(maxSize.width),
                    dimension.height <= Int32(maxSize.height),
                    dimension.width * dimension.height > highestDeviceDimension.width * highestDeviceDimension.height
                {
                    highestDeviceDimension = dimension
                }
            }
            return captureSessionPresetForDimension(highestDeviceDimension)
        }
        
        return AVCaptureSession.Preset.hd1280x720
    }
    
    /// 根据设备的摄像头获取预设值
    ///
    /// - Parameters:
    ///   - position: 设备的摄像头方向，前置和后置
    ///   - maxSize: 允许的最大视频大小
    /// - Returns: AVCaptureSession.Preset 预设值
    public class func bestCaptureSessionPresetForDevicePosition(_ position: AVCaptureDevice.Position,
                                                                maxSize: CGSize) -> AVCaptureSession.Preset
    {
        return bestCaptureSessionPresetForDevice(videoDeviceForPosition(position), maxSize: maxSize)
    }
    
    /// 根据本机支持的格式化蚕食，相机帧速率和视频大小判断是否被支持
    ///
    /// - Parameters:
    ///   - format: 视频格式化相关信息
    ///   - frameRate: 相机帧速率
    ///   - videoDimensions: 视频大小
    /// - Returns: 是否能被支持
    public class func formatInRange(format: AVCaptureDevice.Format,
                                    frameRate: CMTimeScale,
                                    videoDimensions: CMVideoDimensions = CMVideoDimensions(width: 0, height: 0)) -> Bool
    {
        let size = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
        
        if size.width >= videoDimensions.width && size.height > videoDimensions.height {
            for range in format.videoSupportedFrameRateRanges {
                if range.minFrameDuration.timescale > frameRate, range.maxFrameDuration.timescale <= frameRate {
                    return true
                }
            }
        }
        
        return false
    }
    
    /// 写入的文件头信息
    public static var assetWriterMetadata: [AVMutableMetadataItem] {
        let creationDate = AVMutableMetadataItem()
        creationDate.keySpace = AVMetadataKeySpace.common
        creationDate.key = NSString(string: AVMetadataKey.commonKeyCreationDate.rawValue)
        creationDate.value = NSString(string: Date().ios8601)
        
        let software = AVMutableMetadataItem()
        software.keySpace = AVMetadataKeySpace.common
        software.key = NSString(string: AVMetadataKey.commonKeySoftware.rawValue)
        software.value = NSString(string: "LGCameraCapture")
        
        return [software, creationDate]
    }
    
    /// 根据摄像头方向获取输入设备
    ///
    /// - Parameter position: 摄像头方向
    /// - Returns: 输入设备
    public class func videoDeviceForPosition(_ position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let deviceTypes = [AVCaptureDevice.DeviceType.builtInWideAngleCamera,
                           AVCaptureDevice.DeviceType.builtInUltraWideCamera,
                           AVCaptureDevice.DeviceType.builtInTelephotoCamera,
                           AVCaptureDevice.DeviceType.builtInDualCamera,
                           AVCaptureDevice.DeviceType.builtInDualWideCamera,
                           AVCaptureDevice.DeviceType.builtInTripleCamera,
                           AVCaptureDevice.DeviceType.builtInTrueDepthCamera]
        
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: deviceTypes,
                                                                      mediaType: AVMediaType.video,
                                                                      position: AVCaptureDevice.Position.unspecified)
        let devices = deviceDiscoverySession.devices
        for device in devices where device.position == position {
            return device
        }
        return nil
    }
    
    /// 获取设备的最大帧速率，这里为了性能，其实是获取的正常模式下最小帧速率
    ///
    /// - Parameters:
    ///   - format: 视频格式化方式
    ///   - minFrameRate: 最小帧速率
    /// - Returns: 比对后的最小帧速率
    public class func maxFrameRateForFormat(_ format: AVCaptureDevice.Format?,
                                            minFrameRate: CMTimeScale) -> CMTimeScale
    {
        var lowerTimeScale: CMTimeScale = 0
        
        if let format = format {
            for range in format.videoSupportedFrameRateRanges where (range.minFrameDuration.timescale >= minFrameRate
                && (lowerTimeScale == 0 || range.minFrameDuration.timescale < lowerTimeScale))
            {
                lowerTimeScale = range.minFrameDuration.timescale
            }
        }

        return lowerTimeScale
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
        return Date.formatter.date(from: ios8601) ?? Date()
    }
}

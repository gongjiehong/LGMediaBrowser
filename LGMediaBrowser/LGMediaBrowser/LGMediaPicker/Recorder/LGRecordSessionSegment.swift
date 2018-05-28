//
//  LGRecordSessionSegment.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/5/28.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import Foundation
import AVFoundation

open class LGRecordSessionSegment {
    public struct Keys {
        public static var SegmentFilenamesKey: String = "RecordSegmentFilenames"
        public static var SegmentsKey: String = "Segments"
        public static var SegmentFilenameKey: String = "Filename"
        public static var SegmentInfoKey: String = "Info"
    }
    
    public struct Directorys {
        public static var TemporaryDirectory: String = "TemporaryDirectory"
        public static var CacheDirectory: String = "CacheDirectory"
        public static var DocumentDirectory: String = "DocumentDirectory"
    }
    
    public var url: URL?
    
    public var asset: AVAsset? {
        if let url = self.url {
            return AVAsset(url: url)
        }
        return nil
    }
    
    public var duration: CMTime {
        return self.asset?.duration ?? kCMTimeZero
    }
    
    private var _thumbnail: UIImage?
    public var thumbnail: UIImage? {
        var result: UIImage?
        if let image = _thumbnail {
            result = image
        } else {
            if let asset = self.asset {
                let imageGenerator = AVAssetImageGenerator(asset: asset)
                imageGenerator.appliesPreferredTrackTransform = true
                
                do {
                    let thumbnailImage = try imageGenerator.copyCGImage(at: kCMTimeZero,
                                                                         actualTime: nil)
                    _thumbnail = UIImage(cgImage: thumbnailImage)
                    result = _thumbnail
                    
                } catch {
                    println(error)
                }
            }
        }
        
        return result
    }
    
    private var _lastImage: UIImage?
    public var lastImage: UIImage? {
        var result: UIImage?
        if let image = _lastImage {
            result = image
        } else {
            if let asset = self.asset {
                let imageGenerator = AVAssetImageGenerator(asset: asset)
                imageGenerator.appliesPreferredTrackTransform = true
                
                do {
                    let lastImage = try imageGenerator.copyCGImage(at: kCMTimeZero,
                                                                        actualTime: nil)
                    _lastImage = UIImage(cgImage: lastImage)
                    result = _lastImage
                    
                } catch {
                    println(error)
                }
            }
        }
        
        return result
    }
    
    public var frameRate: Float {
        if let tracks = self.asset?.tracks(withMediaType: AVMediaType.video), let track = tracks.first {
            return track.nominalFrameRate
        }
        
        return 0.0
    }
    
    public private(set) var info: [String: Any]?
    
    public var fileUrlExists: Bool {
        if let path = self.url?.path {
            return FileManager.default.fileExists(atPath: path)
        } else {
            return false
        }
    }
    

    public class func segmentURL(forFilename filename: String, andDirectory directory: String) -> URL {
        var directoryUrl: URL
        if directory == Directorys.TemporaryDirectory {
            directoryUrl = URL(fileURLWithPath: NSTemporaryDirectory())
        } else if directory == Directorys.CacheDirectory {
            if let cacheDir = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.cachesDirectory,
                                                               FileManager.SearchPathDomainMask.userDomainMask,
                                                               true).first
            {
                directoryUrl = URL(fileURLWithPath: cacheDir)
            } else {
                directoryUrl = URL(fileURLWithPath: directory)
                println("Execption: get cache directory failed")
            }
        } else if directory == Directorys.DocumentDirectory {
            if let documentsDir = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory,
                                                                      FileManager.SearchPathDomainMask.userDomainMask,
                                                                      true).first
            {
                directoryUrl = URL(fileURLWithPath: documentsDir)
            } else {
                directoryUrl = URL(fileURLWithPath: directory)
                println("Execption: get documents directory failed")
            }
        } else {
            directoryUrl = URL(fileURLWithPath: directory)
            println("Execption: The folder is not exhaustive")
        }
        
        return directoryUrl.appendingPathComponent(filename)
    }
    
    public init(url: URL?, info: [String: Any]?) {
        self.url = url
        self.info = info
    }


    public convenience init?(dictionaryRepresentation dictionary: [String: Any]?, directory: String?) {
        let info = dictionary?[Keys.SegmentInfoKey] as? [String: Any]
        if let fileName = dictionary?[Keys.SegmentFilenameKey] as? String, let directory = directory {
            let url = LGRecordSessionSegment.segmentURL(forFilename: fileName, andDirectory: directory)
            self.init(url: url, info: info)
        }
        
        return nil
    }
    

    public func deleteFile() {
        if let url = self.url {
            do  {
                try FileManager.default.removeItem(at: url)
            } catch {
                println(error)
            }
            return
        }
        
        println("self.url is invalid")
    }
    
    public var dictionaryRepresentation: [String : Any]? {
        guard let url = self.url else {
            return nil
        }
        if let info = self.info {
            return [Keys.SegmentFilenameKey: url.lastPathComponent,
                    Keys.SegmentInfoKey: info]
        } else {
            return [Keys.SegmentFilenameKey: url.lastPathComponent]
        }
    }

}

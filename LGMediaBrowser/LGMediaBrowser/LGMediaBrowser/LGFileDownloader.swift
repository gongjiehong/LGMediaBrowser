//
//  LGFileDownloader.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/5/18.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import LGHTTPRequest
import LGWebImage

open class LGFileManager {
    public init() {
    }
    
    public static var tempFilesDirectory: String {
        let tempDirSuffix = "LGFileManager/TempFile/"
        let tempDir = NSTemporaryDirectory() + tempDirSuffix
        return tempDir
    }
    
    public static var downloadedFilesDirectory: String {
        let cahceDir = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.cachesDirectory,
                                                           FileManager.SearchPathDomainMask.userDomainMask,
                                                           true)[0]
        let downloadedFileDir = cahceDir + "/LGFileManager/"
        return downloadedFileDir
    }
    
    public static func isFileExist(_ filePath: String) -> Bool {
        let fileManager = FileManager.default
        return fileManager.fileExists(atPath: filePath)
    }
    
    public static func isFileExist(withURLString urlString: String) -> Bool {
        if let md5 = urlString.md5Hash() {
            let path = self.downloadedFilesDirectory + md5
            return isFileExist(path)
        } else {
            return false
        }
    }
    
    public static func filePath(withURLString url: String) -> String {
        let md5 = url.md5Hash() ?? ""
        return self.downloadedFilesDirectory + md5
    }
    
    public static func filePath(withURL url: URL) -> String {
        if url.isFileURL {
            return url.absoluteString
        } else {
            let md5 = url.absoluteString.md5Hash() ?? ""
            return self.downloadedFilesDirectory + md5
        }
    }
    
    /// 根据文件URL删除文件
    ///
    /// - Parameters:
    ///   - url: 文件URL
    ///   - block: 完成回调，返回是否删除成功
    public static func removeFile(byURL url: URL, completedBlock block: ((Bool) -> Void)?) {
        if url.isFileURL {
            DispatchQueue.background.async {
                do {
                    try FileManager.default.removeItem(at: url)
                    block?(true)
                } catch {
                    block?(false)
                }
            }
        } else {
            block?(false)
        }
    }

    public static func fileData(fromURL url: URL) -> Data? {
        if !url.isFileURL {
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            return data
        } catch {
            return nil
        }
    }
}

open class LGFileDownloader {
    public init() {
    }
    
    public typealias ProgressBlock = LGProgressHandler
    public typealias CompletionBlock = ((URL?, Bool, Error?) -> Void)
    
    /// 请求容器，用于存储当前活跃的请求，避免重复下载同一个文件
    private var requestContainer = LGThreadSafeDictionary<String, LGDataRequest>()
    
    private var workQueue = DispatchQueue(label: "com.LGFileDownloader.workQueue",
                                          qos: DispatchQoS.background,
                                          attributes: DispatchQueue.Attributes.concurrent,
                                          autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency.inherit,
                                          target: nil)
    
    public static let `default`: LGFileDownloader = {
        return LGFileDownloader()
    }
    
    public func downloadFile(_ fileURL: LGURLConvertible, progress: ProgressBlock?, completion: CompletionBlock?) {
        do {
            let urlString = try fileURL.asURL().absoluteString
            if let request = requestContainer[urlString] {
            } else {
                
            }
        } catch {
        }
        
        
        
        var receivedData: Data = Data()
        let request = LGURLSessionManager.default.request(fileURL,
                                            method: LGHTTPMethod.get,
                                            parameters: nil,
                                            encoding: LGURLEncoding.default,
                                            headers: nil)
        request.stream { (data) in
            receivedData.append(data)
        }
        
        request.response { (response) in
            
        }
        }

    }
    
}

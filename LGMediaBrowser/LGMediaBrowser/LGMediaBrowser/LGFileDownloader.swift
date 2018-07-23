//
//  LGFileDownloader.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/5/18.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import LGHTTPRequest
import LGWebImage

open class LGFileDownloader {
    
    private struct Helper {
        static var downloaderTempFilesDirectory: String {
            let tempDirSuffix = "LGFileDownloader/TempFile/"
            let tempDir = NSTemporaryDirectory() + tempDirSuffix
            createDirectory(tempDir)
            return tempDir
        }
        
        static var downloaderFilesDirectory: String {
            let cahceDir = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.cachesDirectory,
                                                               FileManager.SearchPathDomainMask.userDomainMask,
                                                               true)[0]
            let downloaderFilesDir = cahceDir + "/LGFileDownloader/"
            createDirectory(downloaderFilesDir)
            return downloaderFilesDir
        }
        
        static func createDirectory(_ dir: String) {
            if FileManager.default.fileExists(atPath: dir) {
            } else {
                do {
                    let url = URL(fileURLWithPath: dir, isDirectory: true)
                    try FileManager.default.createDirectory(at: url,
                                                            withIntermediateDirectories: true,
                                                            attributes: nil)
                } catch {
                    println(error)
                }
            }
        }
        
        static func isFileExist(withRemoteURLString urlString: String) -> Bool {
            let path = filePath(withURLString: urlString)
            return FileManager.default.fileExists(atPath: path)
        }
        
        
        static func filePath(withURLString urlString: String) -> String {
            if let url = URL(string: urlString) {
                return filePath(withURL: url)
            } else {
                return ""
            }
        }
        
        static func filePath(withURL url: URL) -> String {
            if url.isFileURL {
                return url.absoluteString
            } else {
                let md5 = url.absoluteString.md5Hash() ?? ""
                return self.downloaderFilesDirectory + md5 + "." + url.pathExtension
            }
        }
        
        
        static func tempFilePath(withURLString urlString: String) -> String {
            if let url = URL(string: urlString) {
                return tempFilePath(withURL: url)
            } else {
                return ""
            }
        }
        
        static func tempFilePath(withURL url: URL) -> String {
            if url.isFileURL {
                return url.absoluteString
            } else {
                let md5 = url.absoluteString.md5Hash() ?? ""
                return self.downloaderTempFilesDirectory + md5 + "." + url.pathExtension
            }
        }
        
        /// 根据文件URL删除文件
        ///
        /// - Parameters:
        ///   - url: 文件URL
        ///   - block: 完成回调，返回是否删除成功
        static func removeFile(byURL url: URL, completedBlock block: ((Bool) -> Void)?) {
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
        
        static func fileData(fromURL url: URL) -> Data? {
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
    }()
    
    public func downloadFile(_ fileURL: LGURLConvertible, progress: ProgressBlock?, completion: CompletionBlock?) {
        workQueue.async {
            do {
                let urlString = try fileURL.asURL().absoluteString
                let downloadTempPath = Helper.tempFilePath(withURLString: urlString)
                let destinationPath = Helper.filePath(withURLString: urlString)
                
                if FileManager.default.fileExists(atPath: destinationPath) {
                    completion?(URL(fileURLWithPath: destinationPath), true, nil)
                    return
                }
                
                let downloadTempURL = URL(fileURLWithPath: downloadTempPath)
                let destinationURL = URL(fileURLWithPath: destinationPath)
                
                var targetRequest: LGDataRequest?
                if let request = self.requestContainer[urlString] {
                    targetRequest = request
                    
                    targetRequest?.downloadProgress(queue: self.workQueue,
                                                    closure:
                        { (pro) in
                            progress?(pro)
                    })
                    
                    targetRequest?.validate().delegate.queue.cancelAllOperations()
                    
                    targetRequest?.validate().response(queue: self.workQueue,
                                                       completionHandler:
                        { (response) in
                            if response.error == nil {
                                do {
                                    try FileManager.default.moveItem(at: downloadTempURL,
                                                                     to: destinationURL)
                                    completion?(destinationURL, true, nil)
                                } catch {
                                    completion?(nil, false, error)
                                }
                            } else {
                                completion?(nil, false, response.error)
                            }
                            self.requestContainer[urlString] = nil
                            targetRequest = nil
                    })
                } else {
                    var receivedData = Data()
                    let breakPointPath = downloadTempPath
                    let breakPointURL = URL(fileURLWithPath: breakPointPath)
                    if FileManager.default.fileExists(atPath: breakPointPath) {
                        let breakPointData = try Data(contentsOf: breakPointURL)
                        receivedData.append(breakPointData)
                    }
                    
                    var header = LGHTTPHeaders()
                    
                    if receivedData.count > 0 {
                        header["Range"] = "bytes=\(receivedData.count)-"
                    }
                    
                    targetRequest = LGURLSessionManager.default.request(fileURL,
                                                                        method: LGHTTPMethod.get,
                                                                        parameters: nil,
                                                                        encoding: LGURLEncoding.default,
                                                                        headers: header)
                    self.requestContainer[urlString] = targetRequest
                    
                    targetRequest?.downloadProgress(queue: self.workQueue,
                                                    closure:
                        { (pro) in
                        progress?(pro)
                    })
                    
                    targetRequest?.stream(closure: { (data) in
                        receivedData.append(data)
                        
                        // Write Data
                        let inputStream = InputStream(data: data)
                        guard let outputStream = OutputStream(url: downloadTempURL,
                                                              append: true) else { return }
                        
                        inputStream.schedule(in: RunLoop.current, forMode: RunLoop.Mode.default)
                        outputStream.schedule(in: RunLoop.current, forMode: RunLoop.Mode.default)
                        inputStream.open()
                        outputStream.open()
                        
                        while inputStream.hasBytesAvailable && outputStream.hasSpaceAvailable {
                            var buffer = [UInt8](repeating: 0, count: 1024)
                            
                            let bytesRead = inputStream.read(&buffer, maxLength: 1024)
                            if inputStream.streamError != nil || bytesRead < 0 {
                                break
                            }
                            
                            let bytesWritten = outputStream.write(&buffer, maxLength: bytesRead)
                            if outputStream.streamError != nil || bytesWritten < 0 {
                                break
                            }
                            
                            if bytesRead == 0 && bytesWritten == 0 {
                                break
                            }
                        }
                        
                        inputStream.remove(from: RunLoop.current, forMode: RunLoop.Mode.default)
                        outputStream.remove(from: RunLoop.current, forMode: RunLoop.Mode.default)
                        
                        inputStream.close()
                        outputStream.close()
                    })
                    
                    targetRequest?.validate().response(queue: self.workQueue,
                                                       completionHandler:
                        { (response) in
                            if response.error == nil {
                                do {
                                    try FileManager.default.moveItem(at: downloadTempURL,
                                                                     to: destinationURL)
                                    completion?(destinationURL, true, nil)
                                } catch {
                                    completion?(nil, false, error)
                                }
                            } else {
                                completion?(nil, false, response.error)
                            }
                            self.requestContainer[urlString] = nil
                            targetRequest = nil
                    })
                }
            } catch {
                completion?(nil, false, error)
            }
        }
    }
    
    public func remoteURLIsDownloaded(_ url: URL) -> Bool {
        return FileManager.default.fileExists(atPath: Helper.filePath(withURL: url))
    }
    
    public func remoteURLIsDownloaded(_ urlString: String) -> Bool {
        if let url = URL(string: urlString) {
            return remoteURLIsDownloaded(url)
        } else {
            return false
        }
    }
    
    public func clearAllFiles(completion block: ((Bool) -> Void)?) {
        workQueue.async {
            do {
                try FileManager.default.removeItem(at: URL(fileURLWithPath: Helper.downloaderTempFilesDirectory,
                                                           isDirectory: true))
                try FileManager.default.removeItem(at: URL(fileURLWithPath: Helper.downloaderFilesDirectory,
                                                           isDirectory: true))
                block?(true)
            } catch {
                println(error)
                block?(false)
            }
        }
    }
}

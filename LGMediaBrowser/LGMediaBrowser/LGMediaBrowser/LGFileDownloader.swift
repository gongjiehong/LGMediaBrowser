//
//  LGFileDownloader.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/5/18.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import LGHTTPRequest
import LGWebImage

/// 将Dictionary封装为线程安全的Dictionary
public struct LGThreadSafeDictionary<Key, Value>: Sequence where Key : Hashable {
    
    /// 原始Dictionary容器
    private var container: Dictionary<Key, Value> = Dictionary<Key, Value>()
    
    /// 线程锁
    private var lock: NSLock = NSLock()
    
    /// 元素类型定义
    public typealias Element = (key: Key, value: Value)
    
    public init() {
    }
    
    public subscript(key: Key) -> Value? {
        get {
            lock.lock()
            defer {
                lock.unlock()
            }
            return self.container[key]
        } set {
            lock.lock()
            defer {
                lock.unlock()
            }
            self.container[key] = newValue
        }
    }
    
    public var count: Int {
        lock.lock()
        defer {
            lock.unlock()
        }
        return self.container.count
    }
    
    public var isEmpty: Bool {
        return self.count == 0
    }
    
    @discardableResult
    public mutating func removeValue(forKey key: Key) -> Value? {
        lock.lock()
        defer {
            lock.unlock()
        }
        return self.container.removeValue(forKey: key)
    }
    
    public mutating func removeAll(keepingCapacity keepCapacity: Bool = false) {
        lock.lock()
        defer {
            lock.unlock()
        }
        self.container.removeAll(keepingCapacity: keepCapacity)
    }
    
    
    public var keys: Dictionary<Key, Value>.Keys {
        lock.lock()
        defer {
            lock.unlock()
        }
        return self.container.keys
    }
    
    
    public var values: Dictionary<Key, Value>.Values {
        lock.lock()
        defer {
            lock.unlock()
        }
        return self.container.values
    }
    
    public func makeIterator() -> DictionaryIterator<Key, Value> {
        lock.lock()
        defer {
            lock.unlock()
        }
        return self.container.makeIterator()
    }
}

open class LGFileDownloader {
    
    internal struct Helper {
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
                if url.pathExtension.isEmpty {
                    //网易云信坑逼没有后缀的时候强行加后缀
                    if let query = url.query, query == ".mp4" {
                        return self.downloaderFilesDirectory + md5 + query
                    } else {
                        return self.downloaderFilesDirectory + md5
                    }
                } else {
                    return self.downloaderFilesDirectory + md5 + "." + url.pathExtension
                }
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
                if url.pathExtension.isEmpty {
                    //网易云信坑逼没有后缀的时候强行加后缀
                    if let query = url.query, query == ".mp4" {
                        return self.downloaderTempFilesDirectory + md5 + query
                    } else {
                        return self.downloaderTempFilesDirectory + md5
                    }
                } else {
                    return self.downloaderTempFilesDirectory + md5 + "." + url.pathExtension
                }
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
    public typealias DownloadResult = (callbackToken: LGWebImageCallbackToken, operation: LGFileDownloadOperation)
    
    
    private lazy var workQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.qualityOfService = .userInitiated
        queue.isSuspended = false
        queue.name = "com.LGFileDownloader.workQueue"
        return queue
    }()
    
    
    public static let `default`: LGFileDownloader = {
        return LGFileDownloader()
    }()
    
    public func downloadFile(_ fileURL: LGURLConvertible, progress: ProgressBlock?, completion: CompletionBlock?) -> DownloadResult {
        let operation = LGFileDownloadOperation(withURL: fileURL,
                                                progress: progress,
                                                completion: completion)
        let token = UUID().uuidString + "\(CACurrentMediaTime())"
        operation.name = token
        workQueue.addOperation(operation)
        return (token, operation)
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
        workQueue.addOperation {
            do {
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


open class LGFileDownloadOperation: Operation {
    
    public typealias ProgressBlock = LGProgressHandler
    public typealias CompletionBlock = ((URL?, Bool, Error?) -> Void)
    
    private var _isFinished: Bool = false
    open override var isFinished: Bool {
        get {
            lock.lock()
            defer {
                lock.unlock()
            }
            return _isFinished
        } set {
            lock.lock()
            defer {
                lock.unlock()
            }
            if _isFinished != newValue {
                willChangeValue(forKey: "isFinished")
                _isFinished = newValue
                didChangeValue(forKey: "isFinished")
            }
        }
    }
    
    private var _isCancelled: Bool = false
    open override var isCancelled: Bool {
        get {
            lock.lock()
            defer {
                lock.unlock()
            }
            return _isCancelled
        }
        set {
            lock.lock()
            defer {
                lock.unlock()
            }
            if _isCancelled != newValue {
                willChangeValue(forKey: "isCancelled")
                _isCancelled = newValue
                didChangeValue(forKey: "isCancelled")
            }
        }
    }
    
    private var _isExecuting: Bool = false
    open override var isExecuting: Bool {
        get{
            lock.lock()
            defer {
                lock.unlock()
            }
            return _isExecuting
        }
        set {
            lock.lock()
            defer {
                lock.unlock()
            }
            
            if _isExecuting != newValue {
                willChangeValue(forKey: "isExecuting")
                _isExecuting = newValue
                didChangeValue(forKey: "isExecuting")
            }
        }
    }
    
    open override var isConcurrent: Bool {
        return true
    }
    
    open override var isAsynchronous: Bool {
        return true
    }
    
    private var isStarted: Bool = false
    private var lock: NSRecursiveLock = NSRecursiveLock()
    private var taskId: UIBackgroundTaskIdentifier = UIBackgroundTaskIdentifier.invalid
    
    weak var request: LGStreamDownloadRequest?
    var progress: ProgressBlock?
    var completion: CompletionBlock?
    var url: LGURLConvertible = ""
    var destinationURL: URL?
    
    public init(withURL url: LGURLConvertible, progress: ProgressBlock?, completion: CompletionBlock?) {
        super.init()
        self.url = url
        self.progress = progress
        self.completion = completion
    }
    
    
    open override func start() {
        lock.lock()
        defer {
            lock.unlock()
        }
        
        isStarted = true
        
        if isCancelled {
            cancelOperation()
            isFinished = true
        } else if isReady, !isFinished, !isExecuting {
            self.isExecuting = true
            
            do {
                let urlString = try url.asURL().absoluteString
                let destinationPath = LGFileDownloader.Helper.filePath(withURLString: urlString)
                self.destinationURL = URL(fileURLWithPath: destinationPath)
            } catch {
                self.invokeCompletionOnMainThread(nil, isSucceed: false, error: error)
                println(error)
            }
            
            var localReadFinished: Bool = false
            getFileFromLoacal(finished: &localReadFinished)
            if localReadFinished {
                finish()
            } else {
                downloadFileFromRemote()
            }
        }
    }
    
    func getFileFromLoacal(finished: inout Bool) {
        if let destinationURL = destinationURL, FileManager.default.fileExists(atPath: destinationURL.path) {
            self.invokeCompletionOnMainThread(self.destinationURL, isSucceed: true, error: nil)
            finished = true
        }
    }
    
    func downloadFileFromRemote() {
        let request = LGURLSessionManager.default.streamDownload(self.url, to: destinationURL)
        self.request = request
        request.validate().downloadProgress(queue: DispatchQueue.utility) { [weak self] (progress) in
            guard let weakSelf = self  else {return}
            if weakSelf.isCancelled || weakSelf.isFinished {
                return
            }
            
            DispatchQueue.main.async { [weak self] in
                guard let weakSelf = self  else {return}
                if let progressBlock = weakSelf.progress {
                    progressBlock(progress)
                }
            }
        }
        
        request.validate().responseData(queue: DispatchQueue.utility) { [weak self] (response) in
            guard let weakSelf = self  else {return}
            if weakSelf.isCancelled || weakSelf.isFinished {
                return
            }
            
            weakSelf.downloadCompleteProcessor(response)
        }
    }
    
    func downloadCompleteProcessor(_ response: LGHTTPDataResponse<Data>){
        func successProcessor() {
            self.invokeCompletionOnMainThread(self.destinationURL, isSucceed: true, error: nil)
        }
        
        if let error = response.error {
            if let lgError = error as? LGError, let responseCode = lgError.responseCode, responseCode == 416 {
                successProcessor()
            } else {
                self.invokeCompletionOnMainThread(nil, isSucceed: false, error: error)
            }
        } else {
            successProcessor()
        }
    }
    
    func invokeCompletionOnMainThread(_ destinationURL: URL?, isSucceed: Bool, error: Error?) {
        guard let completion = self.completion else {return}
        DispatchQueue.main.async { [weak self] in
            completion(destinationURL, isSucceed, error)
            guard let weakSelf = self else {return}
            if isSucceed {
                weakSelf.finish()
            }
        }
    }
    
    open override func cancel() {
        lock.lock()
        defer {
            lock.unlock()
        }
        
        if !isCancelled {
            super.cancel()
            isCancelled = true
            
            if isExecuting {
                isExecuting = false
            }
            cancelOperation()
        }
        
        if isStarted {
            isFinished = true
        }
    }
    
    override open class func automaticallyNotifiesObservers(forKey key: String) -> Bool {
        if key == "isExecuting" || key == "isFinished" || key == "isCancelled" {
            return false
        } else {
            return super.automaticallyNotifiesObservers(forKey: key)
        }
    }
    
    // MARK: - private
    
    func finish() {
        isExecuting = false
        isFinished = true
        endBackgroundTask()
    }
    
    private func cancelOperation() {
        autoreleasepool { () -> Void in
            endBackgroundTask()
            self.request?.cancel()
        }
    }
    
    private func endBackgroundTask() {
        lock.lock()
        defer {
            lock.unlock()
        }
        
        if self.taskId != UIBackgroundTaskIdentifier.invalid {
            UIApplication.shared.endBackgroundTask(self.taskId)
            self.taskId = UIBackgroundTaskIdentifier.invalid
        }
    }
    
    // MARK: - 销毁
    deinit {
        lock.lock()
        defer {
            lock.unlock()
        }
        
        if isExecuting {
            cancelOperation()
            isCancelled = true
            isFinished = true
        }
    }
}

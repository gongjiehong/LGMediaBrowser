//
//  LGMediaModelFetchManager.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/12/10.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import Foundation


public typealias LGMediaModelFetchCallbackToken = String

public class LGMediaModelFetchManager {
    private lazy var workQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.qualityOfService = .userInitiated
        queue.isSuspended = false
        queue.name = "com.LGWebImageManager.workQueue"
        return queue
    }()
    
    /// 默认单例
    public static let `default`: LGMediaModelFetchManager = {
        return LGMediaModelFetchManager()
    }()
    
    public typealias DownloadResult = (callbackToken: LGMediaModelFetchCallbackToken, operation: LGMediaModelFetchOperation)
    
    public func fetchResult(withMediaModel model: LGMediaModel,
                            progress: LGMediaModelFetchOperation.ProgressBlock? = nil,
                            thumbnailImageCompletion: LGMediaModelFetchOperation.ThumbnailImageCompletionBlock? = nil,
                            imageCompletion: LGMediaModelFetchOperation.ImageCompletionBlock? = nil,
                            videoCompletion: LGMediaModelFetchOperation.VideoCompletionBlock? = nil,
                            audioCompletion: LGMediaModelFetchOperation.AudioCompletionBlock? = nil,
                            livePhotoCompletion: LGMediaModelFetchOperation.LivephotoCompletionBlock? = nil) -> DownloadResult
    {
        let operation = LGMediaModelFetchOperation(withMediaModel: model,
                                                   progress: progress,
                                                   thumbnailImageCompletion: thumbnailImageCompletion,
                                                   imageCompletion: imageCompletion,
                                                   videoCompletion: videoCompletion,
                                                   audioCompletion: audioCompletion,
                                                   livePhotoCompletion: livePhotoCompletion)
        let token = UUID().uuidString + "\(CACurrentMediaTime())"
        operation.name = token
        workQueue.addOperation(operation)
        return (token, operation)
    }
    
    /// 通过token取消回调，但不会取消下载
    ///
    /// - Parameter callbackToken: 某次请求对应的token
    public func cancelWith(callbackToken: LGMediaModelFetchCallbackToken) {
        for operation in self.workQueue.operations where operation.name == callbackToken {
            operation.cancel()
        }
    }
}

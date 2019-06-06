//
//  LGMediaModelFetchSetter.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/12/12.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import Foundation

internal class LGMediaModelFetchSetter {
    private var _mediaModel: LGMediaModel?
    var mediaModel: LGMediaModel? {
        lock.lg_lock()
        defer {
            lock.lg_unlock()
        }
        return _mediaModel
    }
    
    typealias Sentinel = Int64
    
    private var _sentinel: Sentinel = 0
    var sentinel: Sentinel {
        return _sentinel
    }
    
    private let lock = DispatchSemaphore(value: 1)
    private weak var operation: LGMediaModelFetchOperation?
    
    init() {
    }
    
    func setOperation(with sentinel: Sentinel,
                      mediaModel model: LGMediaModel,
                      progress: LGMediaModelFetchOperation.ProgressBlock? = nil,
                      thumbnailImageCompletion: LGMediaModelFetchOperation.ThumbnailImageCompletionBlock? = nil,
                      imageCompletion: LGMediaModelFetchOperation.ImageCompletionBlock? = nil,
                      videoCompletion: LGMediaModelFetchOperation.VideoCompletionBlock? = nil,
                      audioCompletion: LGMediaModelFetchOperation.AudioCompletionBlock? = nil,
                      livePhotoCompletion: LGMediaModelFetchOperation.LivephotoCompletionBlock? = nil) -> Sentinel
    {
        var tempSentinel = sentinel
        if (tempSentinel != _sentinel) {
            return _sentinel
        }
        
        let result = LGMediaModelFetchManager.default.fetchResult(withMediaModel: model,
                                                                  progress: progress,
                                                                  thumbnailImageCompletion: thumbnailImageCompletion,
                                                                  imageCompletion: imageCompletion,
                                                                  videoCompletion: videoCompletion,
                                                                  audioCompletion: audioCompletion,
                                                                  livePhotoCompletion: livePhotoCompletion)
        lock.lg_lock()
        defer {
            lock.lg_unlock()
        }
        
        if tempSentinel == _sentinel {
            if self.operation != nil {
                self.operation?.cancel()
            }
            self.operation = result.operation
            tempSentinel = OSAtomicIncrement64Barrier(&_sentinel)
        } else {
            result.operation.cancel()
        }
        return tempSentinel
    }
    
    @discardableResult
    func cancel(withNewMediaModel model: LGMediaModel? = nil) -> Sentinel {
        var tempSentinel: Sentinel
        lock.lg_lock()
        defer {
            lock.lg_unlock()
        }
        
        if self.operation != nil {
            self.operation?.cancel()
            self.operation = nil
        }
        
        _mediaModel = model
        tempSentinel = OSAtomicIncrement64Barrier(&_sentinel)
        return tempSentinel
    }
    
    static let setterQueue: DispatchQueue = {
        let queue = DispatchQueue(label: "cxylg.LGMediaModelFetchSetter.setterQueue",
                                  attributes: DispatchQueue.Attributes(rawValue: 1),
                                  target: DispatchQueue.background)
        return queue
    }()
    
    deinit {
        OSAtomicIncrement64Barrier(&_sentinel)
        if let operation = self.operation {
            operation.cancel()
        }
    }
}



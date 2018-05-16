//
//  LGForceTouchPreviewController.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/5/16.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import UIKit
import LGWebImage
import PhotosUI

open class LGForceTouchPreviewController: UIViewController {
    public var mediaModel: LGMediaModel?
    public var currentIndex: Int = 0
    
    var requestId: PHImageRequestID = 0
    
    lazy var imageView: LGAnimatedImageView = {
        let temp = LGAnimatedImageView(frame: CGRect.zero)
        temp.contentMode = UIViewContentMode.scaleAspectFill
        temp.clipsToBounds = true
        return temp
    }()
    
    lazy var progressView: LGSectorProgressView = {
        let temp = LGSectorProgressView(frame: CGRect.zero)
        return temp
    }()
    
    @available(iOS 9.1, *)
    lazy var livePhotoView: PHLivePhotoView = {
        let temp = PHLivePhotoView(frame: CGRect.zero)
        temp.clipsToBounds = true
        temp.contentMode = UIViewContentMode.scaleAspectFill
        return temp
    }()
    
    lazy var playerView: LGPlayerView? = {
        do {
            if let model = self.mediaModel {
                let temp = try LGPlayerView(frame: self.view.bounds, mediaModel: model)
                return temp
            }
            return nil
        } catch {
            return nil
        }
    }()
    
    override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public convenience init(mediaModel: LGMediaModel, currentIndex: Int) {
        self.init(nibName: nil, bundle: nil)
        self.mediaModel = mediaModel
        self.currentIndex = currentIndex
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        setupSubViews()
    }
    
    func setupSubViews() {
        self.progressView.frame = CGRect(x: 0, y: 0, width: 50.0, height: 50.0)
        self.view.addSubview(self.progressView)
        self.progressView.center = self.view.center
        if let model = self.mediaModel {
            switch model.mediaType {
            case .generalPhoto:
                setupGeneralPhotoView()
                break
            case .livePhoto:
                setupLivePhotoView()
                break
            case .video:
                setupVideoView()
                break
            case .audio:
                setupAudioView()
                break
            default:
                break
            }
        } else {
            self.progressView.isShowError = true
            self.view.bringSubview(toFront: self.progressView)
        }
    }
    
    func setupGeneralPhotoView() {
        self.view.addSubview(self.imageView)
        self.view.bringSubview(toFront: self.progressView)
        self.imageView.frame = self.view.bounds
        if let url = self.mediaModel?.mediaLocation.toURL() {
            self.imageView.lg_setImageWithURL(url,
                                              placeholder: nil,
                                              options: LGWebImageOptions.default,
                                              progressBlock:
                {[weak self] (progress) in
                    self?.progressView.progress = CGFloat(progress.fractionCompleted)
            }, transformBlock: nil)
            {[weak self] (resultImage, imageURL, sourceType, imageStage, error) in
                if error == nil {
                    self?.progressView.isHidden = true
                } else {
                    self?.progressView.isShowError = true
                }
            }
        } else {
            self.progressView.isShowError = true
        }
    }
    
    func setupLivePhotoView() {
        
    }
    
    func setupVideoView() {
        
    }
    
    func setupAudioView() {
        
    }
}

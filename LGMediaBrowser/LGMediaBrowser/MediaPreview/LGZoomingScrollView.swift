//
//  LGZoomingScrollView.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/4/24.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import Foundation
import LGWebImage
import LGHTTPRequest

open class LGZoomingScrollView: UIScrollView {
    var mediaModel: LGMediaModel? {
        didSet {
            layoutImageIfNeeded()
        }
    }
    
    public private(set) var imageView: LGTapDetectingImageView!
    fileprivate var progressView: LGSectorProgressView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupDefault()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupDefault()
    }
    
    func setupDefault() {
        // image
        imageView = LGTapDetectingImageView(frame: self.bounds)
        imageView.detectingDelegate = self
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .clear
        addSubview(imageView)
        
        progressView = LGSectorProgressView(frame: CGRect(x: 0, y: 0, width: 50, height: 50), isShowError: false)
        addSubview(progressView)
        
        self.backgroundColor = .clear
        self.delegate = self
        self.showsHorizontalScrollIndicator = false
        self.showsVerticalScrollIndicator = false
        self.decelerationRate = UIScrollView.DecelerationRate.fast
        self.autoresizingMask = [.flexibleWidth,
                                 .flexibleTopMargin,
                                 .flexibleBottomMargin,
                                 .flexibleRightMargin,
                                 .flexibleLeftMargin]
        self.alwaysBounceVertical = false
        self.alwaysBounceHorizontal = false
        
        self.panGestureRecognizer.delegate = self
    }
    
    func layoutImageIfNeeded() {
        guard let media = self.mediaModel else {
            self.imageView.image = nil
            self.progressView.isShowError = true
            return
        }
        
        if let image = media.thumbnailImage {
            self.imageView.image = image
            self.displayImage(complete: true)
        }
        
        func loadLocalImage() {
            progressView.isShowError = false
            DispatchQueue.utility.async {
                do {
                    guard let photoURL = try media.mediaURL?.asURL() else {
                        throw LGMediaModelError.mediaURLIsInvalid
                    }
                    
                    let data = try Data(contentsOf: photoURL)
                    let image = LGImage.imageWith(data: data)
                    DispatchQueue.main.async {
                        self.imageView.image = image
                        self.displayImage(complete: true)
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.progressView.isShowError = true
                    }
                }
            }
        }
        
        func loadRemoteImage() {
            do {
                guard let photoURL = try media.mediaURL?.asURL() else {
                    throw LGMediaModelError.mediaURLIsInvalid
                }
                
                if let image = LGImageCache.default.getImage(forKey: photoURL.absoluteString,
                                                             withType: LGImageCacheType.memory) {
                    self.imageView.image = image
                    self.displayImage(complete: true)
                } else {
                    self.progressView.isHidden = false
                    imageView.lg_setImageWithURL(photoURL,
                                                 placeholder: media.thumbnailImage,
                                                 options: LGWebImageOptions.default,
                                                 progressBlock:
                        { [weak self] (progressModel) in
                            guard let weakSelf = self else {return}
                            weakSelf.progressView.progress = CGFloat(progressModel.fractionCompleted)
                    }, transformBlock: nil) { [weak self] (resultImage, _, _, imageStage, error) in
                        guard let weakSelf = self else {return}
                        guard error == nil, let image = resultImage else {
                            weakSelf.progressView.isShowError = true
                            return
                        }
                        weakSelf.mediaModel?.thumbnailImage = image
                        weakSelf.progressView.isHidden = imageStage == LGWebImageStage.finished
                        weakSelf.displayImage(complete: imageStage == LGWebImageStage.finished)
                    }
                }
            } catch {
                progressView.isShowError = true
            }
        }
        
        func loadImageFromAlbum() {
            guard let asset = self.mediaModel?.mediaAsset else {
                progressView.isShowError = true
                return
            }
            LGPhotoManager.requestImage(forAsset: asset,
                                        outputSize: CGSize(width: asset.pixelWidth,
                                                           height: asset.pixelHeight),
                                        resizeMode: .exact,
                                        progressHandlder: { (progress, error, stoped, infoDic) in
                                            self.progressView.progress = CGFloat(progress)
            }) { (resultImage, infoDic) in
                guard let resultImage = resultImage else {
                    self.progressView.isShowError = true
                    return
                }
                self.mediaModel?.thumbnailImage = resultImage
                self.progressView.isHidden = true
                self.displayImage(complete: true)
            }
        }
        
        switch media.mediaPosition {
        case .localFile:
            loadLocalImage()
            break
        case .remoteFile:
            loadRemoteImage()
            break
        case .album:
            loadImageFromAlbum()
            break
        }
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        let boundsSize = self.bounds.size
        var frameToCenter = imageView.frame
        
        // horizon
        if frameToCenter.size.width < boundsSize.width {
            frameToCenter.origin.x = floor((boundsSize.width - frameToCenter.size.width) / 2)
        } else {
            frameToCenter.origin.x = 0
        }
        // vertical
        if frameToCenter.size.height < boundsSize.height {
            frameToCenter.origin.y = floor((boundsSize.height - frameToCenter.size.height) / 2)
        } else {
            frameToCenter.origin.y = 0
        }
        
        // Center
        if !imageView.frame.equalTo(frameToCenter) {
            imageView.frame = frameToCenter
        }
        self.progressView.center = imageView.center
    }
    
    open func setMaxMinZoomScalesForCurrentBounds() {
        self.maximumZoomScale = 1
        self.minimumZoomScale = 1
        self.zoomScale = 1
        
        guard let imageView = self.imageView else {
            return
        }
        
        let boundsSize = bounds.size
        let imageSize = imageView.frame.size
        
        let xScale = boundsSize.width / imageSize.width
        let yScale = boundsSize.height / imageSize.height
        var minScale: CGFloat = min(xScale, yScale)
        var maxScale: CGFloat = 1.0
        
        let scale = max(UIScreen.main.scale, 1.5)
        // width in pixels. scale needs to remove if to use the old algorithm
        let deviceScreenWidth = UIScreen.main.bounds.width * scale
        // height in pixels. scale needs to remove if to use the old algorithm
        let deviceScreenHeight = UIScreen.main.bounds.height * scale
        
        if globalConfigs.longPhotoWidthMatchScreen && imageView.frame.height >= imageView.frame.width
        {
            minScale = 1.0
            maxScale = 1.5
        } else if imageView.frame.width < deviceScreenWidth {
            if UIApplication.shared.statusBarOrientation.isPortrait {
                maxScale = deviceScreenHeight / imageView.frame.width
            } else {
                maxScale = deviceScreenWidth / imageView.frame.width
            }
        } else if imageView.frame.width > deviceScreenWidth {
            maxScale = 1.0
        } else {
            maxScale = 1.5
        }
        
        self.maximumZoomScale = maxScale
        self.minimumZoomScale = minScale
        self.zoomScale = minScale
        
        // reset position
        self.imageView.frame.origin = CGPoint.zero
        setNeedsLayout()
    }
    
    open func prepareForReuse() {
        self.mediaModel = nil
    }
    
    // MARK: - image
    open func displayImage(complete flag: Bool) {
        guard let media = self.mediaModel else {
            return
        }
        // reset scale
        self.maximumZoomScale = 1
        self.minimumZoomScale = 1
        self.zoomScale = 1
        progressView.center = self.center
        if !flag {
            progressView.isHidden = false
        } else {
            progressView.isHidden = true
        }
        
        if let image = media.thumbnailImage {
            // image
            imageView.image = image
            
            var imageViewFrame: CGRect = .zero
            imageViewFrame.origin = .zero
            // long photo
            if globalConfigs.longPhotoWidthMatchScreen && image.size.height >= image.size.width
            {
                let imageHeight = LGMesurement.screenWidth / image.size.width * image.size.height
                imageViewFrame.size = CGSize(width: LGMesurement.screenWidth, height: imageHeight)
            } else {
                imageViewFrame.size = image.size
            }
            imageView.frame = imageViewFrame
            
            contentSize = imageViewFrame.size
            setMaxMinZoomScalesForCurrentBounds()
        }

        setNeedsLayout()
    }
    
    open func displayImageFailure() {
        progressView.isHidden = true
    }
    
    // MARK: - handle tap
    open func handleDoubleTap(_ touchPoint: CGPoint) {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        
        if zoomScale > minimumZoomScale {
            // zoom out
            setZoomScale(minimumZoomScale, animated: true)
        } else {
            let zoomRect = zoomRectForScrollViewWith(maximumZoomScale, touchPoint: touchPoint)
            zoom(to: zoomRect, animated: true)
        }
        
        postDoubleTapNotification()
    }
    
    @objc func postNotification() {
        NotificationCenter.default.post(name: kTapedScreenNotification, object: nil)
    }
    
    @objc func postDoubleTapNotification() {
        NotificationCenter.default.post(name: kNeedHideControlsNotification, object: nil)
    }
    
    deinit {
    }
}

extension LGZoomingScrollView: LGTapDetectingImageViewDelegate {
    public func singleTapDetected(_ touch: UITouch, targetView: UIImageView) {
        self.perform(#selector(postNotification), with: nil, afterDelay: 0.2)
    }
    
    public func doubleTapDetected(_ touch: UITouch, targetView: UIImageView) {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        let touchPoint = touch.location(in: targetView)
        handleDoubleTap(touchPoint)
    }
}

extension LGZoomingScrollView: UIScrollViewDelegate {
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }
    
    public func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        self.perform(#selector(postDoubleTapNotification), with: nil, afterDelay: 0.2)
    }
    
    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        self.setNeedsLayout()
        self.layoutIfNeeded()
    }
}

private extension LGZoomingScrollView {
    func getViewFramePercent(_ view: UIView, touch: UITouch) -> CGPoint {
        let oneWidthViewPercent = view.bounds.width / 100
        let viewTouchPoint = touch.location(in: view)
        let viewWidthTouch = viewTouchPoint.x
        let viewPercentTouch = viewWidthTouch / oneWidthViewPercent
        let photoWidth = imageView.bounds.width
        let onePhotoPercent = photoWidth / 100
        let needPoint = viewPercentTouch * onePhotoPercent
        
        var Y: CGFloat!
        
        if viewTouchPoint.y < view.bounds.height / 2 {
            Y = 0
        } else {
            Y = imageView.bounds.height
        }
        let allPoint = CGPoint(x: needPoint, y: Y)
        return allPoint
    }
    
    func zoomRectForScrollViewWith(_ scale: CGFloat, touchPoint: CGPoint) -> CGRect {
        let w = frame.size.width / scale
        let h = frame.size.height / scale
        let x = touchPoint.x - (h / max(UIScreen.main.scale, 2.0))
        let y = touchPoint.y - (w / max(UIScreen.main.scale, 2.0))
        
        return CGRect(x: x, y: y, width: w, height: h)
    }
}

extension LGZoomingScrollView: UIGestureRecognizerDelegate {
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                  shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool
    {
        if gestureRecognizer == self.panGestureRecognizer &&
            otherGestureRecognizer.lg_name == kPanDissmissGestureName &&
            self.contentOffset.y <= 0.0
        {
            return true
        }

        return false
    }
}

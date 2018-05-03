//
//  LGZoomingScrollView.swift
//  LGPhotoBrowser
//
//  Created by 龚杰洪 on 2018/4/24.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import UIKit
import AVKit

open class LGZoomingScrollView: UIScrollView {
//    var photo: LGPhotoProtocol? {
//        didSet {
//            layoutImageIfNeeded()
//        }
//    }
    
//    fileprivate weak var browser: LGPhotoBrowser?
    fileprivate(set) var imageView: LGTapDetectingImageView!
    fileprivate var tapView: LGTapDetectingView!
//    fileprivate var progressView: LGCircleProgressView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupDefault()
//        AVPlayerViewController
//        AVRoutePickerView
//        AVPictureInPictureController
    }
    
//    convenience init(frame: CGRect, browser: LGPhotoBrowser? = nil) {
//        self.init(frame: frame)
//        self.browser = browser
//    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupDefault()
    }
    
    func setupDefault() {
        
        // tap
        tapView = LGTapDetectingView(frame: self.bounds)
        tapView.detectingDelegate = self
        tapView.backgroundColor = .clear
        tapView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        addSubview(tapView)

        // image
        imageView = LGTapDetectingImageView(frame: self.bounds)
        imageView.detectingDelegate = self
        imageView.contentMode = .center
        imageView.backgroundColor = .clear
        addSubview(imageView)
        
//        progressView = LGCircleProgressView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
//        progressView.clockwise = true
//        progressView.trackWidth = 2.0
//        progressView.trackFillColor = UIColor.white
//        progressView.trackBackgroundColor = UIColor.gray.withAlphaComponent(0.3)
//        addSubview(progressView)
        
        self.backgroundColor = .clear
        self.delegate = self
        self.showsHorizontalScrollIndicator = false
        self.showsVerticalScrollIndicator = false
        self.decelerationRate = UIScrollViewDecelerationRateFast
        self.autoresizingMask = [.flexibleWidth,
                                 .flexibleTopMargin,
                                 .flexibleBottomMargin,
                                 .flexibleRightMargin,
                                 .flexibleLeftMargin]
        
        layoutImageIfNeeded()
    }
    
    func layoutImageIfNeeded() {
        self.imageView.image = UIImage(named: "IMG_0064.HEIC")
        self.displayImage(complete: true)
//        guard let photo = self.photo else {
//            self.imageView.image = nil
//            return
//        }
//        if let image = photo.underlyingImage {
//            self.imageView.image = image
//            self.displayImage(complete: true)
//        } else if photo.isVideo {
//
//        } else {
//            do {
//                let photoURL = try photo.photoURL.asURL()
//                if photoURL.isFileURL {
//                    DispatchQueue.utility.async {
//                        do {
//                            let data = try Data(contentsOf: photoURL)
//                            let image = LGImage.imageWith(data: data)
//                            DispatchQueue.main.async {
//                                self.imageView.image = image
//                                self.displayImage(complete: true)
//                            }
//                        } catch {
//
//                        }
//                    }
//                } else {
//                    self.progressView.isHidden = false
//                    imageView.lg_setImageWithURL(photoURL,
//                                                 placeholder: photo.underlyingImage,
//                                                 options: LGWebImageOptions.default,
//                                                 progressBlock:
//                        { (progress) in
//                        self.progressView.progress = progress.fractionCompleted
//                    }, transformBlock: nil) { (resultImage, _, _, imageStage, _) in
//                        self.photo?.underlyingImage = resultImage
//                        self.progressView.isHidden = imageStage == LGWebImageStage.finished
//                        self.displayImage(complete: imageStage == LGWebImageStage.finished)
//                    }
//                }
//            } catch {
//
//            }
//        }
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        self.tapView.frame = self.bounds
        
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
//        self.progressView.center = imageView.center
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
        
        let scale = max(UIScreen.main.scale, 2.0)
        // width in pixels. scale needs to remove if to use the old algorithm
        let deviceScreenWidth = UIScreen.main.bounds.width * scale
        // height in pixels. scale needs to remove if to use the old algorithm
        let deviceScreenHeight = UIScreen.main.bounds.height * scale
        
        minScale = 1.0
        maxScale = 2.0
//        if LGPhotoBrowserOptions.current.contains(.longPhotoWidthMatchScreen) &&
//            imageView.frame.height >= imageView.frame.width
//        {
//            minScale = 1.0
//            maxScale = 2.0
//        } else
    if imageView.frame.width < deviceScreenWidth {
            if UIApplication.shared.statusBarOrientation.isPortrait {
                maxScale = deviceScreenHeight / imageView.frame.width
            } else {
                maxScale = deviceScreenWidth / imageView.frame.width
            }
        } else if imageView.frame.width > deviceScreenWidth {
            maxScale = 1.0
        } else {
            maxScale = 2.0
        }
    
        self.maximumZoomScale = maxScale
        self.minimumZoomScale = minScale
        self.zoomScale = minScale
        
        // reset position
        self.imageView.frame.origin = CGPoint.zero
        setNeedsLayout()
    }
    
    open func prepareForReuse() {
//        photo = nil
    }
    
    // MARK: - image
    open func displayImage(complete flag: Bool) {
//        guard let photo = self.photo else {
//            return
//        }
        // reset scale
        self.maximumZoomScale = 1
        self.minimumZoomScale = 1
        self.zoomScale = 1
//        progressView.center = self.center
//        if !flag {
//            if photo.underlyingImage == nil {
//                progressView.isHidden = true
//            }
//            photo.loadUnderlyingImageAndNotify()
//        } else {
//            progressView.isHidden = true
//        }
//
        if let image = self.imageView.image {
            // image
            imageView.image = image
            imageView.contentMode = UIViewContentMode.scaleAspectFill
            
            var imageViewFrame: CGRect = .zero
            imageViewFrame.origin = .zero
//            // long photo
            if
                image.size.height >= image.size.width
            {
                let imageHeight = UIScreen.main.bounds.size.width / image.size.width * image.size.height
                imageViewFrame.size = CGSize(width: UIScreen.main.bounds.size.width, height: imageHeight)
            } else {
                imageViewFrame.size = image.size
            }
            imageView.frame = imageViewFrame
            
            contentSize = imageViewFrame.size
            setMaxMinZoomScalesForCurrentBounds()
        } else {
            // change contentSize will reset contentOffset, so only set the contentsize zero when the image is nil
            contentSize = CGSize.zero
        }
        setNeedsLayout()
    }
    
    open func displayImageFailure() {
//        progressView.isHidden = true
    }
    
    // MARK: - handle tap
    open func handleDoubleTap(_ touchPoint: CGPoint) {
//        if let browser = browser {
//            NSObject.cancelPreviousPerformRequests(withTarget: browser)
//        }
        
        if zoomScale > minimumZoomScale {
            // zoom out
            setZoomScale(minimumZoomScale, animated: true)
        } else {
            // zoom in
            // I think that the result should be the same after double touch or pinch
            /* var newZoom: CGFloat = zoomScale * 3.13
             if newZoom >= maximumZoomScale {
             newZoom = maximumZoomScale
             }
             */
            let zoomRect = zoomRectForScrollViewWith(maximumZoomScale, touchPoint: touchPoint)
            zoom(to: zoomRect, animated: true)
        }
        
        // delay control
//        browser?.hideControlsAfterDelay()
    }
    
    deinit {
//        browser = nil
    }
}

extension LGZoomingScrollView: LGTapDetectingImageViewDelegate {
    public func singleTapDetected(_ touch: UITouch, targetView: UIImageView) {
//        guard let browser = browser else {
//            return
//        }
//
//        if browser.status == LGPhotoBrowserStatus.browsing {
//            browser.perform(#selector(LGPhotoBrowser.determineAndClose),
//                            with: nil,
//                            afterDelay: 0.2)
//        } else {
//            browser.perform(#selector(LGPhotoBrowser.toggleControls),
//                            with: nil,
//                            afterDelay: 0.2)
//        }
    }
//
    public func doubleTapDetected(_ touch: UITouch, targetView: UIImageView) {
//        if let browser = self.browser {
//            NSObject.cancelPreviousPerformRequests(withTarget: browser)
//        }
//        let touchPoint = touch.location(in: targetView)
//        handleDoubleTap(touchPoint)
    }
}

extension LGZoomingScrollView: LGTapDetectingViewDelegate {
    public func singleTapDetected(_ touch: UITouch, targetView: UIView) {
//        guard let browser = browser else {
//            return
//        }
//        guard LGPhotoBrowserOptions.current.contains(.enableZoomBlackArea) else {
//            return
//        }
//
//        if browser.areControlsHidden() == false && browser.status == LGPhotoBrowserStatus.browsing {
//            browser.perform(#selector(LGPhotoBrowser.determineAndClose),
//                            with: nil,
//                            afterDelay: 0.2)
//        } else {
//            browser.perform(#selector(LGPhotoBrowser.toggleControls),
//                            with: nil,
//                            afterDelay: 0.2)
//        }
    }

    public func doubleTapDetected(_ touch: UITouch, targetView: UIView) {
//        if let browser = self.browser {
//            NSObject.cancelPreviousPerformRequests(withTarget: browser)
//        }
//        if LGPhotoBrowserOptions.current.contains(.enableZoomBlackArea) {
//            let needPoint = getViewFramePercent(targetView, touch: touch)
//            handleDoubleTap(needPoint)
//        }
    }
}

extension LGZoomingScrollView: UIScrollViewDelegate {
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }
    
    public func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
//        browser?.cancelControlHiding()
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

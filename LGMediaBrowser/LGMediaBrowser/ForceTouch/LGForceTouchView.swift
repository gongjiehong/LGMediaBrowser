//
//  LGForceTouchView.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/8/2.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import UIKit

class LGForceTouchView: UIView {

    var preferredContentSize = CGSize.zero
    
    lazy var targePreviewPadding: CGSize = {
        return CGSize(width: 28.0, height: UIScreen.main.bounds.height - preferredContentSize.height)
    }()

    
    var sourceViewCenter = CGPoint.zero
    var sourceToCenterXDelta: CGFloat = 0.0
    var sourceToCenterYDelta: CGFloat = 0.0
    var sourceToTargetWidthDelta: CGFloat = 0.0
    var sourceToTargetHeightDelta: CGFloat = 0.0
    
    var viewControllerScreenshot: UIImage? = nil {
        didSet {
            blurredScreenshots.removeAll()
        }
    }
    var targetViewControllerScreenshot: UIImage? = nil
    var sourceViewScreenshot: UIImage?
    var blurredScreenshots = [UIImage]()
    
    var sourceViewRect = CGRect.zero
    
    var blurredBaseImageView = UIImageView()
    var blurredImageViewFirst = UIImageView()
    var blurredImageViewSecond = UIImageView()
    
    lazy var overlayView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.85, alpha: 0.5)
        return view
    }()
    
    var sourceImageView = UIImageView()
    
    var targetPreviewView = LGForceTouchTargetPreviewView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func setup() {
        self.addSubview(blurredBaseImageView)
        self.addSubview(blurredImageViewFirst)
        self.addSubview(blurredImageViewSecond)
        self.addSubview(overlayView)
        self.addSubview(sourceImageView)
        self.addSubview(targetPreviewView)
    }
    
    func didAppear() {
        blurredBaseImageView.frame = self.bounds
        blurredImageViewFirst.frame = self.bounds
        blurredImageViewSecond.frame = self.bounds
        overlayView.frame = self.bounds
        
        targetPreviewView.frame.size = sourceViewRect.size
        targetPreviewView.imageViewFrame = self.bounds
        targetPreviewView.imageView.image = targetViewControllerScreenshot
        
        sourceImageView.frame = sourceViewRect
        sourceImageView.image = sourceViewScreenshot
        
        sourceViewCenter = CGPoint(x: sourceViewRect.origin.x + sourceViewRect.size.width/2, y: sourceViewRect.origin.y + sourceViewRect.size.height/2)
        sourceToCenterXDelta = self.bounds.size.width/2 - sourceViewCenter.x
        sourceToCenterYDelta = self.bounds.size.height/2 - sourceViewCenter.y
        sourceToTargetWidthDelta = self.bounds.size.width - targePreviewPadding.width - sourceViewRect.size.width
        sourceToTargetHeightDelta = self.bounds.size.height - targePreviewPadding.height - sourceViewRect.size.height
        
    }
    
    func animateProgressiveBlur(_ progress: CGFloat) {
        if blurredScreenshots.count > 2 {
            let blur = progress*CGFloat(blurredScreenshots.count - 1)
            let blurIndex = Int(blur)
            let blurRemainder = blur - CGFloat(blurIndex)
            blurredBaseImageView.image = blurredScreenshots.last
            blurredImageViewFirst.image = blurredScreenshots[blurIndex]
            blurredImageViewSecond.image = blurredScreenshots[blurIndex + 1]
            blurredImageViewSecond.alpha = CGFloat(blurRemainder)
        }
    }
    
    func animateProgress(_ progress: CGFloat) {
        
        sourceImageView.isHidden = progress > 0.33
        targetPreviewView.isHidden = progress < 0.33
        
        // Source rect expand stage
        if progress < 0.33 {
            let adjustedProgress = min(progress*3,1.0)
            animateProgressiveBlur(adjustedProgress)
            let adjustedScale: CGFloat = 1.0 - CGFloat(adjustedProgress)*0.015
            let adjustedSourceImageScale: CGFloat = 1.0 + CGFloat(adjustedProgress)*0.015
            blurredImageViewFirst.transform = CGAffineTransform(scaleX: adjustedScale, y: adjustedScale)
            blurredImageViewSecond.transform = CGAffineTransform(scaleX: adjustedScale, y: adjustedScale)
            overlayView.alpha = CGFloat(adjustedProgress)
            sourceImageView.transform = CGAffineTransform(scaleX: adjustedSourceImageScale, y: adjustedSourceImageScale)
        }
            // Target preview reveal stage
        else if progress < 0.45 {
            let targetAdjustedScale: CGFloat = min(CGFloat((progress - 0.33)/0.1), CGFloat(1.0))
            targetPreviewView.frame.size = CGSize(width: sourceViewRect.size.width + sourceToTargetWidthDelta*targetAdjustedScale, height: sourceViewRect.size.height + sourceToTargetHeightDelta*targetAdjustedScale)
            targetPreviewView.center = CGPoint(x: sourceViewCenter.x + sourceToCenterXDelta*targetAdjustedScale, y: sourceViewCenter.y + sourceToCenterYDelta*targetAdjustedScale)
        }
            // Target preview expand stage
        else if progress < 0.96 {
            let targetAdjustedScale = min(CGFloat(1 + (progress-0.66)/6),1.1)
            targetPreviewView.transform = CGAffineTransform(scaleX: targetAdjustedScale, y: targetAdjustedScale)
        }
            // Commit target view controller
        else {
            targetPreviewView.frame = self.bounds
            targetPreviewView.imageContainer.layer.cornerRadius = 0
        }
        
    }
}

/// <#Description#>
class LGForceTouchTargetPreviewView: UIView {
    var imageContainer = UIImageView()
    var imageView = UIImageView()
    var imageViewFrame = CGRect.zero
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageContainer.frame = self.bounds
        imageView.frame = imageViewFrame
        imageView.contentMode = UIView.ContentMode.scaleAspectFit
        imageView.center = CGPoint(x: self.lg_width / 2.0, y: self.lg_height / 2.0)
    }
    
    func setup() {
        self.addSubview(imageContainer)
        imageContainer.layer.cornerRadius = 15.0
        imageContainer.clipsToBounds = true
        imageContainer.addSubview(imageView)
    }
}

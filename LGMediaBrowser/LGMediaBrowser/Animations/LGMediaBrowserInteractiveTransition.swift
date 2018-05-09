//
//  LGMediaBrowserInteractiveTransition.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/5/9.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import UIKit

public class LGMediaBrowserInteractiveTransition: UIPercentDrivenInteractiveTransition {
    public var interation: Bool = false
    private weak var targetController: UIViewController?
    private weak var transitionContext: UIViewControllerContextTransitioning?
    
    private weak var fromTargetView: UIView?
    private weak var toTargetView: UIView?
    
    public func addPanGestureFor(viewController: UIViewController) {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        viewController.view.addGestureRecognizer(pan)
        self.targetController = viewController
    }
    
    @objc func handlePanGesture(_ sender: UIPanGestureRecognizer) {
        guard let gestureView = sender.view else {
            return
        }
        var scale: CGFloat = 0.0
        
        let translation = sender.translation(in: gestureView)
        let transitionY = translation.y
        scale = transitionY / ((gestureView.lg_height - 50.0) / 2.0)
        
        if scale > 1.0 {
            scale = 1.0
        }
        
        switch sender.state {
        case .began:
            if scale < 0 {
                return
            }
            self.targetController?.dismiss(animated: true, completion: nil)
            break
        case .changed:
            break
        case .ended:
            break
        default:
            break
        }
        
//        switch (gestureRecognizer.state) {
//        case UIGestureRecognizerStateBegan:
//            if (scale < 0) {
//                [gestureRecognizer cancelsTouchesInView];
//                return;
//            }
//            if (![(HXDatePhotoPreviewViewController *)self.vc bottomView].userInteractionEnabled && iOS11_Later) {
//                [(HXDatePhotoPreviewViewController *)self.vc setSubviewAlphaAnimate:NO];
//            }
//            [(HXDatePhotoPreviewViewController *)self.vc setStopCancel:YES];
//            self.beginX = [gestureRecognizer locationInView:gestureRecognizer.view].x;
//            self.beginY = [gestureRecognizer locationInView:gestureRecognizer.view].y;
//            self.interation = YES;
//            [self.vc.navigationController popViewControllerAnimated:YES];
//            break;
//        case UIGestureRecognizerStateChanged:
//            if (self.interation) {
//                if (scale < 0.f) {
//                    scale = 0.f;
//                }
//                CGFloat imageViewScale = 1 - scale * 0.5;
//                if (imageViewScale < 0.4) {
//                    imageViewScale = 0.4;
//                }
//                self.tempImageView.center = CGPointMake(self.transitionImgViewCenter.x + translation.x, self.transitionImgViewCenter.y + translation.y);
//                self.tempImageView.transform = CGAffineTransformMakeScale(imageViewScale, imageViewScale);
//
//                [self updateInterPercent:1 - scale * scale];
//
//                [self updateInteractiveTransition:scale];
//            }
//            break;
//        case UIGestureRecognizerStateEnded:
//            if (self.interation) {
//                if (scale < 0.f) {
//                    scale = 0.f;
//                }
//                self.interation = NO;
//                if (scale < 0.15f){
//                    [self cancelInteractiveTransition];
//                    [self interPercentCancel];
//                }else {
//                    [self finishInteractiveTransition];
//                    [self interPercentFinish];
//                }
//            }
//            break;
//        default:
//            if (self.interation) {
//                self.interation = NO;
//                [self cancelInteractiveTransition];
//                [self interPercentCancel];
//            }
//            break;
//        }
    }
    
    func beginInteractivePercent() {
        
    }
    
    func updateInteractivePercent(_ scale: CGFloat) {
        
    }
    
    func interactivePercentCancel() {
        
    }
    
    func interactivePercentFinished() {
        
    }
    
    public override func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        self.transitionContext = transitionContext
        self.beginInteractivePercent()
    }
}

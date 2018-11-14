//
//  LGForceTouchManager.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/8/2.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import Foundation

class LGForceTouchManager {
    var forceTouch: LGForceTouch!
    
    var viewController: UIViewController {
        return forceTouch.viewController ?? UIViewController()
    }
    
    var targetViewController: UIViewController?
    
    var forceTouchView: LGForceTouchView?
    
    lazy var forceTouchWindow: UIWindow = {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.windowLevel = UIWindow.Level.alert
        window.rootViewController = UIViewController()
        return window
    }()
    
    init(forceTouch: LGForceTouch) {
        self.forceTouch = forceTouch
    }
    
    func forceTouchPossible(_ context: LGForceTouchPreviewingContext, touchLocation: CGPoint) -> Bool {
        
        guard let targetVC = context.delegate?.previewingContext(context,
                                                                 viewControllerForLocation: touchLocation) else
        {
            return false
        }
        
        let temp = LGForceTouchView()
        forceTouchView = temp
        
        if let viewControllerScreenshot = viewController.view.window?.screenShot() {
            forceTouchView?.viewControllerScreenshot = viewControllerScreenshot
            forceTouchView?.blurredScreenshots = self.generateBlurredScreenshots(viewControllerScreenshot)
        }
        
        let rect = viewController.view.convert(context.sourceRect, from: context.sourceView)
        forceTouchView?.sourceViewScreenshot = viewController.view.screenShot(inHierarchy: true, rect: rect)
        forceTouchView?.sourceViewRect = viewController.view.convert(rect, to: nil)
        
        targetVC.view.frame = viewController.view.bounds
        forceTouchView?.targetViewControllerScreenshot = targetVC.view.screenShot(inHierarchy: false)
        forceTouchView?.preferredContentSize = targetVC.preferredContentSize
        targetViewController = targetVC
        
        return true
    }
    
    func generateBlurredScreenshots(_ image: UIImage) -> [UIImage] {
        var images = [UIImage]()
        images.append(image)
        for i in 1...3 {
            let radius: CGFloat = CGFloat(Double(i) * 8.0 / 3.0)
            if let blurredScreenshot = blurImageWithRadius(image, radius: radius) {
                images.append(blurredScreenshot)
            }
        }
        return images
    }
    
    func blurImageWithRadius(_ image: UIImage, radius: CGFloat) -> UIImage? {
        return image.lg_imageByBlurRadius(radius,
                                          tintColor: nil,
                                          tintBlendMode: CGBlendMode.normal,
                                          saturation: 1.0,
                                          maskImage: nil)
    }
    
    
    func forceTouchBegan() {
        forceTouchWindow.alpha = 0.0
        forceTouchWindow.isHidden = false
        forceTouchWindow.makeKeyAndVisible()
        
        if let forceTouchView = forceTouchView {
            forceTouchWindow.addSubview(forceTouchView)
        }
        
        forceTouchView?.frame = UIScreen.main.bounds
        forceTouchView?.didAppear()
        
        UIView.animate(withDuration: 0.2, animations: { () -> Void in
            self.forceTouchWindow.alpha = 1.0
        })
    }
    

    func animateProgressForContext(_ progress: CGFloat, context: LGForceTouchPreviewingContext?) {
        (progress < 0.99) ? forceTouchView?.animateProgress(progress) : commitTarget(context)
    }
    

    func commitTarget(_ context: LGForceTouchPreviewingContext?){
        guard let targetViewController = targetViewController, let context = context else {
            return
        }
        context.delegate?.previewingContext(context, commitViewController: targetViewController)
        forceTouchEnded()
    }
    

    func forceTouchEnded() {
        UIView.animate(withDuration: 0.2, animations: { () -> Void in
            self.forceTouchWindow.alpha = 0.0
        }, completion: { (finished) -> Void in
            self.forceTouch.forceTouchGestureRecognizer?.resetValues()
            self.forceTouchWindow.isHidden = true
            self.forceTouchView?.removeFromSuperview()
            self.forceTouchView = nil
        })
    }
}

//
//  LGNavigationController.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/6/1.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import UIKit

open class LGMPNavigationController: UINavigationController {
    
    open override var title: String? {
        didSet {
            if let titleLabel = self.navigationItem.titleView as? UILabel {
                titleLabel.text = title
                titleLabel.sizeToFit()
            }
        }
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        
        self.interactivePopGestureRecognizer?.delegate = self
        self.view.layer.masksToBounds = true
        
        let titleLabel = UILabel(frame: CGRect.zero)
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18.0)
        titleLabel.textColor = UIColor(colorName: "NavigationBarTitle")
        titleLabel.backgroundColor = UIColor.clear
        self.navigationItem.titleView = titleLabel
    }
    
    open override var preferredStatusBarStyle: UIStatusBarStyle {
        if let stype = self.topViewController?.preferredStatusBarStyle {
            return stype
        } else {
            return UIStatusBarStyle.lightContent
        }
    }
    
    open override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        if viewControllers.count > 0 {
            viewController.hidesBottomBarWhenPushed = true
        }
        super.pushViewController(viewController, animated: animated)
    }
    
    open override func setViewControllers(_ viewControllers: [UIViewController], animated: Bool) {
        if viewControllers.count > 0 {
            viewControllers.last!.hidesBottomBarWhenPushed = true
        }
        super.setViewControllers(viewControllers, animated: true)
    }

    open override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension LGMPNavigationController: UIGestureRecognizerDelegate {
    
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        
        // Ignore interactive pop gesture when there is only one view controller on the navigation stack
        if viewControllers.count <= 1 || (viewControllers.last?.lg_interactivePopDisabled == true) {
            return false
        }
        return true
    }
}

extension UIViewController {
    private struct AssociatedKeys {
        static var popDisabled = "lg_interactivePopDisabled"
    }

    public var lg_interactivePopDisabled: Bool {
        set {
            objc_setAssociatedObject(self,
                                     &AssociatedKeys.popDisabled,
                                     NSNumber(booleanLiteral: newValue),
                                     objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            guard let number = objc_getAssociatedObject(self, &AssociatedKeys.popDisabled) as? NSNumber else {
                return false
            }
            
            return number.boolValue
        }
    }
}

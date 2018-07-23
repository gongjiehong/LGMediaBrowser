//
//  LGButtons.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/4/25.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import Foundation

internal class LGButton: UIButton {
    internal var showFrame: CGRect!
    internal var hideFrame: CGRect!
    
    fileprivate var insets: UIEdgeInsets {
        if UI_USER_INTERFACE_IDIOM() == .phone {
            return UIEdgeInsets(top: 15.25, left: 15.25, bottom: 15.25, right: 15.25)
        } else {
            return UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        }
    }
    fileprivate let size: CGSize = CGSize(width: 44, height: 44)
    fileprivate var marginX: CGFloat = 0
    fileprivate var marginY: CGFloat = 0
    fileprivate var extraMarginY: CGFloat = LGMesurement.isPhoneX ? 10 : 0
    
    func setup(_ imageName: String) {
        self.backgroundColor = .clear
        self.imageEdgeInsets = insets
        self.translatesAutoresizingMaskIntoConstraints = true
        self.autoresizingMask = [.flexibleBottomMargin,
                                 .flexibleLeftMargin,
                                 .flexibleRightMargin,
                                 .flexibleTopMargin]
        
        let image = UIImage(named: imageName,
                            in: Bundle(for: LGButton.self),
                            compatibleWith: nil) ?? UIImage()
        self.setImage(image, for: UIControl.State())
    }
    
    open func setFrameSize(_ size: CGSize? = nil) {
        guard let size = size else { return }
        
        let newRect = CGRect(x: marginX, y: marginY, width: size.width, height: size.height)
        frame = newRect
        showFrame = newRect
        hideFrame = CGRect(x: marginX, y: -marginY, width: size.width, height: size.height)
    }
    
    open func updateFrame(_ frameSize: CGSize) { }
}

internal class LGImageButton: LGButton {
    open var imageName: String {
        return ""
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup(imageName)
        showFrame = CGRect(x: marginX, y: marginY, width: size.width, height: size.height)
        hideFrame = CGRect(x: marginX, y: -marginY, width: size.width, height: size.height)
    }
}

class LGCloseButton: LGImageButton {
    override var imageName: String { return "btn_close_white" }
    override var marginX: CGFloat {
        get {
            let swapCloseAndDeleteButtons = globalConfigs.swapCloseAndDeleteButtons
            var result: CGFloat
            if swapCloseAndDeleteButtons {
                result = LGMesurement.screenWidth - LGButtonOptions.closeButtonPadding.x - self.size.width
            } else {
                result = LGButtonOptions.closeButtonPadding.x
            }
            return result
        }
        set { super.marginX = newValue }
    }
    override var marginY: CGFloat {
        get { return LGButtonOptions.closeButtonPadding.y + extraMarginY }
        set { super.marginY = newValue }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup(imageName)
        showFrame = CGRect(x: marginX, y: marginY, width: size.width, height: size.height)
        hideFrame = CGRect(x: marginX, y: -marginY, width: size.width, height: size.height)
    }
}

class LGDeleteButton: LGImageButton {
    override var imageName: String { return "btn_delete_white" }
    override var marginX: CGFloat {
        get {
            let swapCloseAndDeleteButtons = globalConfigs.swapCloseAndDeleteButtons
            var result: CGFloat
            if swapCloseAndDeleteButtons {
                result = LGButtonOptions.deleteButtonPadding.x
            } else {
                result = LGMesurement.screenWidth - LGButtonOptions.deleteButtonPadding.x - self.size.width
            }
            return result
        }
        set { super.marginX = newValue }
    }
    override var marginY: CGFloat {
        get { return LGButtonOptions.deleteButtonPadding.y + extraMarginY }
        set { super.marginY = newValue }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup(imageName)
        showFrame = CGRect(x: marginX, y: marginY, width: size.width, height: size.height)
        hideFrame = CGRect(x: marginX, y: -marginY, width: size.width, height: size.height)
    }
}


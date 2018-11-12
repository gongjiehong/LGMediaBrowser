//
//  LGActionView.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/4/25.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import Foundation

protocol LGActionViewDelegate: NSObjectProtocol {
    func closeButtonPressed()
    func deleteButtonPressed()
}

class LGActionView: UIView {
    internal var closeButton: LGCloseButton!
    internal var titleLabel: UILabel!
    internal var deleteButton: LGDeleteButton!
    
    weak var delegate: LGActionViewDelegate?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureCloseButton()
        configureDeleteButton()
        configureTitleLabel()
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if let view = super.hitTest(point, with: event) {
            if closeButton.frame.contains(point) || deleteButton.frame.contains(point) {
                return view
            }
            return nil
        }
        return nil
    }
    
    func updateFrame(frame: CGRect) {
        self.frame = frame
        self.setNeedsDisplay()
    }
    
    func updateCloseButton(image: UIImage, size: CGSize? = nil) {
        configureCloseButton(image: image, size: size)
    }
    
    func updateDeleteButton(image: UIImage, size: CGSize? = nil) {
        configureDeleteButton(image: image, size: size)
    }
    
    func animate(hidden: Bool) {
        let closeFrame: CGRect = hidden ? closeButton.hideFrame : closeButton.showFrame
        let deleteFrame: CGRect = hidden ? deleteButton.hideFrame : deleteButton.showFrame
        let titleFrame: CGRect = hidden ? titleLabelHideFrame : titleLabelShowFrame
        
        let closeButtonHidden = !globalConfigs.showsCloseButton
        let deleteButtonHidden = !globalConfigs.showsDeleteButton
        let titleLabelHidden = hidden
        if hidden == false {
            self.closeButton.isHidden = closeButtonHidden
            self.deleteButton.isHidden = deleteButtonHidden
            self.titleLabel.isHidden = titleLabelHidden
        }
        UIView.animate(withDuration: 0.35,
                       animations: {
                        let alpha: CGFloat = hidden ? 0.0 : 1.0
                        self.closeButton.alpha = alpha
                        self.closeButton.frame = closeFrame
                        self.deleteButton.alpha = alpha
                        self.deleteButton.frame = deleteFrame
                        self.titleLabel.alpha = alpha
                        self.titleLabel.frame = titleFrame
                        
        }) { (finished) in
            if finished {
                if !hidden {
                    self.closeButton.isHidden = closeButtonHidden
                    self.deleteButton.isHidden = deleteButtonHidden
                    self.titleLabel.isHidden = titleLabelHidden
                }
            }
        }
    }
    
    @objc func closeButtonPressed(_ sender: UIButton) {
        delegate?.closeButtonPressed()
    }
    
    @objc func deleteButtonPressed(_ sender: UIButton) {
        delegate?.deleteButtonPressed()
    }
}

extension LGActionView {
    func configureCloseButton(image: UIImage? = nil, size: CGSize? = nil) {
        if closeButton == nil {
            closeButton = LGCloseButton(frame: .zero)
            closeButton.addTarget(self, action: #selector(closeButtonPressed(_:)), for: .touchUpInside)
            closeButton.isHidden = !globalConfigs.showsCloseButton
            addSubview(closeButton)
        }
        
        guard let size = size else { return }
        closeButton.setFrameSize(size)
        
        guard let image = image else { return }
        closeButton.setImage(image, for: UIControl.State())
    }
    
    func configureDeleteButton(image: UIImage? = nil, size: CGSize? = nil) {
        if deleteButton == nil {
            deleteButton = LGDeleteButton(frame: .zero)
            deleteButton.addTarget(self, action: #selector(deleteButtonPressed(_:)), for: .touchUpInside)
            deleteButton.isHidden = !globalConfigs.showsDeleteButton
            addSubview(deleteButton)
        }
        
        guard let size = size else { return }
        deleteButton.setFrameSize(size)
        
        guard let image = image else { return }
        deleteButton.setImage(image, for: UIControl.State())
    }
    
    func configureTitleLabel() {
        if titleLabel == nil {
            titleLabel = UILabel(frame: titleLabelHideFrame)
            titleLabel.textColor = UIColor(colorName: "ActionBarTitle")
            titleLabel.backgroundColor = UIColor.clear
            titleLabel.font = UIFont.systemFont(ofSize: 16.0, weight: UIFont.Weight.medium)
            titleLabel.isHidden = true
            self.addSubview(titleLabel)
        }
    }
    
    var titleLabelShowFrame: CGRect {
        let titleLabelWidth: CGFloat = self.lg_width - 80.0
        let titleLabelHeight: CGFloat = 30.0
        let topSafeMargin = UIDevice.topSafeMargin
        let statusBarHeight = UIDevice.statusBarHeight
        let titleLabelOriginY =
            topSafeMargin + statusBarHeight +
                (self.lg_height - topSafeMargin - titleLabelHeight - statusBarHeight) / 2.0
        return CGRect(x: titleLabelWidth / 2.0,
                      y: titleLabelOriginY,
                      width: titleLabelWidth,
                      height: titleLabelHeight)
    }

    var titleLabelHideFrame: CGRect {
        let frame = titleLabelShowFrame
        return CGRect(x: frame.origin.x, y: -frame.origin.y, width: frame.width, height: frame.height)
    }
}

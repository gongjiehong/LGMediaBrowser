//
//  LGActionView.swift
//  LGPhotoBrowser
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
    internal var deleteButton: LGDeleteButton!
    
    weak var delegate: LGActionViewDelegate?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureCloseButton()
        configureDeleteButton()
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
        
        let closeBtnHidden = !globalConfigs.displayCloseButton
        let deleteBtnHidden = !globalConfigs.displayDeleteButton
        
        if hidden == false {
            self.closeButton.isHidden = closeBtnHidden
            self.deleteButton.isHidden = deleteBtnHidden
        }
        UIView.animate(withDuration: 0.35,
                       animations: {
                        let alpha: CGFloat = hidden ? 0.0 : 1.0
                        self.closeButton.alpha = alpha
                        self.closeButton.frame = closeFrame
                        self.deleteButton.alpha = alpha
                        self.deleteButton.frame = deleteFrame
        }) { (finished) in
            if finished {
                if !hidden {
                    self.closeButton.isHidden = closeBtnHidden
                    self.deleteButton.isHidden = deleteBtnHidden
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
            closeButton.isHidden = !globalConfigs.displayCloseButton
            addSubview(closeButton)
        }
        
        guard let size = size else { return }
        closeButton.setFrameSize(size)
        
        guard let image = image else { return }
        closeButton.setImage(image, for: UIControlState())
    }
    
    func configureDeleteButton(image: UIImage? = nil, size: CGSize? = nil) {
        if deleteButton == nil {
            deleteButton = LGDeleteButton(frame: .zero)
            deleteButton.addTarget(self, action: #selector(deleteButtonPressed(_:)), for: .touchUpInside)
            deleteButton.isHidden = !globalConfigs.displayDeleteButton
            addSubview(deleteButton)
        }
        
        guard let size = size else { return }
        deleteButton.setFrameSize(size)
        
        guard let image = image else { return }
        deleteButton.setImage(image, for: UIControlState())
    }
}

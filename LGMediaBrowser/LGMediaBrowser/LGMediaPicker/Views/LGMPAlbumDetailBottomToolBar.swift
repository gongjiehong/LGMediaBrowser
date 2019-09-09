//
//  LGMPAlbumDetailBottomToolBar.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/11/6.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import UIKit

internal protocol LGMPAlbumDetailBottomToolBarDelegate: UIToolbarDelegate {
    func previewButtonPressed(_ button: UIButton)
    func originalButtonPressed(_ button: UIButton)
    func doneButtonPressed(_ button: UIButton)
}

internal class LGMPAlbumDetailBottomToolBar: UIToolbar {
    
    internal var allowSelectOriginal: Bool = true
    
    internal weak var barDelegate: LGMPAlbumDetailBottomToolBarDelegate?
    
    internal lazy var previewButton: UIButton = {
        let temp = UIButton(type: UIButton.ButtonType.custom)
        temp.titleLabel?.font = UIFont.systemFont(ofSize: 15.0)
        temp.setTitle(LGLocalizedString("Preview"), for: UIControl.State.normal)
        temp.addTarget(self, action: #selector(previewButtonPressed(_:)), for: UIControl.Event.touchUpInside)
        temp.setTitleColor(UIColor(named: "BottomBarDisableText", in: Bundle.this, compatibleWith: nil), for: UIControl.State.disabled)
        temp.setTitleColor(UIColor(named: "BottomBarNormalText", in: Bundle.this, compatibleWith: nil), for: UIControl.State.normal)
        temp.isEnabled = false
        
        let bottonButtonsHeight: CGFloat = 30.0
        let previewTitleWidth = LGLocalizedString("Preview").width(withConstrainedHeight: 20.0,
                                                                   font: UIFont.systemFont(ofSize: 15.0))
        temp.frame = CGRect(x: 0,
                            y: 0,
                            width: previewTitleWidth,
                            height: bottonButtonsHeight)
        
        return temp
    }()
    
    internal lazy var originalPhotoButton: UIButton = {
        let temp = UIButton(type: UIButton.ButtonType.custom)
        temp.titleLabel?.font = UIFont.systemFont(ofSize: 15.0)
        temp.setTitle(LGLocalizedString("Original"), for: UIControl.State.normal)
        temp.setImage(UIImage(namedFromThisBundle: "button_original_normal"), for: UIControl.State.normal)
        temp.setImage(UIImage(namedFromThisBundle: "button_original_selected"), for: UIControl.State.selected)
        temp.setTitleColor(UIColor(named: "BottomBarDisableText", in: Bundle.this, compatibleWith: nil), for: UIControl.State.disabled)
        temp.setTitleColor(UIColor(named: "BottomBarNormalText", in: Bundle.this, compatibleWith: nil), for: UIControl.State.normal)
        temp.addTarget(self, action: #selector(originalButtonPressed(_:)), for: UIControl.Event.touchUpInside)
        temp.isEnabled = false
        
        let bottonButtonsHeight: CGFloat = 30.0
        let originalTitleWidth = LGLocalizedString("Original").width(withConstrainedHeight: 20.0,
                                                                     font: UIFont.systemFont(ofSize: 15.0)) + 20.0
        temp.frame = CGRect(x: 0,
                            y: 0,
                            width: originalTitleWidth + 10.0,
                            height: bottonButtonsHeight)
        
        return temp
    }()
    
    internal lazy var photoBytesIndicatorView: UIActivityIndicatorView = {
        let temp = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.gray)
        temp.frame = CGRect(x: 0, y: 0, width: 60.0, height: 30.0)
        temp.hidesWhenStopped = true
        temp.stopAnimating()
        return temp
    }()
    
    internal lazy var photoBytesLabel: UILabel = {
        let temp = UILabel(frame: CGRect(x: 0, y: 0, width: 80.0, height: 30.0))
        temp.font = UIFont.systemFont(ofSize: 15.0)
        temp.textColor = UIColor(named: "BottomBarNormalText", in: Bundle.this, compatibleWith: nil)
        return temp
    }()
    
    internal lazy var doneButton: UIButton = {
        let temp = UIButton(type: UIButton.ButtonType.custom)
        temp.titleLabel?.font = UIFont.systemFont(ofSize: 15.0)
        temp.setTitleColor(UIColor.white, for: UIControl.State.normal)
        temp.setTitleColor(UIColor.white.withAlphaComponent(0.6), for: UIControl.State.disabled)
        temp.setTitle(LGLocalizedString("Done"), for: UIControl.State.normal)
        temp.layer.masksToBounds = true
        temp.layer.cornerRadius = 3.0
        temp.addTarget(self, action: #selector(doneButtonPressed(_:)), for: UIControl.Event.touchUpInside)
        temp.backgroundColor = UIColor(named: "BottomBarNormalText", in: Bundle.this, compatibleWith: nil)
        temp.isEnabled = false
        
        let bottonButtonsHeight: CGFloat = 30.0
        
        var doneWidth = temp.currentTitle?.width(withConstrainedHeight: 20.0,
                                                 font: UIFont.systemFont(ofSize: 15.0)) ?? 0.0
        doneWidth = max(70.0, doneWidth)
        temp.frame = CGRect(x: 0,
                            y: 0,
                            width: doneWidth,
                            height: bottonButtonsHeight)
        
        return temp
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupDefualtItems()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupDefualtItems()
    }
    
    func setupDefualtItems() {
        self.delegate = self
        
        let previewButtonItem = UIBarButtonItem(customView: previewButton)
        let originalPhotoButtonItem = UIBarButtonItem(customView: originalPhotoButton)
        let photoBytesLableItem = UIBarButtonItem(customView: photoBytesLabel)
        let doneButtonItem = UIBarButtonItem(customView: doneButton)
        
        let flexibleSpaceItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace,
                                                target: nil,
                                                action: nil)
        self.items = [previewButtonItem,
                      originalPhotoButtonItem,
                      photoBytesLableItem,
                      flexibleSpaceItem,
                      doneButtonItem]
        
        photoBytesLabel.addSubview(photoBytesIndicatorView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    // MARK: -  actions
    @objc func previewButtonPressed(_ button: UIButton) {
        barDelegate?.previewButtonPressed(button)
    }
    
    @objc func originalButtonPressed(_ button: UIButton) {
        button.isSelected = !button.isSelected
        barDelegate?.originalButtonPressed(button)
    }
    
    @objc func doneButtonPressed(_ button: UIButton) {
        barDelegate?.doneButtonPressed(button)
    }
    
    // MARK: - copy
    override func copy() -> Any {
        let result = LGMPAlbumDetailBottomToolBar(frame: self.frame)
        result.allowSelectOriginal = allowSelectOriginal
        result.barDelegate = barDelegate
        result.previewButton = previewButton
        result.originalPhotoButton = originalPhotoButton
        result.photoBytesLabel = photoBytesLabel
        result.doneButton = doneButton
        return result
    }
}

extension LGMPAlbumDetailBottomToolBar: UIToolbarDelegate {
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        guard let barDelegate = barDelegate, let barPosition = barDelegate.position?(for: bar) else {
            return UIBarPosition.bottom
        }
        return barPosition
    }
}

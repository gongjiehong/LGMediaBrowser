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
        temp.setTitleColor(UIColor(colorName: "BottomBarDisableText"), for: UIControl.State.disabled)
        temp.setTitleColor(UIColor(colorName: "BottomBarNormalText"), for: UIControl.State.normal)
        temp.isEnabled = false
        return temp
    }()
    
    internal lazy var originalPhotoButton: UIButton = {
        let temp = UIButton(type: UIButton.ButtonType.custom)
        temp.titleLabel?.font = UIFont.systemFont(ofSize: 15.0)
        temp.setTitle(LGLocalizedString("Original"), for: UIControl.State.normal)
        temp.setImage(UIImage(namedFromThisBundle: "btn_original_normal"), for: UIControl.State.normal)
        temp.setImage(UIImage(namedFromThisBundle: "btn_original_selected"), for: UIControl.State.selected)
        temp.setTitleColor(UIColor(colorName: "BottomBarDisableText"), for: UIControl.State.disabled)
        temp.setTitleColor(UIColor(colorName: "BottomBarNormalText"), for: UIControl.State.normal)
        temp.addTarget(self, action: #selector(originalButtonPressed(_:)), for: UIControl.Event.touchUpInside)
        temp.isEnabled = false
        return temp
    }()
    
    internal lazy var photoBytesLabel: UILabel = {
        let temp = UILabel(frame: CGRect.zero)
        temp.font = UIFont.systemFont(ofSize: 15.0)
        temp.textColor = UIColor(colorName: "BottomBarNormalText")
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
        temp.backgroundColor = UIColor(colorName: "BottomBarNormalText")
        temp.isEnabled = false
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
        
        self.contentMode = UIView.ContentMode.top
    }
    
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        let bottonButtonsHeight: CGFloat = 30.0
        let previewTitleWidth = LGLocalizedString("Preview").width(withConstrainedHeight: 20.0,
                                                                   font: UIFont.systemFont(ofSize: 15.0))
        previewButton.frame = CGRect(x: 0,
                                     y: 0,
                                     width: previewTitleWidth,
                                     height: bottonButtonsHeight)
        
        if allowSelectOriginal {
            let originalTitleWidth = LGLocalizedString("Original").width(withConstrainedHeight: 20.0,
                                                                         font: UIFont.systemFont(ofSize: 15.0)) + 20.0
            originalPhotoButton.frame = CGRect(x: 0,
                                               y: 0,
                                               width: originalTitleWidth + 10.0,
                                               height: bottonButtonsHeight)
            photoBytesLabel.frame = CGRect(x: 0, y: 0, width: 80.0, height: bottonButtonsHeight)
        }
        
        var doneWidth = doneButton.currentTitle?.width(withConstrainedHeight: 20.0,
                                                       font: UIFont.systemFont(ofSize: 15.0)) ?? 0.0
        doneWidth = max(70.0, doneWidth)
        doneButton.frame = CGRect(x: 0,
                                  y: 0,
                                  width: doneWidth,
                                  height: bottonButtonsHeight)
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
}

extension LGMPAlbumDetailBottomToolBar: UIToolbarDelegate {
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        guard let barDelegate = barDelegate, let barPosition = barDelegate.position?(for: bar) else {
            return UIBarPosition.bottom
        }
        return barPosition
    }
}

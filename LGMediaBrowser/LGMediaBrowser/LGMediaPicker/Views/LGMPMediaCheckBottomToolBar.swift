//
//  LGMPMediaCheckBottomToolBar.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/11/6.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import UIKit

internal protocol LGMPMediaCheckBottomToolBarDelegate: UIToolbarDelegate {
    func editPictureButtonPressed(_ sender: UIButton)
    func doneButtonPressed(_ button: UIButton)
}

internal class LGMPMediaCheckBottomToolBar: UIToolbar {
    internal lazy var editButton: UIButton = {
        let temp = UIButton(type: UIButton.ButtonType.custom)
        temp.setTitle(LGLocalizedString("Edit"), for: UIControl.State.normal)
        temp.setTitleColor(UIColor(colorName: "BottomBarDisableText"), for: UIControl.State.disabled)
        temp.setTitleColor(UIColor(colorName: "BottomBarNormalText"), for: UIControl.State.normal)
        temp.titleLabel?.font = UIFont.systemFont(ofSize: 15.0)
        temp.addTarget(self, action: #selector(editPicture(_:)), for: UIControl.Event.touchUpInside)
        temp.isEnabled = false
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
    
    weak var barDelegate: LGMPMediaCheckBottomToolBarDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupDefault()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupDefault()
    }
    
    func setupDefault() {
        self.delegate = self
        
        let flexibleSpaceItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace,
                                                target: self,
                                                action: nil)
        let editItem = UIBarButtonItem(customView: editButton)
        let doneItem = UIBarButtonItem(customView: doneButton)
        
        self.items = [editItem, flexibleSpaceItem, doneItem]
    }
    
    // MARK: - layout
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    
    // MARK: - actions
    @objc func editPicture(_ sender: UIButton) {
        barDelegate?.editPictureButtonPressed(sender)
    }
    
    @objc func doneButtonPressed(_ sender: UIButton) {
        barDelegate?.doneButtonPressed(sender)
    }
}

extension LGMPMediaCheckBottomToolBar: UIToolbarDelegate {
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        guard let barDelegate = barDelegate, let barPosition = barDelegate.position?(for: bar) else {
            return UIBarPosition.bottom
        }
        return barPosition
    }
}

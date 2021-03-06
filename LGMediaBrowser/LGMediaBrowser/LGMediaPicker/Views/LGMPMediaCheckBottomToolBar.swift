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
        temp.setTitleColor(UIColor(named: "BottomBarDisableText", in: Bundle.this, compatibleWith: nil), for: UIControl.State.disabled)
        temp.setTitleColor(UIColor(named: "BottomBarNormalText", in: Bundle.this, compatibleWith: nil), for: UIControl.State.normal)
        temp.titleLabel?.font = UIFont.systemFont(ofSize: 15.0)
        temp.addTarget(self, action: #selector(editPicture(_:)), for: UIControl.Event.touchUpInside)
        temp.isEnabled = false
        
        let bottonButtonsHeight: CGFloat = 30.0
        
        var editWidth = temp.currentTitle?.width(withConstrainedHeight: 20.0,
                                                 font: UIFont.systemFont(ofSize: 15.0)) ?? 0.0
        temp.frame = CGRect(x: 0,
                            y: 0,
                            width: editWidth,
                            height: bottonButtonsHeight)
        
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
    
    weak var barDelegate: LGMPMediaCheckBottomToolBarDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupDefault()
    }
    
    var allowEdit: Bool = true
    
    init(frame: CGRect, allowEdit: Bool) {
        super.init(frame: frame)
        self.allowEdit = allowEdit
        editButton.isHidden = !allowEdit
        
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
        let doneItem = UIBarButtonItem(customView: doneButton)
        if allowEdit {
            let editItem = UIBarButtonItem(customView: editButton)
            self.items = [editItem, flexibleSpaceItem, doneItem]
        } else {
            self.items = [flexibleSpaceItem, doneItem]
        }
    }
    
    // MARK: - actions
    @objc func editPicture(_ sender: UIButton) {
        barDelegate?.editPictureButtonPressed(sender)
    }
    
    @objc func doneButtonPressed(_ sender: UIButton) {
        barDelegate?.doneButtonPressed(sender)
    }
    
    // MARK: - copy(fake)
    override func copy() -> Any {
        let result = LGMPMediaCheckBottomToolBar(frame: self.frame, allowEdit: self.allowEdit)
        return result
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

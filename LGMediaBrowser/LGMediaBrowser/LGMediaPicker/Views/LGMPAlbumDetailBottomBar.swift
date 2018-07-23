//
//  LGMPAlbumDetailBottomBar.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/7/4.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import UIKit

public protocol LGMPAlbumDetailBottomBarDelegate: NSObjectProtocol {
    func previewButtonPressed(_ button: UIButton)
    func originalButtonPressed(_ button: UIButton)
    func doneButtonPressed(_ button: UIButton)
}

public class LGMPAlbumDetailBottomBar: UIView {
    
    public var allowSelectOriginal: Bool = true
    
    public weak var delegate: LGMPAlbumDetailBottomBarDelegate?
    
    public lazy var cutLine: UIView = {
        let temp = UIView(frame: CGRect(x: 0, y: 0, width: self.bounds.width, height: 1.0))
        temp.backgroundColor = UIColor(colorName: "CutLine")
        return temp
    }()
    
    public lazy var previewButton: UIButton = {
        let temp = UIButton(type: UIButton.ButtonType.custom)
        temp.titleLabel?.font = UIFont.systemFont(ofSize: 15.0)
        temp.setTitle(LGLocalizedString("Preview"), for: UIControl.State.normal)
        temp.addTarget(self, action: #selector(previewButtonPressed(_:)), for: UIControl.Event.touchUpInside)
        temp.setTitleColor(UIColor(colorName: "BottomBarDisableText"), for: UIControl.State.disabled)
        temp.setTitleColor(UIColor(colorName: "BottomBarNormalText"), for: UIControl.State.normal)
        temp.isEnabled = false
        return temp
    }()
    
    public lazy var originalPhotoButton: UIButton = {
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
    
    public lazy var photoBytesLabel: UILabel = {
        let temp = UILabel(frame: CGRect.zero)
        temp.font = UIFont.systemFont(ofSize: 15.0)
        temp.textColor = UIColor(colorName: "BottomBarNormalText")
        return temp
    }()
    
    public lazy var doneButton: UIButton = {
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
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupDefualtViews()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupDefualtViews()
    }
    
    func setupDefualtViews() {
        self.addSubview(cutLine)
        self.addSubview(previewButton)
        self.addSubview(originalPhotoButton)
        self.addSubview(photoBytesLabel)
        self.addSubview(doneButton)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        cutLine.frame = CGRect(x: 0, y: 0, width: self.lg_width, height: 0.5)
        
        var offsetX: CGFloat = 12.0
        let bottonButtonsHeight: CGFloat = 30.0
        let previewTitleWidth = LGLocalizedString("Preview").width(withConstrainedHeight: 20.0,
                                                                  font: UIFont.systemFont(ofSize: 15.0))
        previewButton.frame = CGRect(x: offsetX,
                                     y: 7,
                                     width: previewTitleWidth,
                                     height: bottonButtonsHeight)
        offsetX = previewButton.frame.maxX + 20.0
        
        if allowSelectOriginal {
            let originalTitleWidth = LGLocalizedString("Original").width(withConstrainedHeight: 20.0,
                                                                         font: UIFont.systemFont(ofSize: 15.0)) + 20.0
            originalPhotoButton.frame = CGRect(x: offsetX,
                                               y: 7,
                                               width: originalTitleWidth,
                                               height: bottonButtonsHeight)
            offsetX = originalPhotoButton.frame.maxX + 5.0
            
            photoBytesLabel.frame = CGRect(x: offsetX, y: 7, width: 80.0, height: bottonButtonsHeight)
        }
        
        var doneWidth = doneButton.currentTitle?.width(withConstrainedHeight: 20.0,
                                                       font: UIFont.systemFont(ofSize: 15.0)) ?? 0.0
        doneWidth = max(70.0, doneWidth)
        doneButton.frame = CGRect(x: self.lg_width - doneWidth - 12.0,
                                  y: 7,
                                  width: doneWidth,
                                  height: bottonButtonsHeight)
    }

    // MARK: -  actions
    @objc func previewButtonPressed(_ button: UIButton) {
        delegate?.previewButtonPressed(button)
    }
    
    @objc func originalButtonPressed(_ button: UIButton) {
        button.isSelected = !button.isSelected
        delegate?.originalButtonPressed(button)
    }
    
    @objc func doneButtonPressed(_ button: UIButton) {
        delegate?.doneButtonPressed(button)
    }
}

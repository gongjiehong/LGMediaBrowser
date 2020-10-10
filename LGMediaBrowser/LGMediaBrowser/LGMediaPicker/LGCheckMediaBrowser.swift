//
//  LGCheckMediaBrowser.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/11/14.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import UIKit

internal protocol LGCheckMediaBrowserCallBack: NSObjectProtocol {
    func checkMedia(_ browser: LGCheckMediaBrowser,
                    withIndex index: Int,
                    isSelected: Bool,
                    complete: @escaping (Bool) -> Void)
    func checkMedia(_ browser: LGCheckMediaBrowser, didDoneWith photoList: [LGAlbumAssetModel])
}

internal class LGCheckMediaBrowser: LGMediaBrowser {
    
    weak var checkMediaCallBack: LGCheckMediaBrowserCallBack?
    
    var pickerConfigs: LGMediaPicker.Configuration!
    
    lazy var bottomToolBar: LGMPMediaCheckBottomToolBar = {
        let temp = LGMPMediaCheckBottomToolBar(frame: CGRect(x: 0,
                                                             y: self.view.lg_height - UIDevice.bottomSafeMargin - 44.0,
                                                             width: self.view.lg_width,
                                                             height: UIDevice.bottomSafeMargin + 44.0),
                                               allowEdit: allowEdit)
        temp.barDelegate = self
        return temp
    }()
    
    lazy var checkMediaButton: LGClickAreaButton = {
        let tempButton = LGClickAreaButton(type: UIButton.ButtonType.custom)
        tempButton.frame = CGRect(x: 0, y: 0, width: 23.0, height: 23.0)
        tempButton.setBackgroundImage(UIImage(namedFromThisBundle: "button_unselected"), for: UIControl.State.normal)
        tempButton.setBackgroundImage(UIImage(namedFromThisBundle: "button_selected"), for: UIControl.State.selected)
        tempButton.addTarget(self, action: #selector(selectButtonPressed(_:)), for: UIControl.Event.touchUpInside)
        tempButton.setTitleColor(UIColor.white, for: UIControl.State.normal)
        tempButton.titleLabel?.font = UIFont.systemFont(ofSize: 12.0)
        tempButton.enlargeOffset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        return tempButton
    }()
    
    var allowEdit: Bool {
        return pickerConfigs.allowEditImage || pickerConfigs.allowEditVideo
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavigationItems()
        
        contructBottomToolBar()
        
        self.actionView.animate(hidden: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        refreshCheckButtonStatus()
        
        refreshEditButtonStatus()
    }
    
    // MARK: - setup & refres
    func refreshCheckButtonStatus() {
        refreshCheckButtonStatus(withIndex: self.currentIndex)
    }
    
    func refreshCheckButtonStatus(withIndex index: Int) {
        if self.mediaArray.count <= index {
            return
        }
        
        let model = self.mediaArray[index]
        if let photoModel = model.photoModel {
            if photoModel.isSelected {
                checkMediaButton.isSelected = true
                checkMediaButton.setTitle("\(photoModel.currentSelectedIndex)", for: UIControl.State.normal)
            } else {
                checkMediaButton.isSelected = false
                checkMediaButton.setTitle(nil, for: UIControl.State.normal)
            }
        } else {
            checkMediaButton.isSelected = false
            checkMediaButton.setTitle(nil, for: UIControl.State.normal)
        }
    }
    
    override func refreshCountLayout() {
        let layoutTitle = "\(self.currentIndex + 1) / \(self.mediaArray.count)"
        self.title = layoutTitle
    }
    
    func setupNavigationItems() {
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: checkMediaButton)
    }
    
    func contructBottomToolBar() {
        self.view.addSubview(bottomToolBar)
        
        bottomToolBar.translatesAutoresizingMaskIntoConstraints = false
        
        bottomToolBar.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        bottomToolBar.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        bottomToolBar.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        bottomToolBar.heightAnchor.constraint(equalToConstant: 44.0 + UIDevice.bottomSafeMargin).isActive = true
    }
    
    // MARK: - 显示和隐藏控件
    override func showOrHideControls(_ show: Bool) {
        if isAnimating {
            return
        }
        
        isShowingControls = show
        
        if show {
            isAnimating = true
            
            showsStatusBar = true
            self.navigationController?.setNavigationBarHidden(false, animated: true)
            self.setNeedsStatusBarAppearanceUpdate()
            
            UIView.animate(withDuration: TimeInterval(UINavigationController.hideShowBarDuration),
                           animations:
                {
                    self.bottomToolBar.transform = CGAffineTransform.identity
                    self.bottomToolBar.alpha = 1.0
            }) { (isFinished) in
                self.isAnimating = false
            }
        } else {
            isAnimating = true
            
            showsStatusBar = false
            self.navigationController?.setNavigationBarHidden(true, animated: true)
            self.setNeedsStatusBarAppearanceUpdate()
            
            UIView.animate(withDuration: TimeInterval(UINavigationController.hideShowBarDuration),
                           animations:
                {
                    self.bottomToolBar.transform = CGAffineTransform(translationX: 0,
                                                                     y: self.bottomToolBar.lg_height)
                    self.bottomToolBar.alpha = 0.0
                    
            }) { (isFinished) in
                self.isAnimating = false
            }
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.bottomToolBar.isUserInteractionEnabled = false
    }
    
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        super.scrollViewDidEndDecelerating(scrollView)
        let index = Int(scrollView.contentOffset.x / scrollView.lg_width)
        if self.mediaArray.count > index {
            let model = self.mediaArray[index]
            if let photoModel = model.photoModel {
                checkMediaButton.isSelected = photoModel.isSelected
            }
        }
        self.bottomToolBar.isUserInteractionEnabled = true
        
        refreshCheckButtonStatus()
        
        refreshEditButtonStatus()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let index = Int(scrollView.contentOffset.x / scrollView.lg_width)
        refreshCheckButtonStatus(withIndex: index)
        refreshEditButtonStatus()
    }
    
    func refreshEditButtonStatus() {
        guard self.mediaArray.count > self.currentIndex else {return}
        let mediaModel = self.mediaArray[self.currentIndex]
        
        if !allowEdit {
        } else {
            bottomToolBar.editButton.isHidden = false
            if (mediaModel.mediaType == .image && pickerConfigs.allowEditImage) ||
                (mediaModel.mediaType == .video && pickerConfigs.allowEditVideo) {
                bottomToolBar.editButton.isEnabled = true
            } else {
                bottomToolBar.editButton.isEnabled = false
            }
        }
    }
    
    
    
    // MARK: -  选择按钮点击事件处理
    @objc func selectButtonPressed(_ button: UIButton) {
        if !button.isSelected {
            button.layer.add(buttonStatusChangedAnimation(), forKey: nil)
        }
        
        guard let checkMediaCallBack = checkMediaCallBack else {return}
        
        checkMediaCallBack.checkMedia(self,
                                                            withIndex: self.currentIndex,
                                                            isSelected: !button.isSelected)
        { [weak self] (canSelect) in
            guard let weakSelf = self else {return}
            if canSelect {
                button.isSelected = !button.isSelected
                let model = weakSelf.mediaArray[weakSelf.currentIndex]
                if let photoModel = model.photoModel {
                    photoModel.isSelected = button.isSelected
                    weakSelf.refreshCheckButtonStatus()
                }
            }
        }        
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.default
    }
}

// MARK: - 自定义动画回调
@objc extension LGCheckMediaBrowser {
    @objc override func navigationController(_ navigationController: UINavigationController,
                                             animationControllerFor operation: UINavigationController.Operation,
                                             from fromVC: UIViewController,
                                             to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning?
    {
        let result = super.navigationController(navigationController,
                                                animationControllerFor: operation,
                                                from: fromVC,
                                                to: toVC) as? LGMPPreviewTransition
        
        result?.bottomBar = bottomToolBar
        return result
    }
    
    @objc override func navigationController(_ navigationController: UINavigationController,
                                             interactionControllerFor controller: UIViewControllerAnimatedTransitioning)
        -> UIViewControllerInteractiveTransitioning?
    {
        let result = super.navigationController(navigationController,
                                                interactionControllerFor: controller) as? LGMediaBrowserInteractiveTransition
        result?.bottomBar = self.bottomToolBar
        return result
    }
}

extension LGCheckMediaBrowser: LGMPMediaCheckBottomToolBarDelegate {
    func editPictureButtonPressed(_ sender: UIButton) {
        
    }
    
    func doneButtonPressed(_ button: UIButton) {
        checkMediaCallBack?.checkMedia(self, didDoneWith: [])
    }
    
    public func position(for bar: UIBarPositioning) -> UIBarPosition {
        return UIBarPosition.bottom
    }
}

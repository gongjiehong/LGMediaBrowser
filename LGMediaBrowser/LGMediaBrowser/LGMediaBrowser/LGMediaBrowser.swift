//
//  LGMediaBrowser.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/4/27.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import UIKit
import Photos

/// override hitTest 解决slider滑动问题
fileprivate class LGCollectionView: UICollectionView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        if let view = view, view.isKind(of: UISlider.self) {
            self.isScrollEnabled = false
        } else {
            self.isScrollEnabled = true
        }
        return view
    }
}

/// 全局设置
var globalConfigs: LGMediaBrowserSettings = LGMediaBrowserSettings()

/// 媒体文件浏览器，支持视频，音频（需要系统支持的格式）；普通图片，LivePhoto等
public class LGMediaBrowser: UIViewController {
    
    /// 重用标识定义
    private struct Reuse {
        static var VideoCell = "LGMediaBrowserVideoCell"
        static var AudioCell = "LGMediaBrowserAudioCell"
        static var GeneralPhotoCell = "LGMediaBrowserGeneralPhotoCell"
        static var LivePhotoCell = "LGMediaBrowserLivePhotoCell"
        static var Other = "UICollectionViewCell"
    }
    
    /// 左右元素的间距
    private let itemPadding: CGFloat = 10.0
    
    /// 自定义滑动dismiss Transition
    private var interactiveTransition: LGMediaBrowserInteractiveTransition!
    
    /// 显示各种媒体文件的UICollectionView
    public weak var collectionView: UICollectionView!
    
    /// 媒体文件模型LGMediaModel array
    public var mediaArray: [LGMediaModel] = []
    
    /// 回调
    public weak var delegate: LGMediaBrowserDelegate?
    
    /// 数据源
    public weak var dataSource: LGMediaBrowserDataSource?
    
    
    /// 从哪个视图present上来的
    public weak var targetView: UIView?
    
    /// 动画用到的图片
    public weak var animationImage: UIImage? {
        if self.mediaArray.count == 0 {
            return nil
        }
        let model = self.mediaArray[currentIndex]
        return model.thumbnailImage
    }
    
    /// 分页标记
    public weak var pageControl: UIPageControl!
    
    /// 关闭和删除按钮视图
    weak var actionView: LGActionView!
    
    /// 浏览器的当前状态，分为纯浏览和浏览并删除，浏览并删除时显示删除按钮
    public var status: LGMediaBrowserStatus = .browsing
    
    /// 当前显示的页码
    var currentIndex: Int = 0 {
        didSet {
            refreshPageControl()
        }
    }
    
    /// UICollectionView显示设置
    lazy var flowLayout: UICollectionViewFlowLayout  = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0.0
        layout.minimumLineSpacing = itemPadding * 2
        layout.scrollDirection = UICollectionViewScrollDirection.horizontal
        layout.sectionInset = UIEdgeInsets(top: 0.0, left: itemPadding, bottom: 0.0, right: itemPadding)
        return layout
    }()
    
    // MARK: -  初始化
    override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public convenience init(mediaArray: [LGMediaModel],
                            configs: LGMediaBrowserSettings,
                            status: LGMediaBrowserStatus = .browsing,
                            currentIndex: Int = 0) {
        self.init(nibName: nil, bundle: nil)
        self.mediaArray = mediaArray
        globalConfigs = configs
        self.status = status
        if self.status == .browsingAndEditing {
            globalConfigs.displayDeleteButton = true
        }
        self.currentIndex = currentIndex
    }
    
    // MARK: -  视图load后进行一系列初始化操作
    override public func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = globalConfigs.backgroundColor
        
        setupTransition()
        
        setupCollectionView()
        
        setupActionView()
        
        setupPageControl()
        
        installNotifications()
        
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        
        addPanDissmissGesture()
    }
    
    /// 添加下拉关闭手势
    func addPanDissmissGesture() {
        self.interactiveTransition = LGMediaBrowserInteractiveTransition(fromTargetView: self.targetView,
                                                                         toTargetView: self.targetView,
                                                                         targetController: self)
        self.interactiveTransition.addPanGestureFor(viewController: self)
        self.interactiveTransition.panDismissGesture?.delegate = self
    }
    
    /// 添加通知
    func installNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(deviceOrientationDidChange(_:)),
                                               name: NSNotification.Name.UIDeviceOrientationDidChange,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(tapedScreen(_:)),
                                               name: kTapedScreenNotification, object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(needHideControls(_:)),
                                               name: kNeedHideControlsNotification,
                                               object: nil)
    }
    
    /// 设置自定义动画
    func setupTransition() {
        self.transitioningDelegate = self
        self.modalPresentationStyle = .currentContext
    }
    
    /// 设置collectionView
    func setupCollectionView() {
        let frame = CGRect(x: -itemPadding,
                            y: UIDevice.topSafeMargin,
                            width: self.view.lg_width + itemPadding * 2.0,
                            height: self.view.lg_height - UIDevice.topSafeMargin - UIDevice.bottomSafeMargin)
        let collection = LGCollectionView(frame: frame,
                                          collectionViewLayout: flowLayout)
        self.collectionView = collection
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        if #available(iOS 11.0, *) {
            self.collectionView.contentInsetAdjustmentBehavior = .never
        } else {
        }
        
        self.view.addSubview(self.collectionView)
        
        self.collectionView.delaysContentTouches = false
        
        self.collectionView.register(LGMediaBrowserVideoCell.self, forCellWithReuseIdentifier: Reuse.VideoCell)
        self.collectionView.register(LGMediaBrowserAudioCell.self, forCellWithReuseIdentifier: Reuse.AudioCell)
        self.collectionView.register(LGMediaBrowserGeneralPhotoCell.self,
                                     forCellWithReuseIdentifier: Reuse.GeneralPhotoCell)
        self.collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: Reuse.Other)
        
        self.collectionView.isMultipleTouchEnabled = true
        self.collectionView.delaysContentTouches = false
        self.collectionView.canCancelContentTouches = true
        self.collectionView.alwaysBounceVertical = false
        self.collectionView.isPagingEnabled = true
        self.collectionView.backgroundColor = UIColor.clear
        self.collectionView.keyboardDismissMode = .onDrag
    }
    
    func setupActionView() {
        let temp = LGActionView(frame: CGRect(x: 0, y: 0, width: self.view.lg_width, height: 100))
        temp.delegate = self
        self.actionView = temp
        self.view.addSubview(temp)
        self.actionView.animate(hidden: false)
    }
    
    func setupPageControl() {
        let originY = self.view.lg_height - UIDevice.topSafeMargin - UIDevice.bottomSafeMargin - 85
        let temp = UIPageControl(frame: CGRect(x: 0,
                                               y: originY,
                                               width: self.view.lg_width,
                                               height: 20.0))
        temp.hidesForSinglePage = true
        temp.isUserInteractionEnabled = false
        pageControl = temp
        self.view.addSubview(pageControl)
    }

    func refreshPageControl() {
        self.pageControl.numberOfPages = self.mediaArray.count
        self.pageControl.currentPage = currentIndex
    }
    
    // MARK: -  点击屏幕关闭，或者显示控件
    @objc func tapedScreen(_ noti: Notification) {
        if globalConfigs.enableTapToClose && self.status == .browsing {
            self.dismissSelf()
        } else {
            showOrHideControls(!isShowingControls)
        }
    }
    
    @objc func needHideControls(_ noti: Notification) {
        if self.mediaArray[currentIndex].mediaType == LGMediaType.video ||
            self.mediaArray[currentIndex].mediaType == LGMediaType.audio {
            showOrHideControls(!isShowingControls)
        } else {
            showOrHideControls(false)
        }
    }
    
    private var isShowingControls: Bool = true
    private var isAnimating: Bool = false
    func showOrHideControls(_ show: Bool) {
        if isAnimating {
            return
        }
        isShowingControls = show
        if show {
            self.actionView.animate(hidden: false)
            isAnimating = true
            UIView.animate(withDuration: 0.25,
                           animations:
                {
                    self.pageControl.alpha = 1.0
            }) { (isFinished) in
                self.isAnimating = false
            }
        } else {
            self.actionView.animate(hidden: true)
            UIView.animate(withDuration: 0.25,
                           animations:
                {
                    self.pageControl.alpha = 0.0
            }) { (isFinished) in
                self.isAnimating = false
            }
        }
    }
    
    // MARK: -  视图简要显示，处理frame
    private var isFirstTimeLayout: Bool = true
    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if isFirstTimeLayout {
            refreshFrames()
            isFirstTimeLayout = false
        } else {
            
        }
    }
    
    func refreshFrames() {
        let frame = CGRect(x: -itemPadding,
                           y: UIDevice.topSafeMargin,
                           width: self.view.lg_width + itemPadding * 2.0,
                           height: self.view.lg_height - UIDevice.topSafeMargin - UIDevice.bottomSafeMargin)
        self.collectionView.frame = frame
        self.collectionView.reloadData()
        
        self.actionView.frame = CGRect(x: 0, y: 0, width: self.view.lg_width, height: 100)
        
        let originY = self.view.lg_height - UIDevice.topSafeMargin - UIDevice.bottomSafeMargin - 85
        self.pageControl.frame = CGRect(x: 0,
                                        y: originY,
                                        width: self.view.lg_width,
                                        height: 20.0)
        
        refreshPageControl()
        
        if self.currentIndex != 0 {
            self.collectionView.scrollToItem(at: IndexPath(row: self.currentIndex,
                                                           section: 0),
                                             at: UICollectionViewScrollPosition.centeredHorizontally,
                                             animated: false)
        }
    }
    
    // MARK: -  退出当前页面
    
    func dismissSelf() {
        if self.delegate?.responds(to: #selector(LGMediaBrowserDelegate.willDismissAtPageIndex(_:))) == true {
            self.delegate?.willDismissAtPageIndex!(self.currentIndex)
        }
        self.dismiss(animated: true) {
            if self.delegate?.responds(to: #selector(LGMediaBrowserDelegate.didDismissAtPageIndex(_:))) == true {
                self.delegate?.didDismissAtPageIndex!(self.currentIndex)
            }
        }
    }
    

    
    // MARK: -  旋转方向处理
    private var lastOrientation: UIDeviceOrientation = UIDevice.current.orientation
    @objc func deviceOrientationDidChange(_ noti: Notification) {
        if UIDevice.current.orientation == lastOrientation {
        } else {
            lastOrientation = UIDevice.current.orientation
            self.refreshFrames()
        }
    }
    
    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: -  状态栏显示与隐藏处理
    override public var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    override public var prefersStatusBarHidden: Bool {
        return !globalConfigs.displayStatusbar
    } 
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
    }
}

// MARK: - UIViewControllerTransitioningDelegate
extension LGMediaBrowser: UIViewControllerTransitioningDelegate {
    
    func getCurrentLayoutView() -> UIView? {
        if let cell = self.collectionView.cellForItem(at: IndexPath(row: self.currentIndex, section: 0)) {
            if cell.isKind(of: LGMediaBrowserGeneralPhotoCell.self) == true {
                let generalPhotoCell = cell as! LGMediaBrowserGeneralPhotoCell
                let zoomView = generalPhotoCell.previewView as? LGZoomingScrollView
                return zoomView?.imageView
            } else if cell.isKind(of: LGMediaBrowserAudioCell.self) == true ||
                cell.isKind(of: LGMediaBrowserVideoCell.self) == true {
                return (cell as? LGMediaBrowserPreviewCell)?.previewView
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    
    public func animationController(forPresented presented: UIViewController,
                                             presenting: UIViewController,
                                             source: UIViewController) -> UIViewControllerAnimatedTransitioning?
    {
        if self.delegate?.responds(to: #selector(LGMediaBrowserDelegate.viewForMedia(_:index:))) == true {
            if let view = delegate?.viewForMedia!(self, index: self.currentIndex) {
                self.targetView = view
            }
        }
        
        var finalImageSize: CGSize = CGSize.zero
        if let image = self.animationImage {
            finalImageSize = image.size
        } else if let layoutView = getCurrentLayoutView() {
            finalImageSize = layoutView.lg_size
        }
        
        return LGMediaBrowserPresentTransition(direction: .present,
                                               targetView: self.targetView,
                                               finalImageSize: finalImageSize,
                                               placeholderImage: animationImage)
    }
    
    public func animationController(forDismissed dismissed: UIViewController) ->
        UIViewControllerAnimatedTransitioning?
    {
        if self.delegate?.responds(to: #selector(LGMediaBrowserDelegate.viewForMedia(_:index:))) == true {
            if let view = delegate?.viewForMedia!(self, index: self.currentIndex) {
                self.targetView = view
            }
        }
        
        var finalImageSize: CGSize = CGSize.zero
        
        if let layoutView = getCurrentLayoutView() {
            if self.mediaArray[currentIndex].mediaType == LGMediaType.video ||
                self.mediaArray[currentIndex].mediaType == LGMediaType.audio {
                if let image = self.animationImage {
                    finalImageSize = image.size
                }
            } else {
                finalImageSize = layoutView.lg_size
            }
        } else if let image = self.animationImage {
            finalImageSize = image.size
        }
        return LGMediaBrowserPresentTransition(direction: .dismiss,
                                               targetView: self.targetView,
                                               finalImageSize: finalImageSize,
                                               placeholderImage: animationImage)

    }

    public func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) ->
        UIViewControllerInteractiveTransitioning?
    {
        if self.delegate?.responds(to: #selector(LGMediaBrowserDelegate.viewForMedia(_:index:))) == true {
            if let view = delegate?.viewForMedia!(self, index: self.currentIndex) {
                self.targetView = view
            }
        }
        
        if !self.interactiveTransition.isInteration {
            return nil
        }
        
        var finalImageSize: CGSize = CGSize.zero
        var fromTargetView: UIView?
        if let layoutView = getCurrentLayoutView() {
            fromTargetView = layoutView
            if self.mediaArray[currentIndex].mediaType == LGMediaType.video ||
                self.mediaArray[currentIndex].mediaType == LGMediaType.audio {
                if let image = self.animationImage {
                    finalImageSize = image.size
                }
            } else {
                finalImageSize = layoutView.lg_size
            }
        } else if let image = self.animationImage {
            finalImageSize = image.size
        }
        
        self.interactiveTransition.targetController = self
        self.interactiveTransition.toTargetView = self.targetView
        self.interactiveTransition.fromTargetView = fromTargetView
        self.interactiveTransition.targetImage = self.animationImage
        self.interactiveTransition.finalImageSize = finalImageSize
        return self.interactiveTransition
    }
}

// MARK: UICollectionViewDataSource & UICollectionViewDelegate
extension LGMediaBrowser: UICollectionViewDelegate, UICollectionViewDataSource {
    
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return mediaArray.count
    }
    
    public func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let media = mediaArray[indexPath.row]
        switch media.mediaType {
        case .video:
            return listView(collectionView, videoCellForItemAt: indexPath)
        case .audio:
            return listView(collectionView, audioCellForItemAt: indexPath)
        case .generalPhoto:
            return listView(collectionView, generalPhotoCellForItemAt: indexPath)
        case .livePhoto:
            return listView(collectionView, livePhotoCellForItemAt: indexPath)
        default:
            return listView(collectionView, otherCellForItemAt: indexPath)
        }
    }
    
    public func listView(_ collectionView: UICollectionView,
                               videoCellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        var result: LGMediaBrowserVideoCell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Reuse.VideoCell, for: indexPath)
        if let temp = cell as? LGMediaBrowserVideoCell {
            result = temp
        } else {
            result = LGMediaBrowserVideoCell(frame: CGRect.zero)
        }
        result.mediaModel = mediaArray[indexPath.row]
        return result
    }
    
    public func listView(_ collectionView: UICollectionView,
                               audioCellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        var result: LGMediaBrowserAudioCell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Reuse.AudioCell, for: indexPath)
        if let temp = cell as? LGMediaBrowserAudioCell {
            result = temp
        } else {
            result = LGMediaBrowserAudioCell(frame: CGRect.zero)
        }
        result.mediaModel = mediaArray[indexPath.row]
        return result
    }
    
    public func listView(_ collectionView: UICollectionView,
                               generalPhotoCellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        var result: LGMediaBrowserGeneralPhotoCell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Reuse.GeneralPhotoCell, for: indexPath)
        if let temp = cell as? LGMediaBrowserGeneralPhotoCell {
            result = temp
        } else {
            result = LGMediaBrowserGeneralPhotoCell(frame: CGRect.zero)
        }
        result.mediaModel = mediaArray[indexPath.row]
        return result
    }
    
    public func listView(_ collectionView: UICollectionView,
                               livePhotoCellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        var result: LGMediaBrowserVideoCell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Reuse.VideoCell, for: indexPath)
        if let temp = cell as? LGMediaBrowserVideoCell {
            result = temp
        } else {
            result = LGMediaBrowserVideoCell(frame: CGRect.zero)
        }
        result.mediaModel = mediaArray[indexPath.row]
        return result
    }
    
    public func listView(_ collectionView: UICollectionView,
                               otherCellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        var result: LGMediaBrowserVideoCell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Reuse.VideoCell, for: indexPath)
        if let temp = cell as? LGMediaBrowserVideoCell {
            result = temp
        } else {
            result = LGMediaBrowserVideoCell(frame: CGRect.zero)
        }
        result.mediaModel = mediaArray[indexPath.row]
        return result
    }
    
    public func collectionView(_ collectionView: UICollectionView,
                               willDisplay cell: UICollectionViewCell,
                               forItemAt indexPath: IndexPath)
    {
        if let temp = cell as? LGMediaBrowserPreviewCell {
            temp.willDisplay()
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView,
                               didEndDisplaying cell: UICollectionViewCell,
                               forItemAt indexPath: IndexPath)
    {
        if let temp = cell as? LGMediaBrowserPreviewCell {
            temp.didEndDisplay()
        }
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let index = Int(scrollView.contentOffset.x / scrollView.lg_width)
        self.currentIndex = index
        if self.delegate?.responds(to: #selector(LGMediaBrowserDelegate.didScrollToIndex(_:index:))) == true {
            self.delegate?.didScrollToIndex!(self, index: self.currentIndex)
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension LGMediaBrowser: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               sizeForItemAt indexPath: IndexPath) -> CGSize
    {
        return CGSize(width: self.view.lg_width,
                      height: self.view.lg_height - UIDevice.topSafeMargin - UIDevice.bottomSafeMargin)
    }
}

// MARK: -  LGActionViewDelegate
extension LGMediaBrowser: LGActionViewDelegate {
    func closeButtonPressed() {
        dismissSelf()
    }
    
    func deleteButtonPressed() {
        func deleteItemRefresh() {
            self.mediaArray.remove(at: self.currentIndex)
            self.collectionView.performBatchUpdates({
                self.collectionView.deleteItems(at: [IndexPath(row: self.currentIndex, section: 0)])
            }) { (isFinished) in
                if self.currentIndex < self.mediaArray.count {
                    self.refreshPageControl()
                } else {
                    self.currentIndex -= 1
                }
                
                if self.currentIndex < 0 {
                    self.dismissSelf()
                }
            }
        }
        
        if let delegate = self.delegate,
            delegate.responds(to: #selector(LGMediaBrowserDelegate.removeMedia(_:index:reload:)))
        {
            delegate.removeMedia!(self,
                                  index: self.currentIndex,
                                  reload: {
                                    deleteItemRefresh()
            })
        }
    }
}

extension LGMediaBrowser: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.view?.isKind(of: UISlider.self) == true {
            return false
        }
        return true
    }
}


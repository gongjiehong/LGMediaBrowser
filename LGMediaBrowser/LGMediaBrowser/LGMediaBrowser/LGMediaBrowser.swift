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
internal class LGCollectionView: UICollectionView {
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
var globalConfigs: LGMediaBrowserSettings! = nil

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
    private lazy var interactiveTransition: LGMediaBrowserInteractiveTransition = {
        let temp = LGMediaBrowserInteractiveTransition(fromTargetView: self.targetView,
                                                       toTargetView: self.targetView,
                                                       targetController: self)
        temp.addPanGestureFor(viewController: self)
        temp.panExitGesture?.delegate = self
        
        return temp
    }()
    
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
            if let dataSource = self.dataSource {
                let dataModel = dataSource.photoBrowser(self, photoAtIndex: self.currentIndex)
                return dataModel.thumbnailImage
            }
            return nil
        }
        let model = self.mediaArray[currentIndex]
        return model.thumbnailImage
    }
    
    /// 关闭和删除按钮视图
    weak var actionView: LGActionView!
    
    /// 浏览器的当前状态，分为纯浏览和浏览并删除，浏览并删除时显示删除按钮
    public var status: LGMediaBrowserStatus = .browsing
    
    var showsStatusBar: Bool = true
    
    /// 当前显示的页码
    var currentIndex: Int = 0 {
        didSet {
            refreshCountLayout()
        }
    }
    
    /// UICollectionView显示设置
    lazy var flowLayout: UICollectionViewFlowLayout  = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0.0
        layout.minimumLineSpacing = itemPadding * 2
        layout.scrollDirection = UICollectionView.ScrollDirection.horizontal
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
                            configs: LGMediaBrowserSettings? = nil,
                            status: LGMediaBrowserStatus = .browsing,
                            currentIndex: Int = 0) {
        self.init(nibName: nil, bundle: nil)
        self.mediaArray = mediaArray
        globalConfigs = configs ?? LGMediaBrowserSettings.settings(with: status)
        self.status = status
        if self.status == .browsingAndEditing {
            globalConfigs.showsDeleteButton = true
        }
        self.currentIndex = currentIndex
        
        showsStatusBar = globalConfigs.showsStatusBar
    }
    
    public convenience init(dataSource: LGMediaBrowserDataSource,
                            configs: LGMediaBrowserSettings? = nil,
                            status: LGMediaBrowserStatus = .browsing,
                            currentIndex: Int = 0) {
        self.init(nibName: nil, bundle: nil)
        self.dataSource = dataSource
        globalConfigs = configs ?? LGMediaBrowserSettings.settings(with: status)
        self.status = status
        if self.status == .browsingAndEditing {
            globalConfigs.showsDeleteButton = true
        }
        self.currentIndex = currentIndex
        
        showsStatusBar = globalConfigs.showsStatusBar
    }
    
    // MARK: -  视图load后进行一系列初始化操作
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = globalConfigs.backgroundColor
        
        setupTransition()
        
        setupCollectionView()
        
        setupTopBarInit()
        
        setupMediaArray()
        
        installNotifications()
        
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        
        addPanExitGesture()
        
//        self.extendedLayoutIncludesOpaqueBars = true
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if globalConfigs.showsNavigationBar == true {
            self.navigationController?.setNavigationBarHidden(false, animated: true)
        } else {
            self.navigationController?.setNavigationBarHidden(true, animated: true)
        }
    }
    
    func setupTopBarInit() {
        switch self.status {
        case .browsing, .browsingAndEditing:
            setupActionView()
            break
        case .checkMedia:
            break
        }
    }
    
    func setupNavigationItems() {
        
    }
    
    // MARK: - 初始化数据源
    func setupMediaArray() {
        if let dataSource = self.dataSource {
            let count = dataSource.numberOfPhotosInPhotoBrowser(self)
            self.mediaArray = [LGMediaModel](repeating: LGMediaModel(), count: count)
            self.refreshCountLayout()
        }
    }
    
    /// 添加下拉关闭手势
    func addPanExitGesture() {
        let interactiveTransition = self.interactiveTransition
        if let panPopGeusture = self.navigationController?.interactivePopGestureRecognizer {
            interactiveTransition.panExitGesture?.require(toFail: panPopGeusture)
        }
    }
    
    /// 添加通知
    func installNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(deviceOrientationDidChange(_:)),
                                               name: UIDevice.orientationDidChangeNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(tapedScreen(_:)),
                                               name: LGMediaBrowser.tapedScreenNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(needHideControls(_:)),
                                               name: LGMediaBrowser.needHideControlsNotification,
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
                           y: 0,
                           width: self.view.lg_width + itemPadding * 2.0,
                           height: self.view.lg_height)
        let collection = LGCollectionView(frame: frame,
                                          collectionViewLayout: flowLayout)
        self.collectionView = collection
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        if #available(iOS 11.0, *) {
            self.collectionView.contentInset = UIEdgeInsets(top: -20.0, left: 0, bottom: 0, right: 0)
            self.collectionView.contentInsetAdjustmentBehavior = .never
        } else {
            self.automaticallyAdjustsScrollViewInsets = false
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
        
        if let panPopGeusture = self.navigationController?.interactivePopGestureRecognizer {
            collectionView.panGestureRecognizer.require(toFail: panPopGeusture)
        }
    }
    
    func setupActionView() {
        let temp = LGActionView(frame: CGRect(x: 0,
                                              y: 0,
                                              width: self.view.lg_width,
                                              height: UIDevice.statusBarHeight + UIDevice.topSafeMargin + 44.0))
        temp.delegate = self
        self.actionView = temp
        self.view.addSubview(temp)
        self.actionView.animate(hidden: false)
    }
    
    // MARK: -  点击屏幕关闭，或者显示控件
    @objc func tapedScreen(_ noti: Notification) {
        if globalConfigs.isClickToTurnOffEnabled && self.status == .browsing {
            self.closeSelf()
        } else {
            showOrHideControls(!isShowingControls)
        }
    }
    
    @objc func needHideControls(_ noti: Notification) {
        if self.mediaArray[currentIndex].mediaType == .video ||
            self.mediaArray[currentIndex].mediaType == .audio {
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
            switch self.status {
            case .browsingAndEditing, .browsing:
                self.actionView.animate(hidden: false)
                break
            case .checkMedia:
                showsStatusBar = true
                self.navigationController?.setNavigationBarHidden(false, animated: true)
                self.setNeedsStatusBarAppearanceUpdate()
                break
            }
            isAnimating = true
            UIView.animate(withDuration: 0.25,
                           animations:
                {
            }) { (isFinished) in
                self.isAnimating = false
            }
        } else {
            switch self.status {
            case .browsingAndEditing, .browsing:
                self.actionView.animate(hidden: true)
                break
            case .checkMedia:
                showsStatusBar = false
                self.navigationController?.setNavigationBarHidden(true, animated: true)
                self.setNeedsStatusBarAppearanceUpdate()
                break
            }
            UIView.animate(withDuration: 0.25,
                           animations:
                {
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
                           y: 0,
                           width: self.view.lg_width + itemPadding * 2.0,
                           height: self.view.lg_height)
        self.collectionView.frame = frame
        self.collectionView.reloadData()
        
        switch self.status {
        case .browsing, .browsingAndEditing:
            self.actionView.frame = CGRect(x: 0,
                                           y: 0,
                                           width: self.view.lg_width,
                                           height: UIDevice.statusBarHeight + UIDevice.topSafeMargin + 44.0)
            break
        case .checkMedia:
            break
        }
        
        if self.currentIndex != 0 {
            self.collectionView.scrollToItem(at: IndexPath(row: self.currentIndex,
                                                           section: 0),
                                             at: UICollectionView.ScrollPosition.centeredHorizontally,
                                             animated: true)
        }
    }
    
    // MARK: -  退出当前页面
    
    func closeSelf() {
        
        func callWillHide() {
            if let delegate = self.delegate,
                delegate.responds(to: #selector(LGMediaBrowserDelegate.willHide(_:atIndex:))) {
                delegate.willHide!(self, atIndex: self.currentIndex)
            }
        }
        
        func callDidHide() {
            if let delegate = self.delegate,
                delegate.responds(to: #selector(LGMediaBrowserDelegate.didHide(_:atIndex:)))
            {
                delegate.didHide!(self, atIndex: self.currentIndex)
            }
        }
        
        callWillHide()
        
        if let navi = self.navigationController, navi.topViewController == self, navi.viewControllers.count > 1 {
            self.navigationController?.popViewController(animated: true)
            callDidHide()
        } else {
            self.dismiss(animated: true) {
                callDidHide()
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
        return !showsStatusBar
    }
    
    override public var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return UIStatusBarAnimation.slide
    }
    
    // MARK: - 刷新数量显示
    
    func refreshCountLayout() {
        let layoutTitle = "\(self.currentIndex + 1) / \(self.mediaArray.count)"
        if self.status == .checkMedia {
            self.title = layoutTitle
        } else {
            guard let actionView = self.actionView else {return}
            actionView.titleLabel.text = layoutTitle
        }
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
        globalConfigs = nil
    }
}

// MARK: - UIViewControllerTransitioningDelegate
extension LGMediaBrowser: UIViewControllerTransitioningDelegate, LGMediaBrowserPushAnimationDelegate {
    
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
            if self.mediaArray[currentIndex].mediaType == .video ||
                self.mediaArray[currentIndex].mediaType == .audio {
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
        self.interactiveTransition.actionType = .dismiss
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
            if self.mediaArray[currentIndex].mediaType == .video ||
                self.mediaArray[currentIndex].mediaType == .audio {
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
    
    public func navigationController(_ navigationController: UINavigationController,
                                     animationControllerFor operation: UINavigationController.Operation,
                                     from fromVC: UIViewController,
                                     to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning?
    {
        if self.delegate?.responds(to: #selector(LGMediaBrowserDelegate.viewForMedia(_:index:))) == true {
            if let view = delegate?.viewForMedia!(self, index: self.currentIndex) {
                self.targetView = view
            }
        }
        
        if operation == .push {
            let transition = LGMPPreviewTransition(withDirection: LGMPPreviewTransition.Direction.push)
            transition.placeholderImage = animationImage
            transition.targetView = targetView
            return transition
        } else {
            if fromVC.self != self.self {
                return nil
            }
            
            let transition = LGMPPreviewTransition(withDirection: LGMPPreviewTransition.Direction.pop)
            transition.placeholderImage = animationImage
            transition.targetView = targetView
            if let layoutView = getCurrentLayoutView() {
                transition.finalImageSize = layoutView.lg_size
            }
            return transition
        }
    }
    
    public func navigationController(_ navigationController: UINavigationController,
                                     interactionControllerFor controller: UIViewControllerAnimatedTransitioning)
        -> UIViewControllerInteractiveTransitioning?
    {
        self.interactiveTransition.actionType = .pop
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
            if self.mediaArray[currentIndex].mediaType == .video ||
                self.mediaArray[currentIndex].mediaType == .audio {
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
        return self.interactiveTransition.isInteration ? self.interactiveTransition : nil
    }
}

// MARK: UICollectionViewDataSource & UICollectionViewDelegate
extension LGMediaBrowser: UICollectionViewDelegate, UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let dataSource = self.dataSource {
            return dataSource.numberOfPhotosInPhotoBrowser(self)
        } else {
            return mediaArray.count
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        var media: LGMediaModel
        if let dataSource = self.dataSource {
            media = dataSource.photoBrowser(self, photoAtIndex: indexPath.row)
            self.mediaArray[indexPath.row] = media
        } else {
            media = mediaArray[indexPath.row]
        }
        
        switch media.mediaType {
        case .video:
            return listView(collectionView, videoCellForItemAt: indexPath, mediaModel: media)
        case .audio:
            return listView(collectionView, audioCellForItemAt: indexPath, mediaModel: media)
        case .generalPhoto:
            return listView(collectionView, generalPhotoCellForItemAt: indexPath, mediaModel: media)
        case .livePhoto:
            return listView(collectionView, livePhotoCellForItemAt: indexPath, mediaModel: media)
        default:
            return listView(collectionView, otherCellForItemAt: indexPath, mediaModel: media)
        }
    }
    
    public func listView(_ collectionView: UICollectionView,
                         videoCellForItemAt indexPath: IndexPath,
                         mediaModel: LGMediaModel) -> UICollectionViewCell
    {
        var result: LGMediaBrowserVideoCell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Reuse.VideoCell, for: indexPath)
        if let temp = cell as? LGMediaBrowserVideoCell {
            result = temp
        } else {
            result = LGMediaBrowserVideoCell(frame: CGRect.zero)
        }
        result.mediaModel = mediaModel
        return result
    }
    
    public func listView(_ collectionView: UICollectionView,
                         audioCellForItemAt indexPath: IndexPath,
                         mediaModel: LGMediaModel) -> UICollectionViewCell
    {
        var result: LGMediaBrowserAudioCell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Reuse.AudioCell, for: indexPath)
        if let temp = cell as? LGMediaBrowserAudioCell {
            result = temp
        } else {
            result = LGMediaBrowserAudioCell(frame: CGRect.zero)
        }
        result.mediaModel = mediaModel
        return result
    }
    
    public func listView(_ collectionView: UICollectionView,
                         generalPhotoCellForItemAt indexPath: IndexPath,
                         mediaModel: LGMediaModel) -> UICollectionViewCell
    {
        var result: LGMediaBrowserGeneralPhotoCell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Reuse.GeneralPhotoCell, for: indexPath)
        if let temp = cell as? LGMediaBrowserGeneralPhotoCell {
            result = temp
        } else {
            result = LGMediaBrowserGeneralPhotoCell(frame: CGRect.zero)
        }
        result.mediaModel = mediaModel
        return result
    }
    
    public func listView(_ collectionView: UICollectionView,
                         livePhotoCellForItemAt indexPath: IndexPath,
                         mediaModel: LGMediaModel) -> UICollectionViewCell
    {
        var result: LGMediaBrowserVideoCell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Reuse.VideoCell, for: indexPath)
        if let temp = cell as? LGMediaBrowserVideoCell {
            result = temp
        } else {
            result = LGMediaBrowserVideoCell(frame: CGRect.zero)
        }
        result.mediaModel = mediaModel
        return result
    }
    
    public func listView(_ collectionView: UICollectionView,
                         otherCellForItemAt indexPath: IndexPath,
                         mediaModel: LGMediaModel) -> UICollectionViewCell
    {
        var result: LGMediaBrowserVideoCell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Reuse.VideoCell, for: indexPath)
        if let temp = cell as? LGMediaBrowserVideoCell {
            result = temp
        } else {
            result = LGMediaBrowserVideoCell(frame: CGRect.zero)
        }
        result.mediaModel = mediaModel
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
                      height: self.view.lg_height)
    }
}

// MARK: -  LGActionViewDelegate
extension LGMediaBrowser: LGActionViewDelegate {
    func closeButtonPressed() {
        closeSelf()
    }
    
    func deleteButtonPressed() {
        func deleteItemRefresh() {
            self.mediaArray.remove(at: self.currentIndex)
            self.collectionView.performBatchUpdates({
                self.collectionView.deleteItems(at: [IndexPath(row: self.currentIndex, section: 0)])
            }) { (isFinished) in
                if self.currentIndex < self.mediaArray.count {
                } else {
                    self.currentIndex -= 1
                }
                
                if self.currentIndex < 0 {
                    self.closeSelf()
                }
            }
        }
        
        if let delegate = self.delegate,
            delegate.responds(to: #selector(LGMediaBrowserDelegate.removeMedia(_:index:reload:)))
        {
            delegate.removeMedia!(self,
                                  index: self.currentIndex,
                                  reload:
                {
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

extension LGMediaBrowser {
    public static let tapedScreenNotification = Notification.Name("TapedScreenNotification")
    public static let needHideControlsNotification = Notification.Name("NeedHideControlsNotification")
}

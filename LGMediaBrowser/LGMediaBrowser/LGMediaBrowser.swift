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

var globalConfigs: LGMediaBrowserSettings = LGMediaBrowserSettings()

public class LGMediaBrowser: UIViewController {
    
    private struct Reuse {
        static var VideoCell = "LGMediaBrowserVideoCell"
        static var AudioCell = "LGMediaBrowserAudioCell"
        static var GeneralPhotoCell = "LGMediaBrowserGeneralPhotoCell"
        static var LivePhotoCell = "LGMediaBrowserLivePhotoCell"
        static var Other = "UICollectionViewCell"
    }
    
    private let itemPadding: CGFloat = 10.0

    public weak var collectionView: UICollectionView!
    
    public var mediaArray: [LGMediaModel] = []
    
    public weak var delegate: LGMediaBrowserDelegate?
    public weak var dataSource: LGMediaBrowserDataSource?
    
    public weak var targetView: UIView?
    public weak var animationImage: UIImage!
    
    public weak var pageControl: UIPageControl!
    weak var actionView: LGActionView!
    
    public var status: LGMediaBrowserStatus = .browsing
    
    var currentIndex: Int = 0 {
        didSet {
            self.pageControl.numberOfPages = self.mediaArray.count
            self.pageControl.currentPage = currentIndex
        }
    }
    
    lazy var flowLayout: UICollectionViewFlowLayout  = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0.0
        layout.minimumLineSpacing = itemPadding * 2
        layout.scrollDirection = UICollectionViewScrollDirection.horizontal
        layout.sectionInset = UIEdgeInsets(top: 0.0, left: itemPadding, bottom: 0.0, right: itemPadding)
        return layout
    }()
    
    override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public convenience init(configs: LGMediaBrowserSettings, status: LGMediaBrowserStatus = .browsing) {
        self.init(nibName: nil, bundle: nil)
        globalConfigs = configs
        self.status = status
        if self.status == .browsingAndEditing {
            globalConfigs.displayDeleteButton = true
        }
    }
    
    
    override public func viewDidLoad() {
        super.viewDidLoad()

        setupTransition()
        
        setupCollectionView()
        
        setupActionView()
        
        setupPageControl()
        
        installNotifications()
        
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
    }
    
    func installNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(deviceOrientationDidChange(_:)),
                                               name: NSNotification.Name.UIDeviceOrientationDidChange,
                                               object: nil)
    }
    
    func setupTransition() {
        self.transitioningDelegate = self
        self.modalPresentationStyle = .custom
    }
    
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

    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    func refreshFrames() {
        let frame = CGRect(x: -itemPadding,
                           y: UIDevice.topSafeMargin,
                           width: self.view.lg_width + itemPadding * 2.0,
                           height: self.view.lg_height - UIDevice.topSafeMargin - UIDevice.bottomSafeMargin)
        self.collectionView.frame = frame
        self.collectionView.reloadData()
        
        if self.currentIndex != 0 {
            self.collectionView.scrollToItem(at: IndexPath(row: self.currentIndex, section: 0),
                                             at: UICollectionViewScrollPosition.left,
                                             animated: true)
        }
        
        self.actionView.frame = CGRect(x: 0, y: 0, width: self.view.lg_width, height: 100)
        
        let originY = self.view.lg_height - UIDevice.topSafeMargin - UIDevice.bottomSafeMargin - 85
        self.pageControl.frame = CGRect(x: 0,
                                        y: originY,
                                        width: self.view.lg_width,
                                        height: 20.0)
        
        self.pageControl.numberOfPages = self.mediaArray.count
        self.pageControl.currentPage = currentIndex
        
        if self.currentIndex != 0 {
            self.collectionView.scrollToItem(at: IndexPath(row: self.currentIndex,
                                                           section: 0),
                                             at: UICollectionViewScrollPosition.left,
                                             animated: false)
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

extension LGMediaBrowser: UIViewControllerTransitioningDelegate {
    
    public func animationController(forPresented presented: UIViewController,
                                             presenting: UIViewController,
                                             source: UIViewController) -> UIViewControllerAnimatedTransitioning?
    {
        return LGMediaBrowserPresentTransition(direction: .present,
                                               targetView: self.targetView,
                                               finalImageSize: animationImage.size,
                                               placeholderImage: animationImage)
    }
    
    public func animationController(forDismissed dismissed: UIViewController) ->
        UIViewControllerAnimatedTransitioning?
    {
        if self.currentIndex == 0 {
            self.animationImage = self.mediaArray[0].thumbnailImage
        }
        return LGMediaBrowserPresentTransition(direction: .dismiss,
                                               targetView: self.targetView,
                                               finalImageSize: animationImage.size,
                                               placeholderImage: animationImage)
    }
    
//    public func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) ->
//        UIViewControllerInteractiveTransitioning?
//    {
//        return self
//    }
//
//
//    public func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) ->
//        UIViewControllerInteractiveTransitioning?
//    {
//
//    }
//
//
//    public func presentationController(forPresented presented: UIViewController,
//                                                presenting: UIViewController?,
//                                                source: UIViewController) -> UIPresentationController?
//    {
//
//    }
}

extension LGMediaBrowser: UICollectionViewDelegate, UICollectionViewDataSource {
    // MARK: UICollectionViewDataSource
    
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
        self.animationImage = self.mediaArray[index].thumbnailImage
    }
    
    
    // MARK: UICollectionViewDelegate
    
    
    /*
     // Uncomment this method to specify if the specified item should be highlighted during tracking
     override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
     return true
     }
     */
    
    /*
     // Uncomment this method to specify if the specified item should be selected
     override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
     return true
     }
     */
    
    /*
     // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
     override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
     return false
     }
     
     override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
     return false
     }
     
     override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
     
     }
     */
}

extension LGMediaBrowser: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               sizeForItemAt indexPath: IndexPath) -> CGSize
    {
        return CGSize(width: self.view.lg_width,
                      height: self.view.lg_height - UIDevice.topSafeMargin - UIDevice.bottomSafeMargin)
    }
}


extension LGMediaBrowser: LGActionViewDelegate {
    func closeButtonPressed() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func deleteButtonPressed() {
        func deleteItemRefresh() {
            self.mediaArray.remove(at: self.currentIndex)
            self.collectionView.performBatchUpdates({
                self.collectionView.deleteItems(at: [IndexPath(row: self.currentIndex, section: 0)])
            }) { (isFinished) in
                let tempIndex = self.currentIndex - 1
                
                if tempIndex < 0 {
                    if self.mediaArray.count > 0 {
                        self.currentIndex = 0
                    } else {
                        self.dismiss(animated: true, completion: nil)
                    }
                } else {
                    self.currentIndex = tempIndex
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


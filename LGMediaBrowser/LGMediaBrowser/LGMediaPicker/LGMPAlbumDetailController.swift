//
//  LGMPAlbumDetailController.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/6/25.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import UIKit
import Photos

public class LGMPAlbumDetailController: LGMPBaseViewController {
    weak var listView: UICollectionView!
    
    var albumListModel: LGAlbumListModel?
    
    var dataArray: [LGPhotoModel] = []
    
    var selectedIndexPath: [IndexPath] = []
    
    lazy var allowTakePhoto: Bool = {
        return configs.allowTakePhotoInLibrary &&
            (configs.resultMediaTypes.contains(.video) ||
            configs.resultMediaTypes.contains(.image))
    }()
    
    lazy var isForceTouchAvailable: Bool = {
        if #available(iOS 9.0, *) {
            return self.traitCollection.forceTouchCapability == UIForceTouchCapability.available
        } else {
            return false
        }
    }()
    
    struct Settings {
        static var columnCount: Int = {
            if UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.pad {
                return 6
            } else {
                return 4
            }
        }()
        
        static var itemInteritemSpacing: CGFloat = {
           return 3.0 * min(UIScreen.main.bounds.width / 320.0, 1.4)
        }()
        
        static var itemLineSpacing: CGFloat = {
            return 3.0 * min(UIScreen.main.bounds.width / 320.0, 1.4)
        }()
    }
    
    weak var mainPicker: LGMediaPicker!
    
    var configs: LGMediaPicker.Configuration {
        return mainPicker.config
    }
        
    lazy var bottomToolBar: LGMPAlbumDetailBottomToolBar = {
        let temp = LGMPAlbumDetailBottomToolBar(frame: CGRect(x: 0,
                                                              y: 0,
                                                              width: LGMesurement.screenWidth,
                                                              height: 44.0))
        temp.barDelegate = self
        return temp
    }()

    override public func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setupListCollectionView()
        
        setupCancel()
        
        fetchDataIfNeeded()
        
        PHPhotoLibrary.shared().register(self)
        
        constructBottomToolBar()
    }
    
    func setupCancel() {
        let rightItem = UIBarButtonItem(title: LGLocalizedString("Cancel"),
                                        style: UIBarButtonItem.Style.plain,
                                        target: self,
                                        action: #selector(close))
        self.navigationItem.rightBarButtonItem = rightItem
    }
    
    @objc func close() {
        self.dismiss(animated: true, completion: nil)
    }

    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: -  初始化视图
    
    private struct Reuse {
        static var imageCell: String = "LGMPAlbumDetailImageCell"
        static var cameraCell: String = "LGMPAlbumDetailCameraCell"
    }
    
    var forchTouch: LGForceTouch!
    
    func setupListCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = Settings.itemLineSpacing
        layout.minimumInteritemSpacing = Settings.itemInteritemSpacing
        layout.sectionInset = UIEdgeInsets(top: Settings.itemLineSpacing,
                                           left: Settings.itemLineSpacing,
                                           bottom: Settings.itemLineSpacing,
                                           right: Settings.itemLineSpacing)
        
        let width = min(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
        let columnCount = CGFloat(Settings.columnCount)
        layout.itemSize = CGSize(width: (width - Settings.itemLineSpacing * (columnCount + 1)) / columnCount,
                                 height: (width - Settings.itemLineSpacing * (columnCount + 1)) / columnCount)
        
        
        let collectionView = UICollectionView(frame: self.view.bounds, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = UIColor.white
        self.view.addSubview(collectionView)
        
        self.listView = collectionView
        
        self.listView.register(LGMPAlbumDetailImageCell.self, forCellWithReuseIdentifier: Reuse.imageCell)
        self.listView.register(LGMPAlbumDetailCameraCell.self, forCellWithReuseIdentifier: Reuse.cameraCell)
        
        let forchTouch = LGForceTouch(viewController: self)
        forchTouch.registerForPreviewingWithDelegate(self, sourceView: self.listView)
        self.forchTouch = forchTouch
        
        listView.translatesAutoresizingMaskIntoConstraints = false
        
        if #available(iOS 11.0, *) {
            listView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor,
                                             constant: -44.0).isActive = true
        } else {
            listView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor,
                                             constant: -44.0).isActive = true
        }
        listView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        listView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        listView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
    }
    
    func constructBottomToolBar() {
        self.view.addSubview(bottomToolBar)
        
        bottomToolBar.translatesAutoresizingMaskIntoConstraints = false
        
        if #available(iOS 11.0, *) {
            bottomToolBar.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        } else {
            bottomToolBar.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        }
        bottomToolBar.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        bottomToolBar.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        bottomToolBar.heightAnchor.constraint(equalToConstant: 44.0 + UIDevice.bottomSafeMargin)
    }

    // MARK: - 显示状态
    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
    }
    
    lazy var callOnceScrollToBottom: Void = {
        self.scrollToBottom()
    }()
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        _ = callOnceScrollToBottom
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refreshBottomBarStatus()
        
    }
    
    // MARK: - 获取数据并显示
    @objc func fetchDataIfNeeded(_ needRefresh: Bool = false) {
        if self.dataArray.count == 0 || needRefresh {
            let hud = LGLoadingHUD.show(inView: self.view)
            if let albumListModel = albumListModel {
                if needRefresh {
                    guard let result = albumListModel.result else { return }
                    let photos = LGPhotoManager.fetchPhoto(inResult: result,
                                                           supportMediaType: self.configs.resultMediaTypes)
                    for temp in photos {
                        for selectedTemp in self.mainPicker.selectedDataArray
                            where selectedTemp.asset.localIdentifier == temp.asset.localIdentifier {
                                temp.isSelected = true
                        }
                    }
                    self.dataArray.removeAll()
                    self.dataArray += photos
                    self.listView.reloadData()
                } else {
                    let photos = albumListModel.models
                    for temp in albumListModel.models {
                        for selectedTemp in self.mainPicker.selectedDataArray
                            where selectedTemp.asset.localIdentifier == temp.asset.localIdentifier {
                                temp.isSelected = true
                        }
                    }
                    self.dataArray.removeAll()
                    self.dataArray += photos
                }
                hud.dismiss()
                self.title = albumListModel.title
                self.cachingImages()
                
            } else {
                DispatchQueue.userInteractive.async { [weak self] in
                    guard let weakSelf = self else { return }
                    let album = LGPhotoManager.getAllPhotosAlbum(weakSelf.configs.resultMediaTypes)
                    weakSelf.albumListModel = album
                    weakSelf.dataArray.removeAll()
                    for temp in album.models {
                        for selectedTemp in weakSelf.mainPicker.selectedDataArray
                            where selectedTemp.asset.localIdentifier == temp.asset.localIdentifier
                        {
                            temp.isSelected = true
                        }
                    }
                    weakSelf.dataArray += album.models
                    DispatchQueue.main.async { [weak self] in
                        hud.dismiss()
                        guard let weakSelf = self else { return }
                        weakSelf.title = album.title
                        weakSelf.listView.reloadData()
                        weakSelf.scrollToBottom()
                        weakSelf.cachingImages()
                    }
                }
            }
        }
    }
    
    func cachingImages() {
        var assetArray: [PHAsset] = []
        for model in self.dataArray {
            assetArray.append(model.asset)
        }
        
        let width = min(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
        let columnCount = CGFloat(Settings.columnCount)
        let itemSize = CGSize(width: (width - Settings.itemLineSpacing * (columnCount + 1)) / columnCount,
                                 height: (width - Settings.itemLineSpacing * (columnCount + 1)) / columnCount)
        
        LGPhotoManager.startCachingImages(for: assetArray,
                                          targetSize: CGSize(width: itemSize.width * UIScreen.main.scale,
                                                             height: itemSize.height * UIScreen.main.scale),
                                          contentMode: PHImageContentMode.aspectFill)
    }
    
    func scrollToBottom() {
        if configs.sortBy == .descending {
            return
        }
        
        if self.dataArray.count == 0 {
            return
        }
        
        var row = max(self.dataArray.count - 1, 0)
        if self.allowTakePhoto {
            row += 1
        }
        
        let lastIndexPath = IndexPath(row: row, section: 0)
        self.listView.layoutIfNeeded()
        if row == 0 {
            return
        }
        self.listView.scrollToItem(at: lastIndexPath,
                                   at: UICollectionView.ScrollPosition.bottom,
                                   animated: false)
    }
    
    deinit {
        if self.mainPicker != nil {
            self.mainPicker.selectedDataArray.removeAll()
        }
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
}

extension LGMPAlbumDetailController: UICollectionViewDataSource, UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if self.allowTakePhoto {
            return self.dataArray.count + 1
        } else {
            return self.dataArray.count
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        if self.allowTakePhoto {
            if (self.configs.sortBy == .ascending && indexPath.row == self.dataArray.count) ||
                (self.configs.sortBy == .descending && indexPath.row == 0)
            {
                var cell: LGMPAlbumDetailCameraCell
                if let temp = collectionView.dequeueReusableCell(withReuseIdentifier: Reuse.cameraCell,
                                                                 for: indexPath) as? LGMPAlbumDetailCameraCell
                {
                    cell = temp
                } else {
                    cell = LGMPAlbumDetailCameraCell(frame: CGRect.zero)
                }
                cell.cornerRadius = configs.cellCornerRadius
                if configs.isShowCaptureImageOnTakePhotoButton {
                    DispatchQueue.main.after(0.3) {
                        cell.startCapture()
                    }
                }
                return cell
            }
        }
        
        var cell: LGMPAlbumDetailImageCell
        if let temp = collectionView.dequeueReusableCell(withReuseIdentifier: Reuse.imageCell, for: indexPath)
            as? LGMPAlbumDetailImageCell {
            cell = temp
        } else {
            cell = LGMPAlbumDetailImageCell(frame: CGRect.zero)
        }
        
        var dataModel: LGPhotoModel
        if !self.allowTakePhoto || configs.sortBy == .ascending {
            dataModel = self.dataArray[indexPath.row]
        } else {
            dataModel = self.dataArray[indexPath.row - 1]
        }
        
        cell.listModel = dataModel
        weak var weakCell = cell
        cell.selectedBlock = { [weak self] (isSelected) in
            guard let weakSelf = self else { return }
            guard let weakCell = weakCell else { return }
            if !isSelected {
                if weakSelf.canSelectModel(dataModel) {
                    dataModel.isSelected = true
                    weakSelf.mainPicker.selectedDataArray.append(dataModel)
                    weakSelf.selectedIndexPath.append(indexPath)
                    weakCell.selectButton.isSelected = true
                }
            } else {
                weakCell.selectButton.isSelected = false
                dataModel.isSelected = false
                if let index = weakSelf.mainPicker.selectedDataArray.index(where: { (temp) -> Bool in
                    temp.asset.localIdentifier == dataModel.asset.localIdentifier
                }) {
                    dataModel.currentSelectedIndex = -1
                    weakSelf.mainPicker.selectedDataArray.remove(at: index)
                }
            }
           
            if weakSelf.configs.isShowSelectedMask {
                weakCell.coverView.isHidden = !dataModel.isSelected
            }
            
            if dataModel.currentSelectedIndex == -1 {
                weakCell.selectButton.setTitle(nil,
                                               for: UIControl.State.normal)
            } else {
                weakCell.selectButton.setTitle("\(dataModel.currentSelectedIndex)",
                                               for: UIControl.State.normal)
            }
            weakSelf.refreshSelectedIndexsLayout()
            weakSelf.refreshBottomBarStatus()
        }
        return cell
    }
    
    func canSelectModel(_ model: LGPhotoModel) -> Bool {
        if mainPicker.selectedDataArray.count >= configs.maxSelectCount {
            let tipsString = String(format: LGLocalizedString("Select a maximum of %d photos."),
                                    configs.maxSelectCount)
            LGStatusBarTips.show(withStatus: tipsString,
                                 style: LGStatusBarConfig.Style.error)
            return false
        }
        
        if mainPicker.selectedDataArray.count > 0 {
            if let selectedModel = mainPicker.selectedDataArray.first {
                if !configs.allowMixSelect && model.type != selectedModel.type {
                    let tipsString = LGLocalizedString("Can't select photos and videos at the same time.")
                    LGStatusBarTips.show(withStatus: tipsString,
                                         style: LGStatusBarConfig.Style.error)
                    return false
                }
            }
        }
        
        return true
    }

    var isSelecteOriginalPhoto: Bool {
        return bottomToolBar.originalPhotoButton.isSelected
    }
    
    func refreshBottomBarStatus() {
        if mainPicker.selectedDataArray.count > 0 {
            bottomToolBar.previewButton.isEnabled = true
            bottomToolBar.originalPhotoButton.isEnabled = true
            bottomToolBar.doneButton.isEnabled = true
            bottomToolBar.doneButton.setTitle(LGLocalizedString("Done") + "(\(mainPicker.selectedDataArray.count))",
                                               for: UIControl.State.normal)
            layoutPhotosBytes()
        } else {
            bottomToolBar.previewButton.isEnabled = false
            bottomToolBar.originalPhotoButton.isEnabled = false
            bottomToolBar.originalPhotoButton.isSelected = false
            bottomToolBar.photoBytesLabel.text = ""
            bottomToolBar.doneButton.isEnabled = false
            bottomToolBar.doneButton.setTitle(LGLocalizedString("Done"), for: UIControl.State.normal)
        }
    }
    
    func layoutPhotosBytes() {
        
        if isSelecteOriginalPhoto {
            DispatchQueue.background.async { [weak self] in
                guard let weakSelf = self else {return}
                if let photoModel = weakSelf.mainPicker.selectedDataArray.last, photoModel.isICloudAsset {
                    DispatchQueue.main.async { [weak self] in
                        guard let weakSelf = self else {return}
                        weakSelf.bottomToolBar.photoBytesLabel.text = "    "
                        weakSelf.bottomToolBar.photoBytesIndicatorView.startAnimating()
                    }
                    LGPhotoManager.getPhotoBytes(withPhotos: weakSelf.mainPicker.selectedDataArray)
                    { (mbFormatString, originalLength) in
                        DispatchQueue.main.async { [weak self] in
                            guard let weakSelf = self else {return}
                            weakSelf.bottomToolBar.photoBytesIndicatorView.stopAnimating()
                            weakSelf.bottomToolBar.photoBytesLabel.text = String(format: "(%@)", mbFormatString)
                            weakSelf.bottomToolBar.photoBytesLabel.sizeToFit()
                        }
                    }
                } else {
                    LGPhotoManager.getPhotoBytes(withPhotos: weakSelf.mainPicker.selectedDataArray)
                    { (mbFormatString, originalLength) in
                        DispatchQueue.main.async { [weak self] in
                            guard let weakSelf = self else {return}
                            weakSelf.bottomToolBar.photoBytesIndicatorView.stopAnimating()
                            weakSelf.bottomToolBar.photoBytesLabel.text = String(format: "(%@)", mbFormatString)
                            weakSelf.bottomToolBar.photoBytesLabel.sizeToFit()
                        }
                    }
                }
            }
        } else {
            self.bottomToolBar.photoBytesLabel.text = ""
        }
    }
    
    func refreshSelectedIndexsLayout() {
        var indexs: [IndexPath] = []
        
        for tempModel in mainPicker.selectedDataArray {
            if let index = dataArray.index(where: { (temp) -> Bool in
                tempModel.asset.localIdentifier == temp.asset.localIdentifier
            }) {
                if !self.allowTakePhoto || self.configs.sortBy == .ascending {
                    indexs.append(IndexPath(row: index, section: 0))
                } else {
                    indexs.append(IndexPath(row: index - 1, section: 0))
                }
                
            }
            
            if let index = mainPicker.selectedDataArray.index(where: { (temp) -> Bool in
                tempModel.asset.localIdentifier == temp.asset.localIdentifier
            }) {
                tempModel.currentSelectedIndex = index + 1
            }
            
            self.listView.reloadItems(at: indexs)
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        preview(with: indexPath.row)
    }

}

extension LGMPAlbumDetailController: LGForceTouchPreviewingDelegate {
    public func previewingContext(_ previewingContext: LGForceTouchPreviewingContext,
                           viewControllerForLocation location: CGPoint) -> UIViewController?
    {
        guard let indexPath = self.listView.indexPathForItem(at: location) else { return nil }
        guard let cell = self.listView.cellForItem(at: indexPath) as? LGMPAlbumDetailImageCell else { return nil }
        
        previewingContext.sourceRect = cell.frame
        
        var index = indexPath.row
        if self.allowTakePhoto && configs.sortBy != .ascending {
            index = indexPath.row - 1
        }
        
        let model = self.dataArray[index]
        let mediaModel = model.asLGMediaModel()
        mediaModel.thumbnailImage = cell.layoutImageView.image
        
        let previewVC = LGForceTouchPreviewController(mediaModel: mediaModel,
                                                      currentIndex: indexPath.row)
        previewVC.currentIndex = indexPath.row
        previewVC.preferredContentSize = getSizeWith(photoModel: model)
        return previewVC
    }
    
    public func previewingContext(_ previewingContext: LGForceTouchPreviewingContext,
                           commitViewController viewControllerToCommit: UIViewController)
    {
        guard let previewController = viewControllerToCommit as? LGForceTouchPreviewController else {return}
        preview(with: previewController.currentIndex)
    }

    func getSizeWith(photoModel: LGPhotoModel) -> CGSize {
        var width = min(CGFloat(photoModel.asset.pixelWidth),
                        self.view.lg_width)
        var height = width * CGFloat(photoModel.asset.pixelHeight) / CGFloat(photoModel.asset.pixelWidth)
        
        if height.isNaN { return CGSize.zero }

        if height > self.view.lg_height {
            height = self.view.lg_height
            width = height * CGFloat(photoModel.asset.pixelWidth) / CGFloat(photoModel.asset.pixelHeight)
        }
        
        return CGSize(width: width, height: height)
    }
}

extension LGMPAlbumDetailController: PHPhotoLibraryChangeObserver {
    public func photoLibraryDidChange(_ changeInstance: PHChange) {
        DispatchQueue.main.async { [weak self] in
            guard let weakSelf = self else { return }
            NSObject.cancelPreviousPerformRequests(withTarget: weakSelf)
            weakSelf.perform(#selector(LGMPAlbumDetailController.changeAndReload(_:)),
                         with: changeInstance,
                         afterDelay: 0.3)
        }
    }
    
    @objc func changeAndReload(_ changeInstance: PHChange) {
        guard let result = self.albumListModel?.result else { return }
        if let detail = changeInstance.changeDetails(for: result) {
            
            let photos = LGPhotoManager.fetchPhoto(inResult: detail.fetchResultAfterChanges,
                                                   supportMediaType: configs.resultMediaTypes)
//            self.dataArray.removeAll()
//            self.dataArray += photos
//            self.listView.reloadData()
//            self.cachingImages()
//            self.scrollToBottom()
        }
    }
}

extension LGMPAlbumDetailController: LGMediaBrowserDataSource {
    public func numberOfPhotosInPhotoBrowser(_ photoBrowser: LGMediaBrowser) -> Int {
        return self.dataArray.count
    }
    
    public func photoBrowser(_ photoBrowser: LGMediaBrowser, photoAtIndex index: Int) -> LGMediaModel {
        var thumbnailImage: UIImage?
        if let cell = self.listView.cellForItem(at: IndexPath(row: index, section: 0)) as? LGMPAlbumDetailImageCell {
            thumbnailImage = cell.layoutImageView.image
        }
        var dataModel: LGPhotoModel
        if !self.allowTakePhoto || configs.sortBy == .ascending {
            dataModel = self.dataArray[index]
        } else {
            dataModel = self.dataArray[index - 1]
        }
        let mediaModel = dataModel.asLGMediaModel()
        mediaModel.thumbnailImage = thumbnailImage
        return mediaModel
    }
}

extension LGMPAlbumDetailController: LGMediaBrowserDelegate {
    public func viewForMedia(_ browser: LGMediaBrowser, index: Int) -> UIView? {
        self.listView.layoutIfNeeded()
        return self.listView.cellForItem(at: IndexPath(row: index, section: 0))
    }
    
    public func didScrollToIndex(_ browser: LGMediaBrowser, index: Int) {
        self.listView.layoutIfNeeded()
        if let tempCell = self.listView.cellForItem(at: IndexPath(row: index, section: 0)) {
            if self.listView.frame.contains(tempCell.convert(tempCell.bounds, to: self.view)) {
                
            } else {
                self.listView.scrollToItem(at: IndexPath(row: index, section: 0),
                                           at: UICollectionView.ScrollPosition.centeredVertically,
                                           animated: true)
            }
        }
    }
}


extension LGMPAlbumDetailController: LGMPAlbumDetailBottomToolBarDelegate {
    public func position(for bar: UIBarPositioning) -> UIBarPosition {
        return UIBarPosition.bottom
    }
    
    func previewButtonPressed(_ button: UIButton) {
        preview(with: self.selectedIndexPath.last?.row ?? 0)
    }
    
    func originalButtonPressed(_ button: UIButton) {
        layoutPhotosBytes()
    }
    
    func doneButtonPressed(_ button: UIButton) {
        mainPicker.pickerDelegate?.picker(mainPicker,
                                          didDoneWith: mainPicker.selectedDataArray,
                                          isOriginalPhoto: bottomToolBar.originalPhotoButton.isSelected)
    }
    
    func preview(with index: Int) {
        var configs = LGMediaBrowserSettings()
        configs.isClickToTurnOffEnabled = false
        configs.showsStatusBar = true
        configs.showsNavigationBar = true
        let mediaBrowser = LGCheckMediaBrowser(dataSource: self,
                                               configs: configs,
                                               status: .checkMedia,
                                               currentIndex: index)
        mediaBrowser.delegate = self
        mediaBrowser.checkMediaCallBack = self
        self.navigationController?.pushViewController(mediaBrowser, animated: true)
    }
}

extension LGMPAlbumDetailController: LGCheckMediaBrowserCallBack {
    func checkMedia(_ browser: LGCheckMediaBrowser, withIndex index: Int, isSelected: Bool) -> Bool {
        var dataModel: LGPhotoModel
        if !self.allowTakePhoto || configs.sortBy == .ascending {
            dataModel = self.dataArray[index]
        } else {
            dataModel = self.dataArray[index - 1]
        }
        
        if isSelected {
            if canSelectModel(dataModel) {
                dataModel.isSelected = true
                self.mainPicker.selectedDataArray.append(dataModel)
                let indexPath = IndexPath(row: index, section: 0)
                self.selectedIndexPath.append(indexPath)
                refreshSelectedIndexsLayout()
                return true
            } else {
                return false
            }
        } else {
            dataModel.isSelected = false
            if let index = self.mainPicker.selectedDataArray.index(where: { (temp) -> Bool in
                temp.asset.localIdentifier == dataModel.asset.localIdentifier
            }) {
                dataModel.currentSelectedIndex = -1
                self.mainPicker.selectedDataArray.remove(at: index)
            }
            self.listView.reloadItems(at: [IndexPath(row: index, section: 0)])
            refreshSelectedIndexsLayout()
            return true
        }
    }
    
    func checkMedia(_ browser: LGCheckMediaBrowser, didDoneWith photoList: [LGPhotoModel]) {
        mainPicker.pickerDelegate?.picker(mainPicker,
                                          didDoneWith: mainPicker.selectedDataArray,
                                          isOriginalPhoto: bottomToolBar.originalPhotoButton.isSelected)
    }
}

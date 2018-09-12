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
    
    lazy var bottomBar: LGMPAlbumDetailBottomBar = {
       let temp = LGMPAlbumDetailBottomBar(frame: CGRect(x: 0.0,
                                                         y: self.view.lg_height - UIDevice.bottomSafeMargin - 44.0,
                                                         width: self.view.lg_width,
                                                         height: 44.0))
        temp.delegate = self
        return temp
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

    override public func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setupListCollectionView()
        
        setupCancel()
        
        fetchDataIfNeeded()
        
        self.view.addSubview(bottomBar)
        
        PHPhotoLibrary.shared().register(self)
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
        
        if configs.allowForceTouch, isForceTouchAvailable {
            if #available(iOS 9.0, *) {
                self.registerForPreviewing(with: self, sourceView: collectionView)
            } else {
            }
        }
    }
    
    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        self.listView.frame = CGRect(x: 0,
                                     y: 0,
                                     width: self.view.lg_width,
                                     height: self.view.lg_height - 44.0 - UIDevice.bottomSafeMargin)
        bottomBar.frame = CGRect(x: 0.0,
                                 y: self.view.lg_height - UIDevice.bottomSafeMargin - 44.0,
                                 width: self.view.lg_width,
                                 height: 44.0)
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.scrollToBottom()
    }
    
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
                            where selectedTemp.asset.localIdentifier == temp.asset.localIdentifier {
                            temp.isSelected = true
                        }
                    }
                    weakSelf.dataArray += album.models
                    DispatchQueue.main.async { [weak self] in
                        hud.dismiss()
                        guard let weakSelf = self else { return }
                        weakSelf.title = album.title
                        weakSelf.listView.reloadData()
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
        
        var row = self.dataArray.count - 1
        if self.allowTakePhoto {
            row += 1
        }
        
        let lastIndexPath = IndexPath(row: row, section: 0)
        
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
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if self.allowTakePhoto {
            if (self.configs.sortBy == .ascending && indexPath.row == self.dataArray.count) ||
                (self.configs.sortBy == .descending && indexPath.row == 0)
            {
                var cell: LGMPAlbumDetailCameraCell
                if let temp = collectionView.dequeueReusableCell(withReuseIdentifier: Reuse.cameraCell, for: indexPath)
                    as? LGMPAlbumDetailCameraCell {
                    cell = temp
                } else {
                    cell = LGMPAlbumDetailCameraCell(frame: CGRect.zero)
                }
                cell.cornerRadius = configs.cellCornerRadius
                if configs.isShowCaptureImageOnTakePhotoBtn {
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
        return self.bottomBar.originalPhotoButton.isSelected
    }
    
    func refreshBottomBarStatus() {
        if mainPicker.selectedDataArray.count > 0 {
            self.bottomBar.previewButton.isEnabled = true
            self.bottomBar.originalPhotoButton.isEnabled = true
            self.bottomBar.doneButton.isEnabled = true
            self.bottomBar.doneButton.setTitle(LGLocalizedString("Done") + "(\(mainPicker.selectedDataArray.count))",
                                               for: UIControl.State.normal)
            layoutPhotosBytes()
        } else {
            self.bottomBar.previewButton.isEnabled = false
            self.bottomBar.originalPhotoButton.isEnabled = false
            self.bottomBar.originalPhotoButton.isSelected = false
            self.bottomBar.photoBytesLabel.text = ""
            self.bottomBar.doneButton.isEnabled = false
            self.bottomBar.doneButton.setTitle(LGLocalizedString("Done"), for: UIControl.State.normal)
        }
    }
    
    func layoutPhotosBytes() {
        if isSelecteOriginalPhoto {
            LGPhotoManager.getPhotoBytes(withPhotos: mainPicker.selectedDataArray)
            { (mbFormatString, originalLength) in
                DispatchQueue.main.async { [weak self] in
                    self?.bottomBar.photoBytesLabel.text = String(format: "(%@)", mbFormatString)
                }
            }
        } else {
            self.bottomBar.photoBytesLabel.text = ""
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

}

extension LGMPAlbumDetailController: UIViewControllerPreviewingDelegate {
    @available(iOS 9.0, *)
    public func previewingContext(_ previewingContext: UIViewControllerPreviewing,
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
        
        func assetTypeToMediaType(_ type: LGPhotoModel.AssetMediaType) -> LGMediaModel.MediaType {
            switch type {
            case .unknown:
                return .other
            case .generalImage:
                return .generalPhoto
            case .livePhoto:
                return .livePhoto
            case .video:
                return .video
            case .audio:
                return .audio
            default:
                return .other
            }
        }

        let mediaModel = LGMediaModel(thumbnailImageURL: nil,
                                      mediaURL: nil,
                                      mediaAsset: model.asset,
                                      mediaType: assetTypeToMediaType(model.type),
                                      mediaPosition: LGMediaModel.Position.album,
                                      thumbnailImage: cell.layoutImageView.image)
        
        let previewVC = LGForceTouchPreviewController(mediaModel: mediaModel,
                                                      currentIndex: indexPath.row)
        previewVC.preferredContentSize = getSizeWith(photoModel: model)
        return previewVC

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
    
    @available(iOS 9.0, *)
    public func previewingContext(_ previewingContext: UIViewControllerPreviewing,
                                  commit viewControllerToCommit: UIViewController)
    {
        return
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
            self.dataArray.removeAll()
            self.dataArray += photos
            self.listView.reloadData()
            self.cachingImages()
            self.scrollToBottom()
        }
    }
}

extension LGMPAlbumDetailController: LGMPAlbumDetailBottomBarDelegate {
    public func previewButtonPressed(_ button: UIButton) {
        
    }
    
    public func originalButtonPressed(_ button: UIButton) {
        layoutPhotosBytes()
    }
    
    public func doneButtonPressed(_ button: UIButton) {
        
    }
}

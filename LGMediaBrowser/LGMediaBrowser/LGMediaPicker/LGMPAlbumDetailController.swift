//
//  LGMPAlbumDetailController.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/6/25.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import UIKit
import Photos
import TOCrop

public class LGMPAlbumDetailController: LGMPBaseViewController {
    weak var listView: UICollectionView!
    
    var albumListModel: LGAlbumListModel?
    
    var dataArray: [LGPhotoModel] = []
    
    var selectedIndexPath: [IndexPath] = []
    
    weak var delegate: LGMediaPickerDelegate?
    
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
    
    
    var configs: LGMediaPicker.Configuration!
    
    lazy var bottomToolBar: LGMPAlbumDetailBottomToolBar = {
        let temp = LGMPAlbumDetailBottomToolBar(frame: CGRect(x: 0,
                                                              y: 0,
                                                              width: LGMesurement.screenWidth,
                                                              height: 44.0))
        temp.barDelegate = self
        return temp
    }()
    
    private var isFullDatasourcePreview: Bool = true
    
    private var tempSelectedPhotosArray: [LGPhotoModel] = []
    
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
        
        bottomToolBar.originalPhotoButton.isHidden = !configs.allowSelectOriginal
        bottomToolBar.originalPhotoButton.isSelected = configs.allowSelectOriginal
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
        if globleSelectedDataArray == nil {
            globleSelectedDataArray = []
        }
        if self.dataArray.count == 0 || needRefresh {
            let hud = LGLoadingHUD.show(inView: self.view)
            if let albumListModel = albumListModel {
                if needRefresh {
                    guard let result = albumListModel.result else { return }
                    let photos = LGPhotoManager.fetchPhoto(inResult: result,
                                                           supportTypes: self.configs.resultMediaTypes)
                    for temp in photos {
                        for selectedTemp in globleSelectedDataArray
                            where selectedTemp.asset.localIdentifier == temp.asset.localIdentifier {
                                temp.isSelected = true
                                temp.currentSelectedIndex = selectedTemp.currentSelectedIndex
                        }
                    }
                    self.dataArray.removeAll()
                    self.dataArray += photos
                    self.listView.reloadData()
                } else {
                    let photos = albumListModel.models
                    for temp in albumListModel.models {
                        for selectedTemp in globleSelectedDataArray
                            where selectedTemp.asset.localIdentifier == temp.asset.localIdentifier {
                                temp.isSelected = true
                                temp.currentSelectedIndex = selectedTemp.currentSelectedIndex
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
                    if let album = LGPhotoManager.getAllPhotosAlbum(weakSelf.configs.resultMediaTypes) {
                        weakSelf.albumListModel = album
                        weakSelf.dataArray.removeAll()
                        for temp in album.models {
                            for selectedTemp in globleSelectedDataArray
                                where selectedTemp.asset.localIdentifier == temp.asset.localIdentifier
                            {
                                temp.isSelected = true
                                temp.currentSelectedIndex = selectedTemp.currentSelectedIndex
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
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
        NSObject.cancelPreviousPerformRequests(withTarget: self)
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
                        //                        cell.startCapture()
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
        
        cell.isShowSelectButton = self.configs.maxSelectCount != 1
        
        cell.listModel = dataModel
        weak var weakCell = cell
        cell.selectedBlock = { [weak self] (isSelected) in
            guard let weakSelf = self else { return }
            guard let weakCell = weakCell else { return }
            
            func forceReload() {
                weakCell.selectButton.isUserInteractionEnabled = true
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
            
            
            if !isSelected {
                weakCell.selectButton.isUserInteractionEnabled = false
                weakSelf.canSelectModel(dataModel, callback: { (canSelecte) in
                    if canSelecte {
                        dataModel.isSelected = true
                        globleSelectedDataArray.append(dataModel)
                        weakSelf.selectedIndexPath.append(indexPath)
                        weakCell.selectButton.isSelected = true
                    }
                    
                    forceReload()
                })
            } else {
                weakCell.selectButton.isSelected = false
                dataModel.isSelected = false
                if let index = globleSelectedDataArray.index(where: { (temp) -> Bool in
                    temp.asset.localIdentifier == dataModel.asset.localIdentifier
                }) {
                    dataModel.currentSelectedIndex = -1
                    globleSelectedDataArray.remove(at: index)
                }
                
                forceReload()
            }
        }
        return cell
    }
    
    func canSelectModel(_ model: LGPhotoModel, callback: @escaping (Bool) -> Void) {
        if globleSelectedDataArray.count >= configs.maxSelectCount {
            let tipsString = String(format: LGLocalizedString("Select maximum of %d photos."),
                                    configs.maxSelectCount)
            LGStatusBarTips.show(withStatus: tipsString,
                                 style: LGStatusBarConfig.Style.error)
            callback(false)
            return
        }
        
        if globleSelectedDataArray.count > 0 {
            if let selectedModel = globleSelectedDataArray.first {
                if !configs.allowMixSelect && model.type != selectedModel.type {
                    let tipsString = LGLocalizedString("Can't select photos and videos at the same time.")
                    LGStatusBarTips.show(withStatus: tipsString,
                                         style: LGStatusBarConfig.Style.error)
                    callback(false)
                    return
                }
            }
        }
        
        model.isICloudAsset({ [weak self] (isICloudAsset) in
            guard let weakSelf = self else {return}
            if isICloudAsset && weakSelf.isSelecteOriginalPhoto {
                let tipsString = LGLocalizedString("iCloud synchronization.")
                LGStatusBarTips.show(withStatus: tipsString,
                                     style: LGStatusBarConfig.Style.error)
                callback(false)
            } else {
                callback(true)
            }
        })
    }
    
    var isSelecteOriginalPhoto: Bool {
        return bottomToolBar.originalPhotoButton.isSelected
    }
    
    func refreshBottomBarStatus() {
        if globleSelectedDataArray.count > 0 {
            bottomToolBar.previewButton.isEnabled = true
            bottomToolBar.doneButton.isEnabled = true
            bottomToolBar.doneButton.setTitle(LGLocalizedString("Done") + "(\(globleSelectedDataArray.count))",
                for: UIControl.State.normal)
            layoutPhotosBytes()
        } else {
            bottomToolBar.previewButton.isEnabled = false
            bottomToolBar.photoBytesLabel.text = ""
            bottomToolBar.doneButton.isEnabled = false
            bottomToolBar.doneButton.setTitle(LGLocalizedString("Done"), for: UIControl.State.normal)
        }
    }
    
    func layoutPhotosBytes() {
        if isSelecteOriginalPhoto {
            if let photoModel = globleSelectedDataArray.last {
                photoModel.isICloudAsset { [weak self] (isICloudAsset) in
                    guard let weakSelf = self else {return}
                    if isICloudAsset {
                        weakSelf.bottomToolBar.photoBytesLabel.text = "  "
                        weakSelf.bottomToolBar.photoBytesIndicatorView.startAnimating()
                    }
                    LGPhotoManager.getPhotoBytes(withPhotos: globleSelectedDataArray)
                    { (mbFormatString, originalLength) in
                        DispatchQueue.main.async { [weak self] in
                            guard let weakSelf = self else {return}
                            weakSelf.bottomToolBar.photoBytesIndicatorView.stopAnimating()
                            weakSelf.bottomToolBar.photoBytesLabel.text = String(format: "(%@)", mbFormatString)
                        }
                    }
                }
            } else {
                self.bottomToolBar.photoBytesIndicatorView.stopAnimating()
                self.bottomToolBar.photoBytesLabel.text = ""
            }
        } else {
            self.bottomToolBar.photoBytesIndicatorView.stopAnimating()
            self.bottomToolBar.photoBytesLabel.text = ""
        }
    }
    
    func refreshSelectedIndexsLayout() {
        var indexs: [IndexPath] = []
        
        for tempModel in globleSelectedDataArray {
            if let index = dataArray.index(where: { (temp) -> Bool in
                tempModel.asset.localIdentifier == temp.asset.localIdentifier
            }) {
                if !self.allowTakePhoto || self.configs.sortBy == .ascending {
                    indexs.append(IndexPath(row: index, section: 0))
                } else {
                    indexs.append(IndexPath(row: index + 1, section: 0))
                }
                
            }
            
            if let index = globleSelectedDataArray.index(where: { (temp) -> Bool in
                tempModel.asset.localIdentifier == temp.asset.localIdentifier
            }) {
                tempModel.currentSelectedIndex = index + 1
            }
        }
        
        self.listView.reloadItems(at: indexs)
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        if !self.allowTakePhoto || self.configs.sortBy == .ascending {
            if indexPath.row == self.dataArray.count {
                if let cell = collectionView.cellForItem(at: indexPath) as? LGMPAlbumDetailCameraCell {
                    cell.stopCapture()
                }
                checkCapturePermissionAndOpen()
                return
            } else {
                if self.configs.maxSelectCount == 1,
                    let cell = collectionView.cellForItem(at: indexPath) as? LGMPAlbumDetailImageCell,
                    let mediaModel = cell.listModel?.asLGMediaModel()
                {
                    let hud = LGLoadingHUD.show()
                    LGMediaModelFetchManager.default.fetchResult(withMediaModel: mediaModel,
                                                                 imageCompletion:
                        { [weak self] (resultImage, isFinished, error) in
                            guard let weakSelf = self, let resultImage = resultImage, isFinished == true else {return}
                            hud.dismiss()
                            weakSelf.checkAndCropImage(resultImage)
                    })
                    return
                } else {
                }
            }
        } else {
            if indexPath.row == 0 {
                if let cell = collectionView.cellForItem(at: indexPath) as? LGMPAlbumDetailCameraCell {
                    cell.stopCapture()
                }
                checkCapturePermissionAndOpen()
                return
            } else {
                if self.configs.maxSelectCount == 1,
                    let cell = collectionView.cellForItem(at: indexPath) as? LGMPAlbumDetailImageCell,
                    let mediaModel = cell.listModel?.asLGMediaModel()
                {
                    
                    let hud = LGLoadingHUD.show()
                    LGMediaModelFetchManager.default.fetchResult(withMediaModel: mediaModel,
                                                                 imageCompletion:
                        { [weak self] (resultImage, isFinished, error) in
                            guard let weakSelf = self, let resultImage = resultImage else {return}
                            hud.dismiss()
                            weakSelf.checkAndCropImage(resultImage)
                    })
                } else {
                }
            }
        }
        preview(with: indexPath.row)
    }
    
    
    
    func checkAndCropImage(_ image: UIImage) {
        let crop = TOCropViewController(image: image)
        crop.customAspectRatio = CGSize(width: 2, height: 3)
        crop.aspectRatioLockEnabled = true
        crop.resetButtonHidden = true
        crop.aspectRatioPickerButtonHidden = true
        crop.rotateButtonsHidden = true
        crop.delegate = self
        self.navigationController?.pushViewController(crop, animated: true)
    }
    
    func checkCapturePermissionAndOpen() {
        if configs.allowRecordVideo {
            do {
                let cameraStatus = try LGAuthorizationStatusManager.default.status(withPrivacyType: .camera)
                switch cameraStatus {
                case .notDetermined:
                    try LGAuthorizationStatusManager.default.requestPrivacy(withType: .camera)
                    { [weak self] (type, status) in
                        switch type {
                        case .camera:
                            guard let weakSelf = self else {return}
                            weakSelf.checkCapturePermissionAndOpen()
                            break
                        default:
                            break
                        }
                    }
                    break
                case .denied, .restricted:
                    showPermissionController(withType: .camera)
                    break
                case .authorized:
                    checkMicrophonePermissionAndOpen()
                    break
                case .unSupport:
                    break
                }
            } catch {
                LGStatusBarTips.show(withStatus: error.localizedDescription,
                                     style: LGStatusBarConfig.Style.error)
            }
        } else {
            do {
                let cameraStatus = try LGAuthorizationStatusManager.default.status(withPrivacyType: .camera)
                switch cameraStatus {
                case .notDetermined:
                    try LGAuthorizationStatusManager.default.requestPrivacy(withType: .camera)
                    { [weak self] (type, status) in
                        switch type {
                        case .camera:
                            guard let weakSelf = self else {return}
                            weakSelf.checkCapturePermissionAndOpen()
                            break
                        default:
                            break
                        }
                    }
                    break
                case .denied, .restricted:
                    showPermissionController(withType: .camera)
                    break
                case .authorized:
                    intoCaptureController()
                    break
                case .unSupport:
                    break
                }
            } catch {
                LGStatusBarTips.show(withStatus: error.localizedDescription,
                                     style: LGStatusBarConfig.Style.error)
            }
        }
    }
    
    func checkMicrophonePermissionAndOpen() {
        do {
            let microphoneStatus = try LGAuthorizationStatusManager.default.status(withPrivacyType: .microphone)
            switch microphoneStatus {
            case .notDetermined:
                try LGAuthorizationStatusManager.default.requestPrivacy(withType: .microphone)
                { [weak self] (type, status) in
                    switch type {
                    case .microphone:
                        guard let weakSelf = self else {return}
                        weakSelf.checkMicrophonePermissionAndOpen()
                        break
                    default:
                        break
                    }
                }
                break
            case .denied, .restricted:
                showPermissionController(withType: .microphone)
                break
            case .authorized:
                intoCaptureController()
                break
            case .unSupport:
                break
            }
        } catch {
            LGStatusBarTips.show(withStatus: error.localizedDescription,
                                 style: LGStatusBarConfig.Style.error)
        }
    }
    
    func intoCaptureController() {
        if globleSelectedDataArray.count >= configs.maxSelectCount {
            let tipsString = String(format: LGLocalizedString("Select maximum of %d photos."),
                                    configs.maxSelectCount)
            LGStatusBarTips.show(withStatus: tipsString,
                                 style: LGStatusBarConfig.Style.error)
            return
        }
        
        let capture = LGCameraCapture()
        capture.delegate = self
        capture.allowRecordVideo = false
        
        if let outputSize = configs.clipRatios.first, configs.maxSelectCount == 1 {
            capture.outputSize = outputSize
        }
        
        self.navigationController?.pushViewController(capture, animated: true)
    }
    
    func showPermissionController(withType type: LGUnauthorizedController.UnauthorizedType) {
        let tipsCon = LGUnauthorizedController()
        tipsCon.unauthorizedType = type
        self.navigationController?.pushViewController(tipsCon, animated: true)
    }
}

extension LGMPAlbumDetailController: LGCameraCaptureDelegate {
    public func captureDidCancel(_ capture: LGCameraCapture) {
        self.navigationController?.popToViewController(self, animated: true)
    }
    
    public func captureDidCapturedResult(_ result: LGCameraCapture.ResultModel, capture: LGCameraCapture) {
        switch result.type {
        case .photo:
            let hud = LGLoadingHUD.show()
            result.image?.lg_savetoAlbumWith(completionBlock: { [weak self] (isSucceed, asset, error) in
                guard let weakSelf = self else {return}
                if isSucceed, let asset = asset {
                    let photoModel = LGPhotoModel(asset: asset,
                                                  type: LGPhotoModel.AssetMediaType.generalImage,
                                                  duration: "")
                    globleSelectedDataArray.append(photoModel)
                    weakSelf.delegate?.picker(globleMainPicker,
                                     didDoneWith: globleSelectedDataArray,
                                     isOriginalPhoto: true)
                } else {
                    LGStatusBarTips.show(withStatus: error?.localizedDescription ?? "Unknown error",
                                         style: LGStatusBarConfig.Style.error)
                }
                hud.dismiss()
            })
            break
        case .video:
            guard let videoURL = result.videoURL else {return}
            var localId: String?
            let hud = LGLoadingHUD.show()
            PHPhotoLibrary.shared().performChanges({
                let request = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
                localId = request?.placeholderForCreatedAsset?.localIdentifier
            }) { (isSucceed, error) in
                DispatchQueue.main.async { [weak self] in
                    guard let weakSelf = self else {return}
                    if isSucceed {
                        if let localId = localId {
                            let result = PHAsset.fetchAssets(withLocalIdentifiers: [localId], options: nil)
                            if let asset = result.firstObject {
                                let photoModel = LGPhotoModel(asset: asset,
                                                              type: LGPhotoModel.AssetMediaType.generalImage,
                                                              duration: "")
                                globleSelectedDataArray.append(photoModel)
                                weakSelf.delegate?.picker(globleMainPicker,
                                                          didDoneWith: globleSelectedDataArray,
                                                          isOriginalPhoto: true)
                            }
                        }
                    } else {
                        LGStatusBarTips.show(withStatus: error?.localizedDescription ?? "Unknown error",
                                             style: LGStatusBarConfig.Style.error)
                    }
                    hud.dismiss()
                }
            }
            break
        }
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
        preview(with: previewController.currentIndex, animated: false)
    }
    
    func getSizeWith(photoModel: LGPhotoModel) -> CGSize {
        let width = min(CGFloat(photoModel.asset.pixelWidth),
                        self.view.lg_width)
        let height = width * CGFloat(photoModel.asset.pixelHeight) / CGFloat(photoModel.asset.pixelWidth)
        
        if height.isNaN { return CGSize.zero }
        
        return calcFinalImageSize(CGSize(width: width, height: height))
    }
    
    func calcFinalImageSize(_ finalImageSize: CGSize) -> CGSize {
        let width = UIScreen.main.bounds.width
        let height = UIScreen.main.bounds.height
        let imageWidth = finalImageSize.width
        var imageHeight = finalImageSize.height
        
        var resultWidth: CGFloat
        var resultHeight: CGFloat
        imageHeight = width / imageWidth * imageHeight
        if imageHeight > height {
            resultWidth = height / finalImageSize.height * imageWidth
            resultHeight = height
        } else {
            resultWidth = width
            resultHeight = imageHeight
        }
        return CGSize(width: resultWidth, height: resultHeight)
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
        
            //            let photos = LGPhotoManager.fetchPhoto(inResult: detail.fetchResultAfterChanges,
            //                                                   supportMediaType: configs.resultMediaTypes)
            //            self.dataArray.removeAll()
            //            self.dataArray += photos
//                        self.listView.reloadData()
            //            self.cachingImages()
            //            self.scrollToBottom()
        }
    }
}

extension LGMPAlbumDetailController: LGMediaBrowserDataSource {
    public func numberOfPhotosInPhotoBrowser(_ photoBrowser: LGMediaBrowser) -> Int {
        if isFullDatasourcePreview {
            return self.dataArray.count
        } else {
            return globleSelectedDataArray.count
        }
    }
    
    public func photoBrowser(_ photoBrowser: LGMediaBrowser, photoAtIndex index: Int) -> LGMediaModel {
        if isFullDatasourcePreview {
            var thumbnailImage: UIImage?
            let indexPath = IndexPath(row: index, section: 0)
            if let cell = self.listView.cellForItem(at: indexPath) as? LGMPAlbumDetailImageCell {
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
        } else {
            let dataModel = globleSelectedDataArray[index]
            let dataIndex = self.dataArray.index(where: { (tempModel) -> Bool in
                return tempModel.asset == dataModel.asset
            })
            
            let mediaModel = dataModel.asLGMediaModel()
            
            if var dataIndex = dataIndex {
                if !self.allowTakePhoto || configs.sortBy == .ascending {
                } else {
                    dataIndex += 1
                }
                
                var thumbnailImage: UIImage?
                let indexPath = IndexPath(row: dataIndex, section: 0)
                if let cell = self.listView.cellForItem(at: indexPath) as? LGMPAlbumDetailImageCell {
                    thumbnailImage = cell.layoutImageView.image
                    mediaModel.thumbnailImage = thumbnailImage
                }
            }
            return mediaModel
        }
    }
}

extension LGMPAlbumDetailController: LGMediaBrowserDelegate {
    public func viewForMedia(_ browser: LGMediaBrowser, index: Int) -> UIView? {
        func fullPreviewTargetView(withIndex dataIndex: Int) -> UIView? {
            self.listView.layoutIfNeeded()
            return self.listView.cellForItem(at: IndexPath(row: dataIndex, section: 0))
        }
        
        if isFullDatasourcePreview {
            return fullPreviewTargetView(withIndex: index)
        } else {
            let dataModel = tempSelectedPhotosArray[index]
            if var dataIndex = self.dataArray.firstIndex(where: { (tempModel) -> Bool in
                return tempModel.asset == dataModel.asset
            })
            {
                if !self.allowTakePhoto || configs.sortBy == .ascending {
                } else {
                    dataIndex += 1
                }
                return fullPreviewTargetView(withIndex: dataIndex)
            } else {
                return nil
            }
        }
    }
    
    public func didScrollToIndex(_ browser: LGMediaBrowser, index: Int) {
        func didScrollTo(dataIndex: Int) {
            self.listView.layoutIfNeeded()
            if let tempCell = self.listView.cellForItem(at: IndexPath(row: dataIndex, section: 0)) {
                if self.listView.frame.contains(tempCell.convert(tempCell.bounds, to: self.view)) {
                    
                } else {
                    self.listView.scrollToItem(at: IndexPath(row: dataIndex, section: 0),
                                               at: UICollectionView.ScrollPosition.centeredVertically,
                                               animated: true)
                }
            }
        }
        
        if isFullDatasourcePreview {
            didScrollTo(dataIndex: index)
        } else {
            let dataModel = tempSelectedPhotosArray[index]
            if var dataIndex = self.dataArray.firstIndex(where: { (tempModel) -> Bool in
                return tempModel.asset == dataModel.asset
            })
            {
                if !self.allowTakePhoto || configs.sortBy == .ascending {
                } else {
                    dataIndex += 1
                }
                didScrollTo(dataIndex: dataIndex)
            } else {
            }
        }
        
    }
}


extension LGMPAlbumDetailController: LGMPAlbumDetailBottomToolBarDelegate {
    public func position(for bar: UIBarPositioning) -> UIBarPosition {
        return UIBarPosition.bottom
    }
    
    func previewButtonPressed(_ button: UIButton) {
        self.tempSelectedPhotosArray = globleSelectedDataArray
        preview(with: 0, isFullDataSource: false)
    }
    
    func originalButtonPressed(_ button: UIButton) {
        layoutPhotosBytes()
    }
    
    func doneButtonPressed(_ button: UIButton) {
        delegate?.picker(globleMainPicker,
                         didDoneWith: globleSelectedDataArray,
                         isOriginalPhoto: bottomToolBar.originalPhotoButton.isSelected)
    }
    
    func preview(with index: Int, animated: Bool = true, isFullDataSource: Bool = true) {
        
        self.isFullDatasourcePreview = isFullDataSource
        
        var configs = LGMediaBrowserSettings()
        configs.isClickToTurnOffEnabled = false
        configs.showsStatusBar = true
        configs.showsNavigationBar = true
        let mediaBrowser = LGCheckMediaBrowser(dataSource: self,
                                               configs: configs,
                                               status: .checkMedia,
                                               currentIndex: index)
        mediaBrowser.pickerConfigs = self.configs
        mediaBrowser.delegate = self
        mediaBrowser.checkMediaCallBack = self
        self.navigationController?.pushViewController(mediaBrowser, animated: animated)
    }
}

extension LGMPAlbumDetailController: LGCheckMediaBrowserCallBack {
    func checkMedia(_ browser: LGCheckMediaBrowser,
                    withIndex index: Int,
                    isSelected: Bool,
                    complete: @escaping (Bool) -> Void)
    {
        func fullCheckWith(_ dataIndex: Int) {
            var dataModel: LGPhotoModel
            if !self.allowTakePhoto || configs.sortBy == .ascending {
                dataModel = self.dataArray[dataIndex]
            } else {
                dataModel = self.dataArray[dataIndex - 1]
            }
            
            if isSelected {
                canSelectModel(dataModel) { [weak self] (canSelect) in
                    if canSelect {
                        dataModel.isSelected = true
                        globleSelectedDataArray.append(dataModel)
                        let indexPath = IndexPath(row: dataIndex, section: 0)
                        guard let weakSelf = self else {
                            complete(false)
                            return
                        }
                        weakSelf.selectedIndexPath.append(indexPath)
                        weakSelf.refreshSelectedIndexsLayout()
                        complete(true)
                    } else {
                        complete(false)
                    }
                }
            } else {
                dataModel.isSelected = false
                if let dataIndex = globleSelectedDataArray.index(where: { (temp) -> Bool in
                    temp.asset.localIdentifier == dataModel.asset.localIdentifier
                }) {
                    dataModel.currentSelectedIndex = -1
                    globleSelectedDataArray.remove(at: dataIndex)
                }
                self.listView.reloadItems(at: [IndexPath(row: dataIndex, section: 0)])
                refreshSelectedIndexsLayout()
                complete(true)
            }
        }
        
        if isFullDatasourcePreview {
            fullCheckWith(index)
        } else {
            let dataModel = globleSelectedDataArray[index]
            if var dataIndex = self.dataArray.firstIndex(where: { (tempModel) -> Bool in
                return tempModel.asset == dataModel.asset
            })
            {
                if !self.allowTakePhoto || configs.sortBy == .ascending {
                } else {
                    dataIndex += 1
                }
                fullCheckWith(dataIndex)
            } else {
                complete(false)
            }
        }
    }
 
    func checkMedia(_ browser: LGCheckMediaBrowser, didDoneWith photoList: [LGPhotoModel]) {
        delegate?.picker(globleMainPicker,
                         didDoneWith: globleSelectedDataArray,
                         isOriginalPhoto: bottomToolBar.originalPhotoButton.isSelected)
    }
}

extension LGMPAlbumDetailController: TOCropViewControllerDelegate {
    public func cropViewController(_ cropViewController: TOCropViewController,
                                   didCropImageTo cropRect: CGRect,
                                   angle: Int)
    {
        UIImage().croppedImage(withFrame: CGRect.zero, angle: 0, circularClip: false)
        self.navigationController?.popViewController(animated: true)
    }
    
    public func cropViewController(_ cropViewController: TOCropViewController,
                                   didFinishCancelled cancelled: Bool)
    {
        self.navigationController?.popViewController(animated: true)
    }
    
    public func cropViewController(_ cropViewController: TOCropViewController,
                                   didCropTo image: UIImage,
                                   with cropRect: CGRect,
                                   angle: Int)
    {
        self.navigationController?.popViewController(animated: true)
    }
    
    public func cropViewController(_ cropViewController: TOCropViewController,
                                   didCropToCircularImage image: UIImage,
                                   with cropRect: CGRect,
                                   angle: Int)
    {
        self.navigationController?.popViewController(animated: true)
    }
}

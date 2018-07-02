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
    
    var selectedDataArray: [LGPhotoModel] = []
    
    var configs: LGMediaPicker.Configuration!
    
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

    override public func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setupListCollectionView()
        
        setupCancel()
    }
    
    func setupCancel() {
        let rightItem = UIBarButtonItem(title: LGLocalizedString("Cancel"),
                                        style: UIBarButtonItemStyle.plain,
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
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchDataIfNeeded()
    }
    
    func fetchDataIfNeeded() {
        if self.dataArray.count == 0 {
            let hud = LGLoadingHUD.show(inView: self.view)
            if let albumListModel = albumListModel {
                hud.dismiss()
                let photos = albumListModel.models
                self.dataArray.removeAll()
                self.dataArray += photos
                self.title = albumListModel.title
                self.cachingImages()
                self.scrollToBottom()
            } else {
                DispatchQueue.userInteractive.async { [weak self] in
                    guard let weakSelf = self else { return }
                    let album = LGPhotoManager.getAllPhotosAlbum(weakSelf.configs.resultMediaTypes)
                    weakSelf.albumListModel = album
                    weakSelf.dataArray.removeAll()
                    weakSelf.dataArray += album.models
                    DispatchQueue.main.async { [weak self] in
                        hud.dismiss()
                        guard let weakSelf = self else { return }
                        weakSelf.title = album.title
                        weakSelf.listView.reloadData()
                        weakSelf.cachingImages()
                        weakSelf.scrollToBottom()
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
        
        DispatchQueue.main.after(0.1) {
            self.listView.scrollToItem(at: lastIndexPath,
                                       at: UICollectionViewScrollPosition.bottom,
                                       animated: false)
        }
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
//                    cell.startCapture()
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
//        cell.selectedBlock = { [weak self] (isSelected) in
//            guard let weakSelf = self else { return }
//            if !isSelected {
//                
//            }
//            if (!selected) {
//                //选中
//                if ([strongSelf canAddModel:model]) {
//                    if (![strongSelf shouldDirectEdit:model]) {
//                        model.selected = YES;
//                        [weakNav.arrSelectedModels addObject:model];
//                        strongCell.btnSelect.selected = YES;
//                        [strongSelf shouldDirectEdit:model];
//                    }
//                }
//            } else {
//                strongCell.btnSelect.selected = NO;
//                model.selected = NO;
//                for (ZLPhotoModel *m in weakNav.arrSelectedModels) {
//                    if ([m.asset.localIdentifier isEqualToString:model.asset.localIdentifier]) {
//                        [weakNav.arrSelectedModels removeObject:m];
//                        break;
//                    }
//                }
//            }
//            if (configuration.showSelectedMask) {
//                strongCell.topView.hidden = !model.isSelected;
//            }
//            [strongSelf resetBottomBtnsStatus:YES];
//        }
        return cell
        
    }
    
//    func canSelectModel(_ model: LGPhotoModel) -> Bool {
//        if selectedDataArray.count > configs.maxSelectCount {
//
//        }
//    }
//
//    - (BOOL)canAddModel:(ZLPhotoModel *)model
//    {
//    ZLImageNavigationController *nav = (ZLImageNavigationController *)self.navigationController;
//    ZLPhotoConfiguration *configuration =nav.configuration;
//
//    if (nav.arrSelectedModels.count >= configuration.maxSelectCount) {
//    ShowToastLong(GetLocalLanguageTextValue(ZLPhotoBrowserMaxSelectCountText), configuration.maxSelectCount);
//    return NO;
//    }
//    if (nav.arrSelectedModels.count > 0) {
//    ZLPhotoModel *sm = nav.arrSelectedModels.firstObject;
//    if (!configuration.allowMixSelect &&
//    ((model.type < ZLAssetMediaTypeVideo && sm.type == ZLAssetMediaTypeVideo) || (model.type == ZLAssetMediaTypeVideo && sm.type < ZLAssetMediaTypeVideo))) {
//    ShowToastLong(@"%@", GetLocalLanguageTextValue(ZLPhotoBrowserCannotSelectVideo));
//    return NO;
//    }
//    }
//    if (![ZLPhotoManager judgeAssetisInLocalAblum:model.asset]) {
//    ShowToastLong(@"%@", GetLocalLanguageTextValue(ZLPhotoBrowseriCloudPhotoText));
//    return NO;
//    }
//    if (model.type == ZLAssetMediaTypeVideo && GetDuration(model.duration) > configuration.maxVideoDuration) {
//    ShowToastLong(GetLocalLanguageTextValue(ZLPhotoBrowserMaxVideoDurationText), configuration.maxVideoDuration);
//    return NO;
//    }
//    return YES;
//    }
}

extension LGMPAlbumDetailController: UIViewControllerPreviewingDelegate {
    @available(iOS 9.0, *)
    public func previewingContext(_ previewingContext: UIViewControllerPreviewing,
                                  viewControllerForLocation location: CGPoint) -> UIViewController?
    {
        return nil
    }
    
    @available(iOS 9.0, *)
    public func previewingContext(_ previewingContext: UIViewControllerPreviewing,
                                  commit viewControllerToCommit: UIViewController)
    {
        
    }
}

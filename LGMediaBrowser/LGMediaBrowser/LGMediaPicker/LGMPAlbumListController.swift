//
//  LGMPAlbumListController.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/6/21.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import UIKit
import LGWebImage
import Photos

/// 显示相册列表的cell
public class LGAlbumListCell: UITableViewCell {
    /// 列表模型数据
    public var dataModel: LGAlbumListModel? {
        didSet {
            layoutDataModel()
        }
    }
    
    /// 显示缩略图的UIImageView
    weak var thumbnailImageView: UIImageView!
    
    /// 显示相册名称和相册中图片数量的UILabel
    weak var titleAndCountLabel: UILabel!
    
    // MARK: -  初始化
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupDefaultViews()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupDefaultViews()
    }
    
    // MARK: - 设置默认视图
    func setupDefaultViews() {
        let thumbnailImageView = UIImageView(frame: CGRect.zero)
        thumbnailImageView.contentMode = UIView.ContentMode.scaleAspectFill
        self.contentView.addSubview(thumbnailImageView)
        self.thumbnailImageView = thumbnailImageView
        
        
        let titleAndCountLabel = UILabel(frame: CGRect.zero)
        if #available(iOS 8.2, *) {
            titleAndCountLabel.font = UIFont.systemFont(ofSize: 15.0, weight: UIFont.Weight.medium)
        } else {
            titleAndCountLabel.font = UIFont.boldSystemFont(ofSize: 14.0)
        }
        titleAndCountLabel.textAlignment = NSTextAlignment.left
        titleAndCountLabel.textColor = UIColor(colorName: "AlbumListTitle")
        self.contentView.addSubview(titleAndCountLabel)
        self.titleAndCountLabel = titleAndCountLabel
    }
    
    /// 展示视图，修正视图大小
    override public func layoutSubviews() {
        super.layoutSubviews()
        let thumbnailImageViewSize = self.contentView.lg_height
        thumbnailImageView.frame = CGRect(x: 10,
                                          y: 0.0,
                                          width: thumbnailImageViewSize,
                                          height: thumbnailImageViewSize)
        
        titleAndCountLabel.frame = CGRect(x: 20.0 + thumbnailImageViewSize,
                                          y: (self.contentView.lg_height - 20) / 2.0,
                                          width: self.contentView.lg_width - thumbnailImageViewSize - 30.0,
                                          height: 20.0)
    }
    
    /// 请求图片的请求ID
    private var lastRequestId: PHImageRequestID = PHInvalidImageRequestID
    
    /// 根据列表模型显示列表内容，包含请求图片
    func layoutDataModel() {
        guard let listData = self.dataModel else { return }
        
        let albumTitle = listData.title ?? ""
        let titleAndCountText = "\(albumTitle)  (\(listData.count))"
        
        var titleFont: UIFont
        if #available(iOS 8.2, *) {
            titleFont = UIFont.systemFont(ofSize: 15.0, weight: UIFont.Weight.medium)
        } else {
            titleFont = UIFont.boldSystemFont(ofSize: 14.0)
        }
        
        let attrString = NSMutableAttributedString(string: titleAndCountText)
        attrString.addAttributes([NSAttributedString.Key.font: titleFont,
                                  NSAttributedString.Key.foregroundColor: UIColor(colorName: "AlbumListTitle")],
                                 range: NSMakeRange(0, albumTitle.count))
        attrString.addAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12.0),
                                  NSAttributedString.Key.foregroundColor: UIColor(colorName: "AlbumListCount")],
                                 range: NSMakeRange(albumTitle.count, attrString.length - albumTitle.count))
        titleAndCountLabel.attributedText = attrString
        
        if let headImageAsset = listData.headImageAsset {
            let outputSize = CGSize(width: 60.0 * UIScreen.main.scale, height: 60.0 * UIScreen.main.scale)
            LGAssetExportManager.default.cancelImageRequest(lastRequestId)
            lastRequestId = LGAssetExportManager.default.requestImage(forAsset: headImageAsset,
                                                                      outputSize: outputSize,
                                                                      resizeMode: PHImageRequestOptionsResizeMode.exact)
            { [weak self] (resultImage, infoDic) in
                if let resultImage = resultImage {
                    self?.thumbnailImageView.image = resultImage
                } else {
                    self?.thumbnailImageView.image = UIImage(namedFromThisBundle: "default_image")
                }
            }
        } else {
            self.thumbnailImageView.image = UIImage(namedFromThisBundle: "default_image")
        }
    }
}

/// 相册列表视图控制器
public class LGMPAlbumListController: LGMPBaseViewController {
    
    /// CELL重用标识
    private struct Reuse {
        static var LGAlbumListCell = "LGAlbumListCell"
    }
    
    /// 展示相册列表的UITableView
    public weak var listTable: UITableView!
    
    /// 数据源
    public var dataArray: [LGAlbumListModel] = []
    
    /// 设置参数
    var configs: LGMediaPicker.Configuration!
    
    weak var delegate: LGMediaPickerDelegate?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = LGLocalizedString("Albums")
        
        setupTableView()
        
        setupCancel()
        
        PHPhotoLibrary.shared().register(self)
    }
    
    // MARK: -  设置取消按钮
    func setupCancel() {
        let rightItem = UIBarButtonItem(title: LGLocalizedString("Cancel"),
                                        style: UIBarButtonItem.Style.plain,
                                        target: self,
                                        action: #selector(close))
        self.navigationItem.rightBarButtonItem = rightItem
    }
    
    /// 取消，关闭所有页面
    @objc func close() {
        self.dismiss(animated: true, completion: nil)
    }
    
    /// 初始化tableview
    func setupTableView() {
        let temp = UITableView(frame: self.view.bounds, style: UITableView.Style.plain)
        temp.estimatedRowHeight = 0.0
        temp.estimatedSectionFooterHeight = 0.0
        temp.estimatedSectionHeaderHeight = 0.0
        temp.delegate = self
        temp.dataSource = self
        temp.separatorInset = UIEdgeInsets(top: 0, left: 10.0, bottom: 0.0, right: 0.0)
        self.view.addSubview(temp)
        self.listTable = temp
        
        temp.register(LGAlbumListCell.self, forCellReuseIdentifier: Reuse.LGAlbumListCell)
    }
    
    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.listTable.frame = self.view.bounds
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if self.dataArray.count == 0 {
            fetchAlbumList()
        }
        self.navigationController?.setToolbarHidden(true, animated: true)
    }
    
    /// 获取相册列表
    @objc func fetchAlbumList() {
        let hud = LGLoadingHUD.show(inView: self.view)
        DispatchQueue.userInteractive.async { [weak self] in
            guard let weakSelf = self else { return }
            LGAssetExportManager.default.fetchAlbumList(weakSelf.configs.resultMediaTypes)
            { [weak self] (resultArray) in
                DispatchQueue.main.async { [weak self] in
                    guard let weakSelf = self else { return }
                    hud.dismiss()
                    weakSelf.dataArray.removeAll()
                    weakSelf.dataArray += resultArray
                    weakSelf.listTable.reloadData()
                    weakSelf.cachingImages()
                }
            }
        }
    }
    
    /// 根据需要缓存图片，提升列表展示速度与
    func cachingImages() {
        var assetArray: [PHAsset] = []
        for model in self.dataArray {
            if let asset = model.headImageAsset {
                assetArray.append(asset)
            }
        }
        
        let itemSize = CGSize(width: 60.0 * UIScreen.main.scale, height: 60.0 * UIScreen.main.scale)
        
        LGAssetExportManager.default.startCachingImages(for: assetArray,
                                                        targetSize: itemSize,
                                                        contentMode: PHImageContentMode.aspectFill)
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
        NSObject.cancelPreviousPerformRequests(withTarget: self)
    }
    
}

// MARK: -  tableview回调
extension LGMPAlbumListController: UITableViewDelegate, UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataArray.count
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64.0
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: LGAlbumListCell
        if let tempCell = tableView.dequeueReusableCell(withIdentifier: Reuse.LGAlbumListCell,
                                                        for: indexPath) as? LGAlbumListCell
        {
            cell = tempCell
        } else {
            cell = LGAlbumListCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: Reuse.LGAlbumListCell)
        }
        cell.dataModel = self.dataArray[indexPath.row]
        cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let listModel = self.dataArray[indexPath.row]
        let detail = LGMPAlbumDetailController()
        detail.albumListModel = listModel
        detail.configs = self.configs
        detail.delegate = self.delegate
        self.navigationController?.pushViewController(detail, animated: true)
    }
}

extension LGMPAlbumListController: PHPhotoLibraryChangeObserver {
    public func photoLibraryDidChange(_ changeInstance: PHChange) {
        DispatchQueue.main.async { [weak self] in
            guard let weakSelf = self else { return }
            NSObject.cancelPreviousPerformRequests(withTarget: weakSelf)
            weakSelf.perform(#selector(LGMPAlbumListController.fetchAlbumList),
                             with: nil,
                             afterDelay: 0.3)
        }
    }
}

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

public class LGAlbumListCell: UITableViewCell {
    public var dataModel: LGAlbumListModel? {
        didSet {
            layoutDataModel()
        }
    }
    weak var thumbnailImageView: UIImageView!
    weak var titleAndCountLabel: UILabel!
    
    public override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupDefaultViews()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupDefaultViews()
    }
    
    func setupDefaultViews() {
        let thumbnailImageView = UIImageView(frame: CGRect.zero)
        thumbnailImageView.contentMode = UIViewContentMode.scaleAspectFill
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
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        let thumbnailImageViewSize = self.contentView.lg_height
        thumbnailImageView.frame = CGRect(x: 10,
                                          y: 0,
                                          width: thumbnailImageViewSize,
                                          height: thumbnailImageViewSize)
        
        titleAndCountLabel.frame = CGRect(x: 20.0 + thumbnailImageViewSize,
                                          y: (self.contentView.lg_height - 20) / 2.0,
                                          width: self.contentView.lg_width - thumbnailImageViewSize - 30.0,
                                          height: 20.0)
    }
    
    private var lastRequestId: PHImageRequestID = PHInvalidImageRequestID
    
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
        attrString.addAttributes([NSAttributedStringKey.font: titleFont,
                                  NSAttributedStringKey.foregroundColor: UIColor(colorName: "AlbumListTitle")],
                                 range: NSMakeRange(0, albumTitle.count))
        attrString.addAttributes([NSAttributedStringKey.font: UIFont.systemFont(ofSize: 12.0),
                                  NSAttributedStringKey.foregroundColor: UIColor(colorName: "AlbumListCount")],
                                 range: NSMakeRange(albumTitle.count, attrString.length - albumTitle.count))
        titleAndCountLabel.attributedText = attrString
        
        if let headImageAsset = listData.headImageAsset {
            let outputSize = CGSize(width: 60.0 * UIScreen.main.scale, height: 60.0 * UIScreen.main.scale)
            LGPhotoManager.cancelImageRequest(lastRequestId)
            lastRequestId = LGPhotoManager.requestImage(forAsset: headImageAsset,
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

public class LGMPAlbumListController: LGMPBaseViewController {
    
    private struct Reuse {
        static var LGAlbumListCell = "LGAlbumListCell"
    }
    
    weak var listTable: UITableView!
    
    var dataArray: [LGAlbumListModel] = []
    
    var configs: LGMediaPicker.Configuration!
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = LGLocalizedString("Albums")
        
        setupTableView()
        
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
    
    func setupTableView() {
        let temp = UITableView(frame: self.view.bounds, style: UITableViewStyle.plain)
        temp.estimatedRowHeight = 0.0
        temp.estimatedSectionFooterHeight = 0.0
        temp.estimatedSectionHeaderHeight = 0.0
        temp.delegate = self
        temp.dataSource = self
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
    }
    
    func fetchAlbumList() {
        let hud = LGLoadingHUD.show(inView: self.view)
        DispatchQueue.userInteractive.async { [weak self] in
            LGPhotoManager.fetchAlbumList(LGPhotoManager.ResultMediaType.all) { [weak self] (resultArray) in
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
    
    func cachingImages() {
        var assetArray: [PHAsset] = []
        for model in self.dataArray {
            if let asset = model.headImageAsset {
                assetArray.append(asset)
            }
        }
        
        let itemSize = CGSize(width: 60.0 * UIScreen.main.scale, height: 60.0 * UIScreen.main.scale)
        
        LGPhotoManager.startCachingImages(for: assetArray,
                                          targetSize: itemSize,
                                          contentMode: PHImageContentMode.aspectFill)
    }
    
}

extension LGMPAlbumListController: UITableViewDelegate, UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataArray.count
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: LGAlbumListCell
        if let tempCell = tableView.dequeueReusableCell(withIdentifier: Reuse.LGAlbumListCell,
                                                        for: indexPath) as? LGAlbumListCell
        {
            cell = tempCell
        } else {
            cell = LGAlbumListCell(style: UITableViewCellStyle.default, reuseIdentifier: Reuse.LGAlbumListCell)
        }
        cell.dataModel = self.dataArray[indexPath.row]
        cell.accessoryType = UITableViewCellAccessoryType.disclosureIndicator
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let listModel = self.dataArray[indexPath.row]
        let detail = LGMPAlbumDetailController()
        detail.configs = self.configs
        detail.albumListModel = listModel
        self.navigationController?.pushViewController(detail, animated: true)
    }
}

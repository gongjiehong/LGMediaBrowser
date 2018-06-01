//
//  LGFilterSelectionView.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/5/29.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import Foundation
import GPUImage

/// 滤镜数据模型
public class LGFilterModel {
    /// 滤镜
    public var filter: GPUImageFilter
    
    /// 滤镜名字
    public var filterName: String
    
    /// 滤镜示例图
    public var iconImage: UIImage
    
    /// 滤镜描述
    public var filterDescription: String?
    
    public init(filter: GPUImageFilter,
                filterName: String,
                iconImage: UIImage,
                filterDescription: String? = nil)
    {
        self.filter = filter
        self.filterName = filterName
        self.iconImage = iconImage
        self.filterDescription = filterDescription
    }
    
    /// 获取滤镜处理后的图片
    private var _filteredImage: UIImage?
    public var filteredImage: UIImage? {
        if let filteredImage = _filteredImage {
            return filteredImage
        } else {
            let image = self.iconImage.imageWith(filter: self.filter)
            _filteredImage = image
            return image
        }
    }
}

/// 选择滤镜类型的视图选项Cell
open class LGFilterSelectionViewCell: UICollectionViewCell {
    override open var isSelected: Bool {
        didSet {
            backgroundLayer.isHidden = !isSelected
        }
    }
    
    weak var iconView: UIImageView!
    weak var titleLabel: UILabel!
    weak var backgroundLayer: CAShapeLayer!
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        setupDefaultViews()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func setupDefaultViews() {
        let width = self.lg_width
        let tempIconView = UIImageView(frame: CGRect(x: 10, y: 5, width: width - 20, height: width - 20))
        iconView = tempIconView
        iconView.clipsToBounds = true
        iconView.layer.cornerRadius = 5.0
        iconView.contentMode = UIViewContentMode.scaleAspectFill
        self.contentView.addSubview(iconView)
        
        let tempTitleLabel = UILabel(frame: CGRect(x: 0, y: iconView.frame.maxY + 5, width: width, height: 15.0))
        titleLabel = tempTitleLabel
        titleLabel.backgroundColor = UIColor.clear
        titleLabel.font = UIFont.systemFont(ofSize: 10.0)
        titleLabel.textColor = UIColor.white
        titleLabel.textAlignment = NSTextAlignment.center
        self.contentView.addSubview(titleLabel)
        
        let tempLayer = CAShapeLayer()
        backgroundLayer = tempLayer
        backgroundLayer.frame = self.contentView.bounds
        backgroundLayer.isHidden = true
        self.contentView.layer.insertSublayer(backgroundLayer, at: 0)
        
        let path = UIBezierPath(roundedRect: self.contentView.bounds, cornerRadius: 5.0)
        backgroundLayer.path = path.cgPath
        backgroundLayer.lineWidth = 1.0
        backgroundLayer.fillColor = UIColor.black.withAlphaComponent(0.4).cgColor
        backgroundLayer.strokeColor = UIColor.white.cgColor
    }
    
    public var filterModel: LGFilterModel? {
        didSet {
            layout()
        }
    }
    
    func layout() {
        if let filterModel = filterModel {
            iconView.image = filterModel.filteredImage
            titleLabel.text = LGLocalizedString(filterModel.filterName)
        }
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        let width = self.lg_width
        iconView.frame = CGRect(x: 10, y: 5, width: width - 20, height: width - 20)
        titleLabel.frame = CGRect(x: 0, y: iconView.frame.maxY + 5, width: width, height: 15.0)
        backgroundLayer.frame = self.contentView.bounds
    }
}

public protocol LGFilterSelectionViewDelegate: NSObjectProtocol {
    func didSelectedFilter(_ filter: GPUImageFilter)
}


/// 选择滤镜类型的视图
open class LGFilterSelectionView: UIView {
    public var collectionView: UICollectionView!
    
    public var filtersArray: [LGFilterModel] = []
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
        setupCollectionView()
    }
    
    weak var delegate: LGFilterSelectionViewDelegate?
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupCollectionView()
    }
    
    private struct Resue {
        static var FilterSelectionViewCell: String = "LGFilterSelectionViewCell"
    }
    
    func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0.0
        layout.itemSize = CGSize(width: 70.0, height: 80.0)
        layout.scrollDirection = .horizontal
        
        self.collectionView = UICollectionView(frame: self.bounds,
                                               collectionViewLayout: layout)
        self.collectionView.showsHorizontalScrollIndicator = true
        self.collectionView.showsVerticalScrollIndicator = false
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.backgroundColor = UIColor.clear
        self.addSubview(collectionView)
        
        self.collectionView.register(LGFilterSelectionViewCell.self,
                                     forCellWithReuseIdentifier: Resue.FilterSelectionViewCell)
    }
    
    private var isFirstLayout: Bool = true
    private var isFirstSelected: Bool = true
    open override func layoutSubviews() {
        super.layoutSubviews()
        self.collectionView.frame = self.bounds
    }
}

extension LGFilterSelectionView: UICollectionViewDelegate, UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.filtersArray.count
    }
    
    public func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        var cell: LGFilterSelectionViewCell
        if let tempCell = collectionView.dequeueReusableCell(withReuseIdentifier: Resue.FilterSelectionViewCell,
                                                             for: indexPath) as? LGFilterSelectionViewCell {
            cell = tempCell
        } else {
            cell = LGFilterSelectionViewCell(frame: CGRect.zero)
        }
        
        cell.filterModel = self.filtersArray[indexPath.row]
        if isFirstLayout, indexPath.row == 0 {
            cell.isSelected = true
            isFirstLayout = false
        }
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if isFirstSelected, indexPath.row != 0 {
            if let cell = collectionView.cellForItem(at: IndexPath(row: 0, section: 0)) {
                cell.isSelected = false
            }
            isFirstSelected = false
        }
        let filterModel = self.filtersArray[indexPath.row]
        self.delegate?.didSelectedFilter(filterModel.filter)
    }
}


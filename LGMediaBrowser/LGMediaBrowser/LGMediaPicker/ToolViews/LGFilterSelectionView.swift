//
//  LGFilterSelectionView.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/5/29.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import Foundation

/// 滤镜类型
///
/// - original: 原图
/// - beautify: 美颜
/// - sepia: 怀旧
/// - grayscale: 黑白
/// - brightness: 高光
/// - sketch: 素描
/// - smoothToon: 卡通
/// - gaussianBlur: 毛玻璃，模糊
/// - vignette: 晕影
/// - emboss: <#emboss description#>
/// - //浮雕: <#//浮雕 description#>
/// - gamma: <#gamma description#>
/// - //伽马: <#//伽马 description#>
/// - bulgeDistortion: <#bulgeDistortion description#>
/// - //鱼眼: <#//鱼眼 description#>
/// - stretchDistortion: <#stretchDistortion description#>
/// - //哈哈镜: <#//哈哈镜 description#>
/// - pinchDistortion: <#pinchDistortion description#>
/// - //凹面镜: <#//凹面镜 description#>
/// - colorInvert: <#colorInvert description#>
/// - //反色: <#//反色 description#>
public enum LGFilterType {
    case original
    case beautify
    case sepia
    case grayscale
    case brightness
    case sketch
    case smoothToon
    case gaussianBlur
    case vignette
    case emboss
    case gamma
    case bulgeDistortion
    case stretchDistortion
    case pinchDistortion
    case colorInvert
}

open class LGFilterSelectionView: UIView {
    var collectionView: UICollectionView!
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupCollectionView()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupCollectionView()
    }
    
    func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 40.0, height: 40.0)
        
        self.collectionView = UICollectionView(frame: self.bounds,
                                               collectionViewLayout: layout)
        self.collectionView.showsHorizontalScrollIndicator = true
        self.collectionView.showsVerticalScrollIndicator = false
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.addSubview(collectionView)
    }
}

extension LGFilterSelectionView: UICollectionViewDelegate, UICollectionViewDataSource {
    
}

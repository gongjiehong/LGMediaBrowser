////
////  LGTextView.swift
////  LGMediaBrowser
////
////  Created by 龚杰洪 on 2018/9/26.
////  Copyright © 2018年 龚杰洪. All rights reserved.
////
//
//import UIKit
//
//@IBDesignable
//open class LGTextView: UITextView {
//    
//    private lazy var placeHolderLayer: CATextLayer = {
//        let layer = CATextLayer()
//        if let tempFont = self.font {
//            layer.font = CGFont(tempFont.fontName as CFString)
//            layer.fontSize = tempFont.fontSize
//        }
//        layer.foregroundColor = self.placeHolderColor.cgColor
//        
//        
//        switch self.textAlignment {
//        case NSTextAlignment.left:
//            break
//        case .right:
//            break
//        case .center:
//            break
//        case .left:
//            break
//        default:
//            <#code#>
//        }
//
////        layer.alignmentMode = self.textAlignment.
//        return layer
//    }()
//    
//    open var placeHolderColor: UIColor = UIColor.gray
//    open var placeHolderText: String?
//    open var attributedPlaceHolderText: NSAttributedString?
//    
//    
//    @IBInspectable open var numberOfLines: Int = 0
//    
//    public override init(frame: CGRect, textContainer: NSTextContainer?) {
//        super.init(frame: frame, textContainer: textContainer)
//    }
//    
//    public required init?(coder aDecoder: NSCoder) {
//        super.init(coder: aDecoder)
//    }
//    
//    
//    
//    
//    open override var intrinsicContentSize: CGSize {
//        return CGSize.zero
//    }
//}

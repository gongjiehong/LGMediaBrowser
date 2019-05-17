//
//  String+LGMediaPicker.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/6/4.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import Foundation

extension String {
    public func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = NSLineBreakMode.byWordWrapping
        
        let boundingBox = self.boundingRect(with: constraintRect,
                                            options: .usesLineFragmentOrigin,
                                            attributes: [NSAttributedString.Key.font: font,
                                                         NSAttributedString.Key.paragraphStyle: paragraphStyle],
                                            context: nil)
        return ceil(boundingBox.height) + abs(boundingBox.origin.y)
    }
    
    public func width(withConstrainedHeight height: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = NSLineBreakMode.byWordWrapping
        
        let boundingBox = self.boundingRect(with: constraintRect,
                                            options: .usesLineFragmentOrigin,
                                            attributes: [NSAttributedString.Key.font: font,
                                                         NSAttributedString.Key.paragraphStyle: paragraphStyle],
                                            context: nil)
        
        return ceil(boundingBox.width)
    }
}

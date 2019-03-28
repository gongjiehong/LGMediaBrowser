//
//  UIColor+LGMediaPicker.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/6/1.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import Foundation
import UIKit

class LGColorHelper {
    static let `default`: LGColorHelper = {
       return LGColorHelper()
    }()
    
    var colorDictionary: [String: String]
    
    init() {
        if let configPath = Bundle.this.path(forResource: "LGMBColorConfigs", ofType: "plist") {
            if let tempDic = NSDictionary(contentsOfFile: configPath) as? [String: String] {
                colorDictionary = tempDic
            } else {
                colorDictionary = [String: String]()
            }
        } else {
            colorDictionary = [String: String]()
        }
    }
}


extension UIColor {
    convenience public init(hexColor: String) {
        var red:   CGFloat = 0.0
        var green: CGFloat = 0.0
        var blue:  CGFloat = 0.0
        var alpha: CGFloat = 1.0
        
        var hexColorString = hexColor;
        
        if !hexColorString.hasPrefix("#"){
            hexColorString = "#"+hexColor;
        }
        
        let index   = hexColorString.index(hexColorString.startIndex, offsetBy: 1)
        let hex     = String(hexColorString[index..<hexColorString.endIndex])
        let scanner = Scanner(string: hex)
        var hexValue: CUnsignedLongLong = 0
        if scanner.scanHexInt64(&hexValue) {
            switch (hex.count) {
            case 3:
                red   = CGFloat((hexValue & 0xF00) >> 8)       / 15.0
                green = CGFloat((hexValue & 0x0F0) >> 4)       / 15.0
                blue  = CGFloat(hexValue & 0x00F)              / 15.0
            case 4:
                red   = CGFloat((hexValue & 0xF000) >> 12)     / 15.0
                green = CGFloat((hexValue & 0x0F00) >> 8)      / 15.0
                blue  = CGFloat((hexValue & 0x00F0) >> 4)      / 15.0
                alpha = CGFloat(hexValue & 0x000F)             / 15.0
            case 6:
                red   = CGFloat((hexValue & 0xFF0000) >> 16)   / 255.0
                green = CGFloat((hexValue & 0x00FF00) >> 8)    / 255.0
                blue  = CGFloat(hexValue & 0x0000FF)           / 255.0
            case 8:
                red   = CGFloat((hexValue & 0xFF000000) >> 24) / 255.0
                green = CGFloat((hexValue & 0x00FF0000) >> 16) / 255.0
                blue  = CGFloat((hexValue & 0x0000FF00) >> 8)  / 255.0
                alpha = CGFloat(hexValue & 0x000000FF)         / 255.0
            default:
                println("Invalid RGB string, number of characters after '#' should be either 3, 4, 6 or 8")
            }
        } else {
            println("Scan hex error")
        }
        self.init(red:red, green:green, blue:blue, alpha:alpha)
    }
    
    convenience init(colorName: String) {
        if let hexString = LGColorHelper.default.colorDictionary[colorName] {
            self.init(hexColor: hexString)
        } else {
            println("Can not found color name: \(colorName)")
            self.init(red: 0 / 255.0, green: 0 / 255.0, blue: 0 / 255.0, alpha: 1.0)
        }
    }
}

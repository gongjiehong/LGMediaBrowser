//
//  UIColor+Extensions.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/5/22.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import UIKit


// Only use within this framework
extension Bundle {
    static var this: Bundle {
        return Bundle(for: LGMediaBrowser.self)
    }
}

extension UIImage {
    public convenience init?(namedFromThisBundle name: String) {
        self.init(named: name, in: Bundle.this, compatibleWith: nil)
    }
}

//
//  String+Extension.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/5/8.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import Foundation
import Photos

extension String: LGMediaLocation {
    public func asURL() throws -> URL {
        if self.range(of: "://") == nil {
            if let result = URL(string: self) {
                return result
            } else {
                throw LGMediaBrowserError.cannotConvertToURL
            }
        } else {
            return URL(fileURLWithPath: self)
        }
    }
    
    public func asAsset() throws -> PHAsset {
        throw LGMediaBrowserError.cannotConvertToPHAsset
    }
}

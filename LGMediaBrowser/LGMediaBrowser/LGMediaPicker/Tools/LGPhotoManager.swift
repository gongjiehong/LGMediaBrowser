//
//  LGPhotoManager.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/5/22.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import Foundation
import Photos

public class LGPhotoManager {
    public enum SortBy {
        case ascending
        case descending
    }
    
    public static var sort: SortBy = .descending
}

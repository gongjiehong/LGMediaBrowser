//
//  DebugLog.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2017/9/7.
//  Copyright © 2017年 龚杰洪. All rights reserved.
//

import Foundation

// MARK: - just for this framework

func println(_ objects: Any...) {
    #if DEBUG
    let dateFormater = DateFormatter()
    dateFormater.timeZone = TimeZone.current
    dateFormater.dateStyle = .full
    dateFormater.timeStyle = .full
    for obj in objects {
        Swift.print("[", dateFormater.string(from: Date()), "LGMediaBrowser ]:", obj, terminator: "\n")
    }
    #endif
}

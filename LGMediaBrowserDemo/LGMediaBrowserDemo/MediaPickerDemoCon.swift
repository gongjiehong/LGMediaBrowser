//
//  MediaPickerDemoCon.swift
//  LGMediaBrowserDemo
//
//  Created by 龚杰洪 on 2018/7/26.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import UIKit
import LGHTTPRequest

class MediaPickerDemoCon: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        for _ in 0...100 {
            var request = LGURLSessionManager.default.request("https://www.baidu.com")
            withUnsafePointer(to: &request) {
                print($0)
            }
            
            var request1 = LGURLSessionManager.default.request("https://www.qq.com")
            withUnsafePointer(to: &request1) {
                print($0)
            }
            
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

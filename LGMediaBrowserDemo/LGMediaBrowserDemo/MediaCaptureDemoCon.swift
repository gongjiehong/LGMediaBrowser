//
//  MediaCaptureDemoCon.swift
//  LGMediaBrowserDemo
//
//  Created by 龚杰洪 on 2018/7/26.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import UIKit
import LGMediaBrowser

class MediaCaptureDemoCon: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        do {
            try LGAuthorizationStatusManager.default.requestPrivacy(withType: .contacts) { (type, status) in
                
            }
        } catch {
            LGStatusBarTips.show(withStatus: error.localizedDescription,
                                 style: LGStatusBarConfig.Style.error)
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

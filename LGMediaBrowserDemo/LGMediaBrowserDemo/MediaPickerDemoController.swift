//
//  MediaPickerDemoCon.swift
//  LGMediaBrowserDemo
//
//  Created by 龚杰洪 on 2018/7/26.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import UIKit
import LGMediaBrowser
import LGHTTPRequest

class MediaPickerDemoController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        for index in 0...100 {
            DispatchQueue.background.async {
//                let request = LGURLSessionManager.default.streamDownload("https://dtaw5kick3bfu.cloudfront.net/100/%E6%97%A0%E7%A0%81%E5%A4%A7%E5%9B%BE.jpg")
                let request = LGURLSessionManager.default.download("https://dtaw5kick3bfu.cloudfront.net/100/%E6%97%A0%E7%A0%81%E5%A4%A7%E5%9B%BE.jpg")
                dump(request)
            }
            sleep(1)
        }
        
    }
    
    @IBAction func toChooseButtonPressed(_ sender: UIButton) {
        let picker = LGMediaPicker()
        picker.pickerDelegate = self
        picker.configs.resultMediaTypes = .all
        self.present(picker, animated: true, completion: nil)
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


extension MediaPickerDemoController: LGMediaPickerDelegate {
    func pickerDidCancel(_ picker: LGMediaPicker) {
        picker.dismiss(animated: true) {
            
        }
    }
    
    func picker(_ picker: LGMediaPicker, didDoneWith photoList: [LGPhotoModel], isOriginalPhoto isOriginal: Bool) {
        picker.dismiss(animated: true) {
            
        }
    }
}

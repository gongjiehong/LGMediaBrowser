//
//  MediaPickerDemoCon.swift
//  LGMediaBrowserDemo
//
//  Created by 龚杰洪 on 2018/7/26.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import UIKit
import LGMediaBrowser

class MediaPickerDemoController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
    }
    
    @IBAction func toChooseButtonPressed(_ sender: UIButton) {
        let picker = LGMediaPicker()
//        picker.delegate = self
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

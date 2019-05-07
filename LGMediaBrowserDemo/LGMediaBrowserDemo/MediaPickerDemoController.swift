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

        
    }
    
    @IBAction func toChooseButtonPressed(_ sender: UIButton) {
//        let picker = LGMediaPicker()
//        picker.pickerDelegate = self
//        picker.configs.maxSelectCount = 1
//        picker.configs.clipRatios = [CGSize(width: 2, height: 3)]
//        picker.configs.resultMediaTypes = [.image]
////        picker.configs.isHeadPortraitMode = true
//        self.present(picker, animated: true, completion: nil)
        
        let capture = LGCameraCapture()
        capture.allowRecordVideo = false
        capture.allowTakePhoto = true
        capture.allowSwitchDevicePosition = false
        capture.devicePosition = .front
        capture.outputSize = CGSize(width: 500, height: 500)
        capture.delegate = self
        self.present(capture, animated: true) {
            
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


extension MediaPickerDemoController: LGMediaPickerDelegate {
    func picker(_ picker: LGMediaPicker, didDoneWith resultImage: UIImage?) {
        picker.dismiss(animated: true) {
            
        }
    }
    
    func pickerDidCancel(_ picker: LGMediaPicker) {
        picker.dismiss(animated: true) {
            
        }
    }
    
    func picker(_ picker: LGMediaPicker, didDoneWith photoList: [LGPhotoModel], isOriginalPhoto isOriginal: Bool) {
        picker.dismiss(animated: true) {
            
        }
    }
}

extension MediaPickerDemoController: LGCameraCaptureDelegate {
    func captureDidCancel(_ capture: LGCameraCapture) {
        capture.dismiss(animated: true) {
            
        }
    }
    
    func captureDidCapturedResult(_ result: LGCameraCapture.ResultModel, capture: LGCameraCapture) {
        
    }
    
    
}

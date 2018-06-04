//
//  LGUnauthorizedController.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/6/1.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import UIKit

public class LGUnauthorizedController: UIViewController {
    
    weak var markImageView: UIImageView!
    weak var promptLabel: UILabel!
    weak var openSystemSettingButton: UIButton!
    
    public enum UnauthorizedType {
        case camera
        case ablum
        case microphone
    }
    
    public var unauthorizedType: UnauthorizedType = .camera
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.title = LGLocalizedString("Unauthorized")
        
        setupDefaultViews()
    }
    
    let iamgeWidth: CGFloat = 128.0
    let labelHeight: CGFloat = 100.0
    let labelMagrin: CGFloat = 20.0
    
    func setupDefaultViews() {
        let imageView = UIImageView(image: UIImage(namedFromThisBundle: "unauthorized_mark"))
        imageView.frame = CGRect(x: (self.view.lg_width - iamgeWidth) / 2.0,
                                 y: (self.view.lg_height - iamgeWidth - labelHeight) / 2.0,
                                 width: iamgeWidth,
                                 height: iamgeWidth)
        self.view.addSubview(imageView)
        self.markImageView = imageView
        
        let tempLabel = UILabel(frame: CGRect(x: labelMagrin,
                                              y: imageView.frame.maxY,
                                              width: self.view.lg_width - labelMagrin * 2.0,
                                              height: labelHeight))
        tempLabel.numberOfLines = 0
        tempLabel.font = UIFont.systemFont(ofSize: 15.0)
        tempLabel.textColor = UIColor(colorName: "PromptText")
        tempLabel.textAlignment = NSTextAlignment.center
        self.view.addSubview(tempLabel)
        self.promptLabel = tempLabel
        
        let capInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        let normalBgImage = UIImage(namedFromThisBundle: "btn_open_settings_normal")
        let resizedNormalImage = normalBgImage?.resizableImage(withCapInsets: capInsets)
        let highlightedBgImage = UIImage(namedFromThisBundle: "btn_open_settings_highlited")
        let resizedHighImage = highlightedBgImage?.resizableImage(withCapInsets: capInsets)
        
        let tempButton = UIButton(type: UIButtonType.custom)
        tempButton.setBackgroundImage(resizedNormalImage, for: UIControlState.normal)
        tempButton.setBackgroundImage(resizedHighImage, for: UIControlState.highlighted)
        tempButton.setTitle(LGLocalizedString("Open Settings"), for: UIControlState.normal)
        tempButton.setTitleColor(UIColor(colorName: "OpenSettingsButtonTitle"), for: UIControlState.normal)
        tempButton.titleLabel?.font = UIFont.systemFont(ofSize: 16.0)
        tempButton.addTarget(self, action: #selector(openSettings), for: UIControlEvents.touchUpInside)
        self.view.addSubview(tempButton)
        self.openSystemSettingButton = tempButton
    }
    
    func layoutViews() {
        var appname: String = "LGMediaPicker"
        if let appInfoDic = Bundle.main.infoDictionary {
            if let tempName = appInfoDic["CFBundleDisplayName"] as? String {
                appname = tempName
            } else if let tempName = appInfoDic["CFBundleName"] as? String {
                appname = tempName
            } else {
            }
        }

        let formatStr = LGLocalizedString("Please Allow %@ Access\n1. Open Settings\n2. Tap Privacy \n3. Find %@ And Switch %@ On")
        var resultStr: String = ""
        switch self.unauthorizedType {
        case .camera:
            let cameraStr = LGLocalizedString("Camera")
            resultStr = String(format: formatStr, cameraStr, appname, cameraStr)
            break
        case .ablum:
            let photosStr = LGLocalizedString("Photos")
            resultStr = String(format: formatStr, photosStr, appname, photosStr)
            break
        case .microphone:
            let microphoneStr = LGLocalizedString("Microphone")
            resultStr = String(format: formatStr, microphoneStr, appname, microphoneStr)
            break
        }
        promptLabel.text = resultStr
    }
    
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutViews()
        
        self.markImageView.frame = CGRect(x: (self.view.lg_width - iamgeWidth) / 2.0,
                                          y: (self.view.lg_height - iamgeWidth - labelHeight) / 2.0,
                                          width: iamgeWidth,
                                          height: iamgeWidth)
        
        if let text = self.promptLabel.text {
            let height = text.height(withConstrainedWidth: self.view.lg_width - labelMagrin * 2.0,
                                     font: self.promptLabel.font)
            self.promptLabel.frame = CGRect(x: labelMagrin,
                                            y: markImageView.frame.maxY + 5.0,
                                            width: self.view.lg_width - labelMagrin * 2.0,
                                            height: height + 5.0)
        } else {
            self.promptLabel.frame = CGRect(x: labelMagrin,
                                            y: markImageView.frame.maxY,
                                            width: self.view.lg_width - labelMagrin * 2.0,
                                            height: labelHeight)
        }
        
        if let buttonTitle = self.openSystemSettingButton.title(for: UIControlState.normal) {
            let width = buttonTitle.width(withConstrainedHeight: 30.0, font: UIFont.systemFont(ofSize: 16.0))
            self.openSystemSettingButton.frame = CGRect(x: (self.view.lg_width - width - 20.0) / 2.0,
                                                        y: self.promptLabel.frame.maxY + 5.0,
                                                        width: width + 20.0,
                                                        height: 30.0)
        } else {
            self.openSystemSettingButton.frame = CGRect(x: (self.view.lg_width - 200.0) / 2.0,
                                                        y: self.promptLabel.frame.maxY,
                                                        width: 200.0,
                                                        height: 30.0)
        }

    }

    public override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func openSettings() {
        if let url = URL(string: UIApplicationOpenSettingsURLString) {
            UIApplication.shared.openURL(url)
        }
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}

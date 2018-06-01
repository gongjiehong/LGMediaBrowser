//
//  LGUnauthorizedController.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/6/1.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import UIKit

class LGUnauthorizedController: UIViewController {
    
    weak var markImageView: UIImageView!
    weak var promptLabel: UILabel!
    
    enum UnauthorizedType {
        case camera
        case ablum
        case microphone
    }
    
    var unauthorizedType: UnauthorizedType = .camera
    
    override func viewDidLoad() {
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
    }
    
    func layoutViews() {
        switch self.unauthorizedType {
        case .camera:
            promptLabel.text = LGLocalizedString("")
            break
        case .ablum:
            promptLabel.text = LGLocalizedString("")
            break
        case .microphone:
            promptLabel.text = LGLocalizedString("")
            break
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutViews()
        
        self.markImageView.frame = CGRect(x: (self.view.lg_width - iamgeWidth) / 2.0,
                                          y: (self.view.lg_height - iamgeWidth - labelHeight) / 2.0,
                                          width: iamgeWidth,
                                          height: iamgeWidth)
        
        self.promptLabel.frame = CGRect(x: labelMagrin,
                                        y: markImageView.frame.maxY,
                                        width: self.view.lg_width - labelMagrin * 2.0,
                                        height: labelHeight)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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

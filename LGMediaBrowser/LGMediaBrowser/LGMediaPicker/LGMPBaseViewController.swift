//
//  LGMPBaseViewController.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/6/21.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import UIKit

open class LGMPBaseViewController: UIViewController {
    
    override open var title: String? {
        didSet {
            if let titleLabel = self.navigationItem.titleView as? UILabel {
                titleLabel.text = title
                titleLabel.sizeToFit()
            }
        }
    }
    

    override open func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        setupTitleLabel()
    }
    
    func setupTitleLabel() {
        let titleLabel = UILabel(frame: CGRect.zero)
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18.0)
        titleLabel.textColor = UIColor(colorName: "NavigationBarTitle")
        titleLabel.backgroundColor = UIColor.clear
        self.navigationItem.titleView = titleLabel
    }

    override open func didReceiveMemoryWarning() {
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

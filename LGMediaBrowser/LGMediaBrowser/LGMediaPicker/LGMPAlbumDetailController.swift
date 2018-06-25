//
//  LGMPAlbumDetailController.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/6/25.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import UIKit


public class LGMPAlbumDetailController: LGMPBaseViewController {
    weak var listView: UICollectionView!
    
    var albumListModel: LGAlbumListModel
    
    var configs: LGMediaPicker.Configuration!
    
    lazy var isForceTouchAvailable: Bool = {
        if #available(iOS 9.0, *) {
            return self.traitCollection.forceTouchCapability == UIForceTouchCapability.available
        } else {
            return false
        }
    }()
    
    struct Settings {
        static var columnCount: Int = {
            if UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.pad {
                return 6
            } else {
                return 4
            }
        }()
        
        static var itemInteritemSpacing: CGFloat = 3.0
        static var itemLineSpacing: CGFloat = 3.0
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: -  初始化视图
    
    func setupListCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = Settings.itemLineSpacing
        layout.minimumInteritemSpacing = Settings.itemInteritemSpacing
        
        
        let collectionView = UICollectionView(frame: self.view.bounds, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .never
        } else {
        }
        self.view.addSubview(collectionView)
        self.listView = collectionView
        
        if configs.allowForceTouch, isForceTouchAvailable {
            self.registerForPreviewing(with: self, sourceView: collectionView)
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

extension LGMPAlbumDetailController: UICollectionViewDataSource, UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        <#code#>
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        <#code#>
    }
}

extension LGMPAlbumDetailController: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               sizeForItemAt indexPath: IndexPath) -> CGSize
    {
        let width = min(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
        let columnCount = CGFloat(Settings.columnCount)
        return CGSize(width: (width - Settings.itemLineSpacing * columnCount) / columnCount,
                      height: (width - Settings.itemLineSpacing * columnCount) / columnCount)
    }
}

extension LGMPAlbumDetailController: UIViewControllerPreviewingDelegate {
    @available(iOS 9.0, *)
    public func previewingContext(_ previewingContext: UIViewControllerPreviewing,
                                  viewControllerForLocation location: CGPoint) -> UIViewController?
    {
        
    }
    
    @available(iOS 9.0, *)
    public func previewingContext(_ previewingContext: UIViewControllerPreviewing,
                                  commit viewControllerToCommit: UIViewController)
    {
        
    }
}

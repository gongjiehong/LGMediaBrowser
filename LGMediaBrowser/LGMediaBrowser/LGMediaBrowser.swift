//
//  LGMediaBrowser.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/4/27.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import UIKit
import Photos

public protocol LGMediaBrowserDelegate: NSObjectProtocol {
    
}

public protocol LGMediaBrowserDataSource: NSObjectProtocol {
    
}


public class LGMediaBrowser: UIViewController {
    
    private struct Reuse {
        static var VideoCell = "LGMediaBrowserVideoCell"
        static var AudioCell = "LGMediaBrowserAudioCell"
        static var GeneralPhotoCell = "LGMediaBrowserGeneralPhotoCell"
        static var LivePhotoCell = "LGMediaBrowserLivePhotoCell"
        static var Other = "UICollectionViewCell"
    }

    public weak var collectionView: UICollectionView!
    
    public var mediaArray: [LGMediaProtocol] = []
    
    weak var delegate: LGMediaBrowserDelegate?
    weak var dataSource: LGMediaBrowserDataSource?
    
    public var targetView: UIView?
    public var animationImage: UIImage!
    
    lazy var flowLayout: UICollectionViewFlowLayout  = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0.0
        layout.scrollDirection = UICollectionViewScrollDirection.horizontal
        layout.sectionInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        return layout
    }()
    
    override public func viewDidLoad() {
        super.viewDidLoad()

        setupTransition()
        
        setupCollectionView()
    }
    
    func setupTransition() {
        self.transitioningDelegate = self
        self.modalPresentationStyle = .custom
    }
    
    func setupCollectionView() {
        let collection = UICollectionView(frame: self.view.bounds, collectionViewLayout: flowLayout)
        self.collectionView = collection
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        if #available(iOS 11.0, *) {
            self.collectionView.contentInsetAdjustmentBehavior = .never
        } else {
        }
        
        self.view.addSubview(self.collectionView)
        
        self.collectionView.delaysContentTouches = false
        
        self.collectionView.register(LGMediaBrowserVideoCell.self, forCellWithReuseIdentifier: Reuse.VideoCell)
        self.collectionView.register(LGMediaBrowserAudioCell.self, forCellWithReuseIdentifier: Reuse.AudioCell)
        self.collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: Reuse.Other)
        
        self.collectionView.isMultipleTouchEnabled = true
        self.collectionView.delaysContentTouches = false
        self.collectionView.canCancelContentTouches = true
        self.collectionView.alwaysBounceVertical = false
        self.collectionView.isPagingEnabled = true
    }

    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.collectionView.frame = self.view.bounds
        self.collectionView.reloadData()
    }
    
    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override public var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    override public var prefersStatusBarHidden: Bool {
        return false
    } 
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    

}

extension LGMediaBrowser: UIViewControllerTransitioningDelegate {
    
    public func animationController(forPresented presented: UIViewController,
                                             presenting: UIViewController,
                                             source: UIViewController) -> UIViewControllerAnimatedTransitioning?
    {
        return LGMediaBrowserPresentTransition(direction: .present,
                                               targetView: self.targetView,
                                               finalImageSize: animationImage.size,
                                               placeholderImage: animationImage)
    }
    
    public func animationController(forDismissed dismissed: UIViewController) ->
        UIViewControllerAnimatedTransitioning?
    {
        return LGMediaBrowserPresentTransition(direction: .dismiss,
                                               targetView: self.targetView,
                                               finalImageSize: animationImage.size,
                                               placeholderImage: animationImage)
    }
    
//    public func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) ->
//        UIViewControllerInteractiveTransitioning?
//    {
//        return self
//    }
//
//
//    public func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) ->
//        UIViewControllerInteractiveTransitioning?
//    {
//
//    }
//
//
//    public func presentationController(forPresented presented: UIViewController,
//                                                presenting: UIViewController?,
//                                                source: UIViewController) -> UIPresentationController?
//    {
//
//    }
}

extension LGMediaBrowser: UICollectionViewDelegate, UICollectionViewDataSource {
    // MARK: UICollectionViewDataSource
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return mediaArray.count
    }
    
    public func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let media = mediaArray[indexPath.row]
        switch media.mediaType {
        case .video:
            return listView(collectionView, videoCellForItemAt: indexPath)
        case .audio:
            return listView(collectionView, audioCellForItemAt: indexPath)
        case .generalPhoto:
            return listView(collectionView, generalPhotoCellForItemAt: indexPath)
        case .livePhoto:
            return listView(collectionView, livePhotoCellForItemAt: indexPath)
        default:
            return listView(collectionView, otherCellForItemAt: indexPath)
        }
    }
    
    public func listView(_ collectionView: UICollectionView,
                               videoCellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        var result: LGMediaBrowserVideoCell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Reuse.VideoCell, for: indexPath)
        if let temp = cell as? LGMediaBrowserVideoCell {
            result = temp
        } else {
            result = LGMediaBrowserVideoCell(frame: CGRect.zero)
        }
        result.mediaModel = mediaArray[indexPath.row]
        return result
    }
    
    public func listView(_ collectionView: UICollectionView,
                               audioCellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        var result: LGMediaBrowserVideoCell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Reuse.VideoCell, for: indexPath)
        if let temp = cell as? LGMediaBrowserVideoCell {
            result = temp
        } else {
            result = LGMediaBrowserVideoCell(frame: CGRect.zero)
        }
        result.mediaModel = mediaArray[indexPath.row]
        return result
    }
    
    public func listView(_ collectionView: UICollectionView,
                               generalPhotoCellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        var result: LGMediaBrowserVideoCell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Reuse.VideoCell, for: indexPath)
        if let temp = cell as? LGMediaBrowserVideoCell {
            result = temp
        } else {
            result = LGMediaBrowserVideoCell(frame: CGRect.zero)
        }
        result.mediaModel = mediaArray[indexPath.row]
        return result
    }
    
    public func listView(_ collectionView: UICollectionView,
                               livePhotoCellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        var result: LGMediaBrowserVideoCell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Reuse.VideoCell, for: indexPath)
        if let temp = cell as? LGMediaBrowserVideoCell {
            result = temp
        } else {
            result = LGMediaBrowserVideoCell(frame: CGRect.zero)
        }
        result.mediaModel = mediaArray[indexPath.row]
        return result
    }
    
    public func listView(_ collectionView: UICollectionView,
                               otherCellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        var result: LGMediaBrowserVideoCell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Reuse.VideoCell, for: indexPath)
        if let temp = cell as? LGMediaBrowserVideoCell {
            result = temp
        } else {
            result = LGMediaBrowserVideoCell(frame: CGRect.zero)
        }
        result.mediaModel = mediaArray[indexPath.row]
        return result
    }
    
    // MARK: UICollectionViewDelegate
    
    
    /*
     // Uncomment this method to specify if the specified item should be highlighted during tracking
     override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
     return true
     }
     */
    
    /*
     // Uncomment this method to specify if the specified item should be selected
     override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
     return true
     }
     */
    
    /*
     // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
     override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
     return false
     }
     
     override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
     return false
     }
     
     override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
     
     }
     */
}

extension LGMediaBrowser: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               sizeForItemAt indexPath: IndexPath) -> CGSize
    {
        return self.view.bounds.size
    }
}



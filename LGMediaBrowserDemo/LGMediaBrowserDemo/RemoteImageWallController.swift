//
//  RemoteImageBrowsingController.swift
//  LGMediaBrowserDemo
//
//  Created by 龚杰洪 on 2018/7/26.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import UIKit
import LGWebImage
import LGMediaBrowser

fileprivate class RemoteImageLayoutCell: UICollectionViewCell {
    weak var imageView: LGAnimatedImageView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupImageView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupImageView()
    }
    
    
    
    func setupImageView() {
        let temp = LGAnimatedImageView(frame: CGRect.zero)
        temp.contentMode = UIView.ContentMode.scaleAspectFill
        temp.translatesAutoresizingMaskIntoConstraints = false
        temp.clipsToBounds = true
        self.contentView.addSubview(temp)
        
        self.imageView = temp
        
        temp.topAnchor.constraint(equalTo: self.contentView.topAnchor).isActive = true
        temp.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor).isActive = true
        temp.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor).isActive = true
        temp.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor).isActive = true
    }
}

class RemoteImageWallController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var forchTouch: LGForceTouch!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.collectionView.register(RemoteImageLayoutCell.self, forCellWithReuseIdentifier: "RemoteImageLayoutCell")
        
        let forchTouch = LGForceTouch(viewController: self)
        _ = forchTouch.registerForPreviewingWithDelegate(self, sourceView: self.collectionView)
        self.forchTouch = forchTouch
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
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

extension RemoteImageWallController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var cell: RemoteImageLayoutCell
        if let temp = collectionView.dequeueReusableCell(withReuseIdentifier: "RemoteImageLayoutCell",
                                                         for: indexPath) as? RemoteImageLayoutCell {
            cell = temp
        } else {
            cell = RemoteImageLayoutCell(frame: CGRect.zero)
        }
        cell.imageView.lg_setImageWithURL(ImgaeURLConstructHelper.imageURL(fromFileID: indexPath.row + 1, size: 256))
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return ImageCount//dataArray.count
    }
    

    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        let mediaBrowser = LGMediaBrowser(dataSource: self,
                                          status: LGMediaBrowserStatus.browsing,
                                          currentIndex: indexPath.row)
        mediaBrowser.delegate = self
        self.navigationController?.pushViewController(mediaBrowser, animated: true)
    }
}

extension RemoteImageWallController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize
    {
        let itemWidth = (UIScreen.main.bounds.width) / 4
        return CGSize(width: itemWidth, height: itemWidth)
    }
}

extension RemoteImageWallController: LGMediaBrowserDataSource {
    func numberOfPhotosInPhotoBrowser(_ photoBrowser: LGMediaBrowser) -> Int {
        return ImageCount
    }
    
    func photoBrowser(_ photoBrowser: LGMediaBrowser, photoAtIndex index: Int) -> LGMediaModel {
        let url = ImgaeURLConstructHelper.imageURL(fromFileID: index + 1, size: 256)
        var image: UIImage?
        if let cell = collectionView.cellForItem(at: IndexPath(row: index, section: 0)) as? RemoteImageLayoutCell {
            image = cell.imageView.image
        }
        return (try? LGMediaModel(thumbnailImageURL: url,
                                  mediaURL: url,
                                  mediaAsset: nil,
                                  mediaType: LGMediaModel.MediaType.generalPhoto,
                                  mediaPosition: LGMediaModel.Position.remoteFile,
                                  thumbnailImage: image)) ?? LGMediaModel()
    }
}

extension RemoteImageWallController: LGMediaBrowserDelegate {
    func didScrollToIndex(_ browser: LGMediaBrowser, index: Int) {
        self.collectionView.scrollToItem(at: IndexPath(row: index, section: 0),
                                         at: UICollectionView.ScrollPosition.centeredVertically,
                                         animated: false)
        self.collectionView.setNeedsLayout()
    }
    
    
    func viewForMedia(_ browser: LGMediaBrowser, index: Int) -> UIView? {
        print(index, "-> UIView?")
        return self.collectionView.cellForItem(at: IndexPath(row: index, section: 0))
    }
    
    func didHide(_ browser: LGMediaBrowser, atIndex index: Int) {
        self.collectionView.scrollToItem(at: IndexPath(row: index, section: 0),
                                         at: UICollectionView.ScrollPosition.centeredVertically,
                                         animated: false)
    }
}

extension RemoteImageWallController: LGForceTouchPreviewingDelegate {
    func previewingContext(_ previewingContext: LGForceTouchPreviewingContext,
                           viewControllerForLocation location: CGPoint) -> UIViewController?
    {
        guard let indexPath = self.collectionView.indexPathForItem(at: location),
            let cell = self.collectionView.cellForItem(at: indexPath) as? RemoteImageLayoutCell else
        {
            return nil
        }
        
        previewingContext.sourceRect = cell.frame
        
        let url = ImgaeURLConstructHelper.imageURL(fromFileID: indexPath.row + 1, size: 256)
        let mediaModel = (try? LGMediaModel(thumbnailImageURL: url,
                                            mediaURL: url,
                                            mediaAsset: nil,
                                            mediaType: LGMediaModel.MediaType.generalPhoto,
                                            mediaPosition: LGMediaModel.Position.remoteFile,
                                            thumbnailImage: cell.imageView.image)) ?? LGMediaModel()
        let previewController = LGForceTouchPreviewController(mediaModel: mediaModel, currentIndex: indexPath.row)
        return previewController
    }
    
    func previewingContext(_ previewingContext: LGForceTouchPreviewingContext,
                           commitViewController viewControllerToCommit: UIViewController)
    {
        guard let previewController = viewControllerToCommit as? LGForceTouchPreviewController else {return}
        var configs = LGMediaBrowserSettings()
        configs.isClickToTurnOffEnabled = false
        configs.showsStatusBar = false
        let mediaBrowser = LGMediaBrowser(dataSource: self,
                                          configs: configs,
                                          status: .browsing,
                                          currentIndex: previewController.currentIndex)
        mediaBrowser.delegate = self
        self.navigationController?.pushViewController(mediaBrowser, animated: false)
    }
}



let ImageCount: Int = 4_000
let ImageURLPrefix: String = "http://qzonestyle.gtimg.cn/qzone/app/weishi/client/testimage/"
class ImgaeURLConstructHelper {
    static func imageURL(fromFile file: String, size: Int) -> String {
        return String(format: "%@%d/%@", ImageURLPrefix, size, file)
    }
    
    static func imageURL(fromFileID fileID: Int, size: Int) -> String {
        if size > 0 {
            return String(format: "%@%d/%d.jpg", ImageURLPrefix, size, fileID)
        } else {
            return String(format: "%@origin/%d.jpg", ImageURLPrefix, fileID)
        }
    }
}

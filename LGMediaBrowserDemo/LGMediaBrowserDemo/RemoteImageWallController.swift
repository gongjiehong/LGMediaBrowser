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
    
    var dataArray: [String] = []
    
    var forchTouch: LGForceTouch!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.collectionView.register(RemoteImageLayoutCell.self, forCellWithReuseIdentifier: "RemoteImageLayoutCell")
        
        dataArray.append("https://s3-us-west-2.amazonaws.com/julyforcd/100/mew_interlaced.png")
        dataArray.append("https://s3-us-west-2.amazonaws.com/julyforcd/100/1510480450.jp2")
        dataArray.append("https://s3-us-west-2.amazonaws.com/julyforcd/100/1510480481.jpg")
        dataArray.append("https://s3-us-west-2.amazonaws.com/julyforcd/100/1518065289.tiff")
        dataArray.append("https://s3-us-west-2.amazonaws.com/julyforcd/100/5ad6b3c630e69.bmp")
        dataArray.append("https://s3-us-west-2.amazonaws.com/julyforcd/100/AnimatedPortableNetworkGraphics.png")
        dataArray.append("https://s3-us-west-2.amazonaws.com/julyforcd/100/C3ZwL.png")
        dataArray.append("https://s3-us-west-2.amazonaws.com/julyforcd/100/Pikachu.gif")
        dataArray.append("https://s3-us-west-2.amazonaws.com/julyforcd/100/animated.webp")
        dataArray.append("https://s3-us-west-2.amazonaws.com/julyforcd/100/bitbug_favicon.ico")
        dataArray.append("https://s3-us-west-2.amazonaws.com/julyforcd/100/google%402x.webp")
        dataArray.append("https://s3-us-west-2.amazonaws.com/julyforcd/100/lime-cat.JPEG")
        dataArray.append("https://s3-us-west-2.amazonaws.com/julyforcd/100/normal_png.png")
        dataArray.append("https://s3-us-west-2.amazonaws.com/julyforcd/100/static_gif.gif")
        dataArray.append("https://s3-us-west-2.amazonaws.com/julyforcd/100/twitter_fav_icon_300.png")
        
        // Only supports iOS11 and above
        dataArray.append("http://staticfile.cxylg.com/IMG_0392.heic")
        
        
        forchTouch = LGForceTouch(viewController: self)
        _ = forchTouch.registerForPreviewingWithDelegate(self, sourceView: self.collectionView)
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

extension RemoteImageWallController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
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
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize
    {
        let itemWidth = (UIScreen.main.bounds.width) / 4
        return CGSize(width: itemWidth, height: itemWidth)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        var configs = LGMediaBrowserSettings()
        configs.enableTapToClose = false
        let mediaBrowser = LGMediaBrowser(dataSource: self,
                                          configs: configs,
                                          status: .browsing,
                                          currentIndex: indexPath.row)
        mediaBrowser.delegate = self
        self.navigationController?.pushViewController(mediaBrowser, animated: true)
    }
}

extension RemoteImageWallController: LGMediaBrowserDataSource {
    func numberOfPhotosInPhotoBrowser(_ photoBrowser: LGMediaBrowser) -> Int {
        return ImageCount
    }
    
    func photoBrowser(_ photoBrowser: LGMediaBrowser, photoAtIndex index: Int) -> LGMediaModel {
        let url = ImgaeURLConstructHelper.imageURL(fromFileID: index + 1, size: 256)
        return LGMediaModel(thumbnailImageURL: url,
                            mediaURL: url,
                            mediaAsset: nil,
                            mediaType: LGMediaModel.MediaType.generalPhoto,
                            mediaPosition: LGMediaModel.Position.remoteFile)
    }
}

extension RemoteImageWallController: LGMediaBrowserDelegate {
    func didScrollToIndex(_ browser: LGMediaBrowser, index: Int) {
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
        let mediaModel = LGMediaModel(thumbnailImageURL: url,
                            mediaURL: url,
                            mediaAsset: nil,
                            mediaType: LGMediaModel.MediaType.generalPhoto,
                            mediaPosition: LGMediaModel.Position.remoteFile,
                            thumbnailImage: cell.imageView.image)
        let previewController = LGForceTouchPreviewController(mediaModel: mediaModel, currentIndex: indexPath.row)
        return previewController
    }
    
    func previewingContext(_ previewingContext: LGForceTouchPreviewingContext,
                           commitViewController viewControllerToCommit: UIViewController)
    {
        guard let previewController = viewControllerToCommit as? LGForceTouchPreviewController else {return}
        var configs = LGMediaBrowserSettings()
        configs.enableTapToClose = false
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




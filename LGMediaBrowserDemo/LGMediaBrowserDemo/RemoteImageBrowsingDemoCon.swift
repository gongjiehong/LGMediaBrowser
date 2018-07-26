//
//  RemoteImageBrowsingController.swift
//  LGMediaBrowserDemo
//
//  Created by 龚杰洪 on 2018/7/26.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import UIKit


fileprivate class RemoteImageLayoutCell: UICollectionViewCell {
    weak var imageView: UIImageView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupImageView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupImageView()
    }
    
    func setupImageView() {
        let temp = UIImageView(frame: CGRect.zero)
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

class RemoteImageBrowsingController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    
    var dataArray: [String] = []
    
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

extension RemoteImageBrowsingController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var cell: RemoteImageLayoutCell
        if let temp = collectionView.dequeueReusableCell(withReuseIdentifier: "RemoteImageLayoutCell",
                                                         for: indexPath) as? RemoteImageLayoutCell {
            cell = temp
        } else {
            cell = RemoteImageLayoutCell(frame: CGRect.zero)
        }
        cell.imageView.lg_setImageWithURL(dataArray[indexPath.row])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize
    {
        let itemWidth = (UIScreen.main.bounds.width - 50) / 4
        return CGSize(width: itemWidth, height: itemWidth)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}

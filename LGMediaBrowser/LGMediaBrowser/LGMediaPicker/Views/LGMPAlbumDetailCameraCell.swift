//
//  LGMPAlbumDetailCameraCell.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/6/26.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import UIKit
import AVFoundation

public class LGMPAlbumDetailCameraCell: UICollectionViewCell {
    public lazy var layoutImageView: UIImageView = {
       let temp = UIImageView(frame: self.contentView.bounds)
        temp.contentMode = UIViewContentMode.scaleAspectFill
        temp.image = UIImage(namedFromThisBundle: "btn_take_photo")
        return temp
    }()
    
    lazy var session: AVCaptureSession = {
        return AVCaptureSession()
    }()
    
    lazy var videoInput: AVCaptureDeviceInput? = {
        if let device = LGRecorderTools.videoDeviceForPosition(AVCaptureDevice.Position.back) {
            return try? AVCaptureDeviceInput(device: device)
        } else {
            return nil
        }
    }()
    
    lazy var movieOutput: AVCaptureMovieFileOutput = {
        return AVCaptureMovieFileOutput()
    }()
    
    lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        let layer = AVCaptureVideoPreviewLayer(session: self.session)
        layer.frame = self.contentView.bounds
        layer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        return layer
    }()
    
    /// 圆角大小，默认无圆角
    public var cornerRadius: CGFloat = 0.0

    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupDefaultViews()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupDefaultViews()
    }
    
    func setupDefaultViews() {
        self.contentView.addSubview(layoutImageView)
        
        self.contentView.layer.insertSublayer(previewLayer, at: 0)
        previewLayer.frame = self.contentView.bounds
        previewLayer.masksToBounds = true
        
        self.contentView.backgroundColor = UIColor.black
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        layoutImageView.sizeToFit()
        layoutImageView.center = self.contentView.center
        
        previewLayer.frame = self.contentView.bounds
        
        if cornerRadius > 0.0 {
            self.layer.cornerRadius = cornerRadius
            self.layer.masksToBounds = true
        } else {
            self.layer.cornerRadius = 0.0
            self.layer.masksToBounds = false
        }
    }
    
    public func startCapture() {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera) {
            let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
            
            if status == .restricted || status == .denied {
                return
            }
        } else {
            // 摄像头硬件有问题，直接返回
            return
        }
        
        AVCaptureDevice.requestAccess(for: AVMediaType.video) { (granted) in
            if !granted {
                DispatchQueue.main.async { [weak self] in
                    guard let weakSelf = self else { return }
                    weakSelf.session.stopRunning()
                    weakSelf.previewLayer.removeFromSuperlayer()
                }
            }
        }
        
        if self.session.isRunning {
            return
        }

        guard let videoInput = self.videoInput else { return }
        
        if self.session.canAddInput(videoInput) {
            self.session.addInput(videoInput)
        }
        
        if self.session.canAddOutput(self.movieOutput) {
            self.session.addOutput(self.movieOutput)
        }
        
        self.session.startRunning()
    }
    
    deinit {
        if self.session.isRunning {
            self.session.stopRunning()
        }
    }
}

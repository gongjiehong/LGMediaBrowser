//
//  LGCameraCapture.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/5/22.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import Foundation
import AVFoundation
import CoreMotion
import CoreVideo
import LGWebImage
import CoreImage

/// 拍照或录像完成的回调
public protocol LGCameraCaptureDelegate: NSObjectProtocol {
    func captureDidCancel(_ capture: LGCameraCapture)
    func captureDidCapturedResult(_ result: LGCameraCapture.ResultModel, capture: LGCameraCapture)
}

/// 拍照和录制视频自定义类
public class LGCameraCapture: UIViewController {
    private var _previewLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer()
    
    /// 视频格式定义
    ///
    /// - mp4: mp4
    /// - mov: mov
    public enum VideoType {
        case mp4
        case mov
    }
    
    private var _modalPresentationStyle: UIModalPresentationStyle = UIModalPresentationStyle.fullScreen
    
    /// iOS13以后的全屏问题，默认改成全屏
    public override var modalPresentationStyle: UIModalPresentationStyle {
        set {
            _modalPresentationStyle = newValue
        } get {
            return _modalPresentationStyle
        }
    }
    
    /// 完成后返回的数据模型格式定义
    public struct ResultModel {
        /// 返回的数据类型
        ///
        /// - photo: 图片，image不为空
        /// - video: 视频，videoURL不为空
        public enum `Type` {
            case photo
            case video
        }
        
        /// 初始化
        ///
        /// - Parameters:
        ///   - type: 结果类型
        ///   - image: 图片对象
        ///   - videoURL: 视频本地URL
        public init(type: Type, image: UIImage?, videoURL: URL?) {
            self.type = type
            self.image = image
            self.videoURL = videoURL
        }
        
        public var type: Type
        public var image: UIImage?
        public var videoURL: URL?
    }
    
    /// 最大视频录制时长，默认一分钟
    public var maximumVideoRecordingDuration: CFTimeInterval = 60.0
    
    /// 每秒帧数
    public var framePerSecond: Int32 = 30
    
    /// 是否允许拍照，默认true
    public var allowTakePhoto: Bool = true
    
    /// 是否允许录制视频，默认true
    public var allowRecordVideo: Bool = true
    
    /// 是否支持滤镜，默认true
    public var allowFilters: Bool = true
    
    /// 是否允许切换摄像头，需配合devicePosition使用，默认true
    public var allowSwitchDevicePosition: Bool = true
    
    /// 指定使用前置还是后置摄像头
    public var devicePosition: AVCaptureDevice.Position = AVCaptureDevice.Position.back
    
    /// 输出文件大小
    /// 可以是相对坐标（(1.0, 0.5), (ScreenSize.width * 1.0 px, ScreenSize.height * 0.5 px)）
    /// 也可以是绝对坐标 ((320, 320) 所有设备都输出320px * 320px的视频)
    public var outputSize: CGSize = CGSize(width: 1, height: 1) {
        didSet {
            if outputSize == CGSize(width: 1, height: 1) {
                _previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
            }
        }
    }
    
    /// 输出视频格式
    public var videoType: VideoType = .mp4
    
    /// 输出视频格式 AVFileType
    var videoAVFileType: AVFileType {
        var fileType: AVFileType
        if self.videoType == .mov {
            fileType = AVFileType.mov
        } else {
            fileType = AVFileType.mp4
        }
        return fileType
    }
    
    /// 视频进度条颜色
    public var circleProgressColor: UIColor = UIColor.blue
    
    /// 拍照时是否播放快门音，默认开启
    public var isShutterSoundEnabled: Bool = true
    
    /// 回调
    public weak var delegate: LGCameraCaptureDelegate?
    
    public var filtersArray: [LGFilterModel] = []
    
    /// 录制，返回，完成等按钮的工具条
    var toolView: LGCameraCaptureToolView!
    
    /// 滤镜选择视图
    var filterToolView: LGFilterSelectionView!
    
    var captureSession = AVCaptureSession()
    
    /// 录制视频的摄像机对象
    var videoCamera: AVCaptureDevice!
    
    /// 录制视频的麦克风对象，如果只支持拍照，则不会初始化
    var audioMicrophone: AVCaptureDevice?
    
    /// 当前使用的滤镜
    var filter: CIFilter?
    
    /// 裁切图片和视频的滤镜
    var cropFilter: CIFilter!
    
    /// 视频写入器
    var movieWriter: AVCaptureMovieFileOutput = AVCaptureMovieFileOutput()
    
    /// 图片获取器
    var pictureTaker: AVCapturePhotoOutput = AVCapturePhotoOutput()
    
    /// 组装一部分滤镜
    private lazy var _filtersArray: [LGFilterModel] = {
        var resultArray = [LGFilterModel]()
        
        let exampleImage = UIImage(namedFromThisBundle: "dousen")!
        
        /// 原始图片
        let original = CIFilter()
        let originalModel = LGFilterModel(filter: original,
                                          filterName: "Original",
                                          iconImage: exampleImage)
//        resultArray.append(originalModel)
//
//        /// 磨皮
//        let bilateralFilter = CIFilter.discBlur()
////            GPUImageBilateralFilter()
//        bilateralFilter.distanceNormalizationFactor = 4.0
//        let bilateralModel = LGFilterModel(filter: bilateralFilter,
//                                           filterName: "Beaytify",
//                                           iconImage: exampleImage)
//        resultArray.append(bilateralModel)
//
//        /// 怀旧
//        let sepiaFilter = GPUImageSepiaFilter()
//        let sepiaModel = LGFilterModel(filter: sepiaFilter, filterName: "Nostalgia", iconImage: exampleImage)
//        resultArray.append(sepiaModel)
//
//        /// 黑白
//        let grayscaleFilter = GPUImageGrayscaleFilter()
//        let grayscaleModel = LGFilterModel(filter: grayscaleFilter, filterName: "Grayscale", iconImage: exampleImage)
//        resultArray.append(grayscaleModel)
//
//
//        /// 亮白
//        let brightnessFilter = GPUImageBrightnessFilter()
//        brightnessFilter.brightness = 0.1
//        let brightnessModel = LGFilterModel(filter: brightnessFilter,
//                                            filterName: "Brightness",
//                                            iconImage: exampleImage)
//        resultArray.append(brightnessModel)
//
//        /// 素描
//        let sketchFilter = GPUImageSketchFilter()
//        let sketchModel = LGFilterModel(filter: sketchFilter, filterName: "Sketch", iconImage: exampleImage)
//        resultArray.append(sketchModel)
//
//        /// 毛玻璃
//        let gaussianFilter = GPUImageGaussianBlurFilter()
//        gaussianFilter.blurRadiusInPixels = 5.0
//        let gaussianModel = LGFilterModel(filter: gaussianFilter, filterName: "GaussianBlur", iconImage: exampleImage)
//        resultArray.append(gaussianModel)
//
//        /// 晕影
//        let vignetteFilter = GPUImageVignetteFilter()
//        let vignetteModel = LGFilterModel(filter: vignetteFilter, filterName: "Vignette", iconImage: exampleImage)
//        resultArray.append(vignetteModel)
//
//        /// 浮雕
//        let embossFilter = GPUImageEmbossFilter()
//        embossFilter.intensity = 1.0
//        let embossModel = LGFilterModel(filter: embossFilter, filterName: "Emboss", iconImage: exampleImage)
//        resultArray.append(embossModel)
//
//        /// 伽马
//        let gammaFilter = GPUImageGammaFilter()
//        gammaFilter.gamma = 1.5
//        let gammaModel = LGFilterModel(filter: gammaFilter, filterName: "Gamma", iconImage: exampleImage)
//        resultArray.append(gammaModel)
//
//        /// 鱼眼
//        let bulgeDistortionFilter = GPUImageBulgeDistortionFilter()
//        bulgeDistortionFilter.radius = 0.5
//        let bulgeDistortionModel = LGFilterModel(filter: bulgeDistortionFilter,
//                                                 filterName: "Fisheye",
//                                                 iconImage: exampleImage)
//        resultArray.append(bulgeDistortionModel)
//
//
//        /// 哈哈镜
//        let stretchDistortionFilter = GPUImageStretchDistortionFilter()
//        let stretchDistortionModel = LGFilterModel(filter: stretchDistortionFilter,
//                                                   filterName: "StretchDistortion",
//                                                   iconImage: exampleImage)
//        resultArray.append(stretchDistortionModel)
//
//
//        /// 凹面镜
//        let pinchDistortionFilter = GPUImagePinchDistortionFilter()
//        let pinchDistortionModel = LGFilterModel(filter: pinchDistortionFilter,
//                                                 filterName: "Cartoon",
//                                                 iconImage: exampleImage)
//        resultArray.append(pinchDistortionModel)
//
//        /// 反色
//        let colorInvertFilter = GPUImageColorInvertFilter()
//        let colorInvertModel = LGFilterModel(filter: colorInvertFilter,
//                                             filterName: "ColorInvert",
//                                             iconImage: exampleImage)
//        resultArray.append(colorInvertModel)
        
        return resultArray
    }()
    
    /// 切换前后摄像头的按钮
    lazy var toggleCameraButton: UIButton = {
        let tempButton = UIButton(type: UIButton.ButtonType.custom)
        tempButton.setImage(UIImage(namedFromThisBundle: "button_toggle_camera"),
                            for: UIControl.State.normal)
        tempButton.addTarget(self,
                             action: #selector(toggleCameraButtonPressed(_:)),
                             for: UIControl.Event.touchUpInside)
        return tempButton
    }()
    
    /// 显示焦距反馈的图片视图
    lazy var focusCursorImageView: UIImageView = {
        let temp = UIImageView(image: UIImage(namedFromThisBundle: "camera_focus"))
        temp.contentMode = UIView.ContentMode.scaleAspectFit
        temp.clipsToBounds = true
        temp.alpha = 0.0
        temp.frame = CGRect(x: 0, y: 0, width: 80.0, height: 80.0)
        return temp
    }()
    
    /// 视频写入路径，不是最终路径，本路径为裁切前的路径
    lazy var videoWritePath: String = {
        let tempDir = NSTemporaryDirectory()
        var pathExtension: String
        switch self.videoType {
        case .mov:
            pathExtension = ".mov"
            break
        case .mp4:
            pathExtension = ".mp4"
            break
        }
        let dirPath = tempDir + "LGCameraCapture/"
        let filePath = dirPath + NSUUID().uuidString + pathExtension
        do {
            if !FileManager.default.fileExists(atPath: dirPath) {
                try FileManager.default.createDirectory(atPath: dirPath,
                                                        withIntermediateDirectories: true,
                                                        attributes: nil)
            }
        } catch {
            println(error)
        }
        return filePath
    }()
    
    /// 展示拍摄到的图片的视图
    lazy var takedImageView: UIImageView = {
        let temp = UIImageView(frame: self.view.bounds)
        temp.backgroundColor = UIColor.black
        temp.isHidden = true
        temp.contentMode = UIView.ContentMode.scaleAspectFill
        return temp
    }()
    
    /// 拍摄到的照片
    var takedImage: UIImage?
    
    /// 视频最终路径
    var destinationVideoURL: URL {
        return URL(fileURLWithPath: self.videoWritePath)
    }
    
    /// 视频播放器视图
    lazy var playerView: LGPlayerView = {
        let playerView = LGPlayerView(frame: self.view.bounds,
                                      mediaURL: destinationVideoURL,
                                      isMuted: false)
        return playerView
    }()
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.layer.addSublayer(_previewLayer)
        _previewLayer.frame = UIScreen.main.bounds
        
        if allowFilters {
            self.filtersArray = self._filtersArray
        }
        
        self.setupSubviewsAndLayout()
        
        
        
        self.setupCamera()
        
        if self.allowTakePhoto == false && self.allowRecordVideo == false {
            fatalError("拍摄视频和拍照必须支持一个")
        }
        
        requestAccess()
        
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if LGAuthorizationStatusManager.default.cameraStatus == .denied {
            return
        }
        DispatchQueue.main.after(0.1) {
            self.captureSession.startRunning()
        }
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.captureSession.stopRunning()
    }
    
    weak var focusPanGesture: UIPanGestureRecognizer?
    weak var focusPinchGesture: UIPinchGestureRecognizer?
    
    // MARK: -  初始化视图
    func initCaptureSession() {
        do {
            captureSession.beginConfiguration()
            let preset = LGRecorderTools.bestCaptureSessionPresetCompatibleWithAllDevices
            captureSession.sessionPreset = preset
            try captureSession.addInput(AVCaptureDeviceInput(device: videoCamera))
            let output = AVCaptureVideoDataOutput()
            output.setSampleBufferDelegate(self, queue: DispatchQueue.userInteractive)
            captureSession.addOutput(output)
            captureSession.commitConfiguration()
            captureSession.startRunning()
            _previewLayer.session = captureSession
        } catch  {
            
        }
    }
    
    let filterToolViewHeight: CGFloat = 80.0
    let toolViewHeight: CGFloat = 130.0
    func setupSubviewsAndLayout() {
        if LGAuthorizationStatusManager.default.cameraStatus == .denied {
            return
        }
        self.view.backgroundColor = UIColor.black
        
        let toolViewOriginY = self.view.lg_height - toolViewHeight - UIDevice.bottomSafeMargin
        
        self.view.addSubview(takedImageView)
        
        
        filterToolView = LGFilterSelectionView(frame: CGRect(x: 0,
                                                             y: toolViewOriginY - filterToolViewHeight,
                                                             width: self.view.lg_width,
                                                             height: filterToolViewHeight))
        filterToolView.filtersArray = self.filtersArray
        filterToolView.delegate = self
        self.view.addSubview(filterToolView)
        
        toolView = LGCameraCaptureToolView(frame: CGRect.zero)
        toolView.delegate = self
        toolView.allowRecordVideo = self.allowRecordVideo
        toolView.allowTakePhoto = self.allowTakePhoto
        toolView.circleProgressColor = self.circleProgressColor
        toolView.maximumVideoRecordingDuration = self.maximumVideoRecordingDuration
        self.view.addSubview(toolView)
        
        self.view.addSubview(focusCursorImageView)
        
        if self.allowRecordVideo {
            let pan = UIPanGestureRecognizer(target: self, action: #selector(adjustCameraFocus(_:)))
            pan.maximumNumberOfTouches = 1
            self.view.addGestureRecognizer(pan)
            focusPanGesture = pan
        }
        
        if self.allowTakePhoto || self.allowRecordVideo {
            let pinch = UIPinchGestureRecognizer(target: self,
                                                 action: #selector(handlePinchToZoomRecognizer(_:)))
            self.view.addGestureRecognizer(pinch)
        }
        
        if self.allowSwitchDevicePosition {
            self.view.addSubview(toggleCameraButton)
        }
    }
    
    // MARK: - 视图frame更改
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if LGAuthorizationStatusManager.default.cameraStatus == .denied {
            return
        }
        let toolViewOriginY = self.view.lg_height - toolViewHeight - UIDevice.bottomSafeMargin
        
        filterToolView.frame = CGRect(x: 0,
                                      y: toolViewOriginY - filterToolViewHeight,
                                      width: self.view.lg_width,
                                      height: filterToolViewHeight)
        
        self.toolView.frame = CGRect(x: 0,
                                     y: self.view.lg_height - toolViewHeight - UIDevice.bottomSafeMargin,
                                     width: self.view.lg_width,
                                     height: toolViewHeight)
        
        
        
        
        let cropSize = getCropSize(self.view.lg_size)
        let previewFrame = CGRect(x: (self.view.lg_width - cropSize.width) / 2.0,
                                  y: (self.view.lg_height - cropSize.height) / 2.0,
                                  width: cropSize.width,
                                  height: cropSize.height)
        takedImageView.frame = previewFrame
        
        
        if allowSwitchDevicePosition {
            let toggleCameraButtonSize = CGSize(width: 30.0, height: 30.0)
            let toggleCameraButtonMargin: CGFloat = 20.0
            let originX = self.view.lg_width - toggleCameraButtonMargin - toggleCameraButtonSize.width
            self.toggleCameraButton.frame = CGRect(x: originX,
                                                   y: toggleCameraButtonMargin + UIDevice.topSafeMargin,
                                                   width: toggleCameraButtonSize.width,
                                                   height: toggleCameraButtonSize.height)
        }
    }
    
    /// 计算视频最终的输出大小
    ///
    /// - Returns: 视频最终的输出大小
    func getMovieRealOutputSize() -> CGSize {
        var outputSize = CGSize.zero
        
//        if let output = self.videoCamera.captureSession.outputs.last as? AVCaptureVideoDataOutput {
//            if let outputSettings = output.videoSettings {
//                var width = outputSettings["Width"] as? Int
//                var height = outputSettings["Height"] as? Int
//
//                if self.videoCamera.outputImageOrientation.isPortrait {
//                    let temp = width
//                    width = height
//                    height = temp
//                }
//                if let width = width, let height = height {
//                    outputSize = CGSize(width: width, height: height)
//                }
//            }
//        }
        return outputSize
    }
    
    
    
    // MARK: -  设置摄像头
    func setupCamera() {
        let deviceTypes = [AVCaptureDevice.DeviceType.builtInWideAngleCamera,
                           AVCaptureDevice.DeviceType.builtInUltraWideCamera,
                           AVCaptureDevice.DeviceType.builtInTelephotoCamera,
                           AVCaptureDevice.DeviceType.builtInDualCamera,
                           AVCaptureDevice.DeviceType.builtInDualWideCamera,
                           AVCaptureDevice.DeviceType.builtInTripleCamera,
                           AVCaptureDevice.DeviceType.builtInTrueDepthCamera]

        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: deviceTypes,
                                                                      mediaType: AVMediaType.video,
                                                                      position: AVCaptureDevice.Position.unspecified)
        let devices = deviceDiscoverySession.devices
        
        for device in devices {
            println(device.position.rawValue)
            if device.position == devicePosition {
                videoCamera = device
            } else {
                println("Other device position: ", device.position)
            }
        }
        

        
//        let movieRealOutputSize = getMovieRealOutputSize()
        
        
        self.filter = CIFilter()
        
//        movieWriter = GPUImageMovieWriter(movieURL: destinationVideoURL,
//                                          size: getFinalOutputSize(movieRealOutputSize),
//                                          fileType: videoAVFileType.rawValue,
//                                          outputSettings: nil)
//        movieWriter.hasAudioTrack = true
//        movieWriter.encodingLiveVideo = true
//        movieWriter.assetWriter.movieFragmentInterval = CMTime.invalid
//
//
//        let finalSize = getCropSize(movieRealOutputSize)
//
//        let cropedRect = CGRect(origin: CGPoint(x: ((movieRealOutputSize.width - finalSize.width) / 2.0) / movieRealOutputSize.width,
//                                                y: ((movieRealOutputSize.height - finalSize.height) / 2.0) / movieRealOutputSize.height),
//                                size: CGSize(width: finalSize.width / movieRealOutputSize.width,
//                                             height: finalSize.height / movieRealOutputSize.height))
//
//        cropFilter = GPUImageCropFilter(cropRegion: cropedRect)
//
//        videoCamera.addTarget(cropFilter)
//        if self.allowRecordVideo {
//            videoCamera.audioEncodingTarget = movieWriter
//        }
//
//
//        cropFilter.addTarget((self.filter as! GPUImageInput))
//        self.filter?.addTarget(movieWriter)
//        self.filter?.addTarget(_view)
    }
    
    // MARK: -  获取权限
    func requestAccess() {
        func requestCameraAccess() {
            AVCaptureDevice.requestAccess(for: AVMediaType.video) { [unowned self] (granted) in
                if granted {
                    if self.allowRecordVideo {
                        requestMicrophoneAccess()
                    } else {
                        // 拍照，无需获取麦克风权限
                    }
                    self.initCaptureSession()
                } else {
                    self.onDismiss()
                }
            }
        }
        
        requestCameraAccess()
        
        func requestMicrophoneAccess() {
            AVCaptureDevice.requestAccess(for: AVMediaType.audio, completionHandler: { [unowned self] (granted) in
                if granted {
                    do {
                        try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playAndRecord,
                                                                        mode: AVAudioSession.Mode.default)
                        try AVAudioSession.sharedInstance().setActive(true)
                    } catch {
                        println(error)
                    }
                } else {
                    self.onDismiss()
                }
            })
        }
        
        let sel = #selector(LGCameraCapture.willResignActive(_:))
        NotificationCenter.default.addObserver(self,
                                               selector: sel,
                                               name: UIApplication.willResignActiveNotification,
                                               object: nil)
        
    }
    
    // MARK: -  焦距相关
    private var pivotPinchScale: CGFloat = 0.0
    @objc func handlePinchToZoomRecognizer(_ pinch: UIPinchGestureRecognizer) {
        if let device = self.videoCamera {
            if pinch.state == .began {
                pivotPinchScale = device.videoZoomFactor
            }
            if pinch.state == .changed {
                do {
                    try device.lockForConfiguration()
                    let desiredZoomFactor = pivotPinchScale * pinch.scale
                    device.videoZoomFactor = max(1.0, min(desiredZoomFactor, device.activeFormat.videoMaxZoomFactor))
                    device.unlockForConfiguration()
                } catch {
                    println(error)
                }
            }
        }
    }
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        if !self.captureSession.isRunning { return }
        if let point = touches.first?.location(in: self.view) {
            if point.y > self.view.lg_height - 150.0 - UIDevice.bottomSafeMargin {
                return
            }
            setFocusCursorWithPoint(point)
        }
    }
    
    func setFocusCursorWithPoint(_ point: CGPoint) {
        focusCursorImageView.center = point
        focusCursorImageView.alpha = 1.0
        focusCursorImageView.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        UIView.animate(withDuration: 0.5,
                       animations:
            {
                self.focusCursorImageView.transform = CGAffineTransform.identity
        }) { (isFinished) in
            self.focusCursorImageView.alpha = 0.0
        }
        
        let cameraPoint = CGPoint(x: point.x / self.view.lg_width, y: point.y / self.view.lg_height)
        focusWithMode(AVCaptureDevice.FocusMode.autoFocus,
                      exposureMode: AVCaptureDevice.ExposureMode.autoExpose,
                      atPoint: cameraPoint)
    }
    
    func focusWithMode(_ focusMode: AVCaptureDevice.FocusMode,
                       exposureMode: AVCaptureDevice.ExposureMode,
                       atPoint point: CGPoint)
    {
        if let captureDevice = self.videoCamera {
            do {
                try captureDevice.lockForConfiguration()
                if captureDevice.isFocusModeSupported(focusMode) {
                    captureDevice.focusMode = focusMode
                }
                
                if captureDevice.isFocusPointOfInterestSupported {
                    captureDevice.focusPointOfInterest = point
                }
                captureDevice.unlockForConfiguration()
            } catch {
                println(error)
            }
        }
    }
    
    private var isDragStart: Bool = false
    @objc func adjustCameraFocus(_ pan: UIPanGestureRecognizer) {
        let cameraViewRect = self.toolView.convert(self.toolView.bottomView.frame, to: self.view)
        let point = pan.location(in: self.view)
        switch pan.state {
        case .began:
            if !cameraViewRect.contains(point) { return }
            isDragStart = true
            break
        case .changed:
            if !isDragStart { return }
            let zoomFactor = (cameraViewRect.midY - point.y) / cameraViewRect.midY * 5.0
            setVideoZoomFactor(min(max(zoomFactor, 1.0), 5.0))
            break
        case .cancelled, .ended:
            if !isDragStart { return }
            isDragStart = false
            break
        default:
            break
        }
    }
    
    func setVideoZoomFactor(_ zoomFactor: CGFloat) {
        if let captureDevice = self.videoCamera {
            do {
                try captureDevice.lockForConfiguration()
                captureDevice.videoZoomFactor = zoomFactor
                captureDevice.unlockForConfiguration()
            } catch {
                println(error)
            }
        }
    }
    
    // MARK: - 切换前后摄像头
    @objc func toggleCameraButtonPressed(_ sender: UIButton) {
        let deviceTypes = [AVCaptureDevice.DeviceType.builtInWideAngleCamera,
                           AVCaptureDevice.DeviceType.builtInUltraWideCamera,
                           AVCaptureDevice.DeviceType.builtInTelephotoCamera,
                           AVCaptureDevice.DeviceType.builtInDualCamera,
                           AVCaptureDevice.DeviceType.builtInDualWideCamera,
                           AVCaptureDevice.DeviceType.builtInTripleCamera,
                           AVCaptureDevice.DeviceType.builtInTrueDepthCamera]
        let frontSession = AVCaptureDevice.DiscoverySession(deviceTypes: deviceTypes,
                                                            mediaType: AVMediaType.video,
                                                            position: AVCaptureDevice.Position.front)
        let backSession = AVCaptureDevice.DiscoverySession(deviceTypes: deviceTypes,
                                                           mediaType: AVMediaType.video,
                                                           position: AVCaptureDevice.Position.back)
        if frontSession.devices.count > 0, backSession.devices.count > 0 {
            do {
                
                let animation = CATransition()
                animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
                animation.duration = 0.5
                animation.isRemovedOnCompletion = true
                animation.type = CATransitionType(rawValue: "oglFlip")
                if self.devicePosition == .back {
                    self.captureSession.beginConfiguration()
                    animation.subtype = CATransitionSubtype.fromLeft
                    _previewLayer.add(animation, forKey: nil)
                    let inputs = self.captureSession.inputs
                    for input in inputs {
                        self.captureSession.removeInput(input)
                    }
                    for device in frontSession.devices {
                        let input = try AVCaptureDeviceInput(device: device)
                        if self.captureSession.canAddInput(input) {
                            self.captureSession.addInput(input)
                        }
                    }
                    self.devicePosition = .front
                    self.captureSession.commitConfiguration()
        
                } else {
                    self.captureSession.beginConfiguration()
                    animation.subtype = CATransitionSubtype.fromRight
                    _previewLayer.add(animation, forKey: nil)
                    let inputs = self.captureSession.inputs
                    for input in inputs {
                        self.captureSession.removeInput(input)
                    }
                    for device in backSession.devices {
                        let input = try AVCaptureDeviceInput(device: device)
                        if self.captureSession.canAddInput(input) {
                            self.captureSession.addInput(input)
                        }
                    }
                    self.devicePosition = .back
                    self.captureSession.commitConfiguration()
                }
            } catch {
                
            }
        } else {
            println("摄像头数量不足")
        }
    }
    
    // MARK: - 程序将要不活跃的时候关闭本页面
    @objc func willResignActive(_ noti: Notification) {
        if self.captureSession.isRunning {
            self.delegate?.captureDidCancel(self)
        }
    }
    
    override open var prefersStatusBarHidden: Bool {
        return true
    }
    
    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.portrait
    }
    
    ///析构
    deinit {
        _previewLayer.removeFromSuperlayer()
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
        do {
            try AVAudioSession.sharedInstance().setActive(false,
                                                          options: .notifyOthersOnDeactivation)
        } catch {
            println(error)
        }
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - 状态条
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    /// 是否正在录制
    private var isRecording: Bool = false
}

extension LGCameraCapture: LGCameraCaptureToolViewDelegate {
    /// 拍照
    public func onTakePicture() {
//        filter?.useNextFrameForImageCapture()
//        if let image = filter?.imageFromCurrentFramebuffer() {
//            self.videoCamera.stopCapture()
//            self.takedImage = image
//            self.takedImageView.image = image
//            self.takedImageView.isHidden = false
//        }
        self.toggleCameraButton.isHidden = true
        
        if isShutterSoundEnabled {
            AudioServicesPlaySystemSound(1108)
        }
    }
    
    /// 开始录制视频
    public func onStartRecord() {
        if !isRecording {
//            self.movieWriter.startRecording()
            self.toolView.startAnimate()
        }
    }
    
    /// 完成视频录制
    public func onFinishedRecord() {
        self.setVideoZoomFactor(1)
//        self.videoCamera.stopCapture()
//        movieWriter.finishRecording {
//            DispatchQueue.main.async {
//                self.isRecording = false
//                self.toggleCameraButton.isHidden = true
//                self.playVideo()
//            }
//        }
        
    }
    
    /// 录制完成后播放视频
    func playVideo() {
        if self.playerView.superview == nil {
            self.playerView.frame = self.view.bounds
            self.playerView.player.isLoopEnabled = true
            self.view.insertSubview(playerView, belowSubview: self.toolView)
        }
        self.playerView.isHidden = false
        self.playerView.player.setItemBy(destinationVideoURL)
        self.playerView.play()
    }
    
    /// 放弃现有内容，重拍
    public func onRetake() {
        reset()
    }
    
    /// 重置摄像机，删除视频和图片
    func reset() {
        resetVideoCamera()
        self.toolView.resetLayout()
//        self.videoCamera.startCapture()
        self.setFocusCursorWithPoint(self.view.center)
        
        self.takedImageView.isHidden = true
        self.takedImage = nil
        
        self.toggleCameraButton.isHidden = false
        self.playerView.isHidden = true
        self.playerView.pause()
        self.playerView.player.replaceCurrentItem(with: nil)
        
        removeVideo()
    }
    
    func removeVideo() {
        do {
            if FileManager.default.fileExists(atPath: self.videoWritePath) {
                try FileManager.default.removeItem(at: destinationVideoURL)
            }
        } catch {
            println(error)
        }
    }
    
    func resetVideoCamera() {
//        self.filter?.removeAllTargets()
//        self.videoCamera.removeAllTargets()
//        self.cropFilter.removeAllTargets()
//        self.videoCamera.audioEncodingTarget = nil
//        let outputSize = getMovieRealOutputSize()
//        self.movieWriter = GPUImageMovieWriter(movieURL: destinationVideoURL,
//                                               size: getFinalOutputSize(outputSize),
//                                               fileType: videoAVFileType.rawValue,
//                                               outputSettings: nil)
//        movieWriter.hasAudioTrack = true
//        movieWriter.encodingLiveVideo = true
//        movieWriter.assetWriter.movieFragmentInterval = CMTime.invalid
//
//        self.videoCamera.addTarget(self.cropFilter)
//        if self.allowRecordVideo {
//            self.videoCamera.audioEncodingTarget = movieWriter
//        }
//
//        if let filter = self.filter {
//            self.cropFilter.addTarget(filter as? GPUImageInput)
//            filter.addTarget(movieWriter)
//            filter.addTarget(_view)
//        } else {
//            cropFilter.addTarget(movieWriter)
//            cropFilter.addTarget(_view)
//        }
    }

    /// 拍摄完成返回结果
    public func onDoneClick() {
        var result: ResultModel
        if let image = self.takedImage {
            result = ResultModel(type: .photo, image: image, videoURL: nil)
        } else {
            result = ResultModel(type: .video, image: nil, videoURL: destinationVideoURL)
        }
        delegate?.captureDidCapturedResult(result, capture: self)
    }
    
    /// 取消拍摄并清理拍摄到的视频
    public func onDismiss() {
        self.delegate?.captureDidCancel(self)
        DispatchQueue.background.async { [weak self] in
            self?.removeVideo()
        }
    }
}


extension LGCameraCapture {
    /// 计算裁切后的最大大小，用于显示
    ///
    /// - Parameter originSize: 原始视频大小
    /// - Returns: 裁切后的大小
    func getCropSize(_ originSize: CGSize) -> CGSize {
        if  self.outputSize.width > 0.0,
            self.outputSize.width <= 1.0,
            self.outputSize.height > 0.0,
            self.outputSize.height <= 1.0
        {
            /// 正常的相对大小
            return CGSize(width: originSize.width * self.outputSize.width,
                          height: originSize.height * self.outputSize.height)
        } else if self.outputSize.width > 1.0, self.outputSize.height > 1.0 {
            /// 正常的绝对大小
            let ratio = self.outputSize.width / self.outputSize.height
            if originSize.width / originSize.height > ratio {
                return CGSize(width: originSize.height * ratio, height: originSize.height)
            } else if originSize.width / originSize.height == ratio {
                return originSize
            } else {
                return CGSize(width: originSize.width, height: originSize.width / ratio)
            }
        } else {
            /// 异常
            return originSize
        }
    }
    
    
    /// 计算最终输出大小，如果是相对坐标，则根据视频录制设备支持的最佳大小输出，如果是绝对坐标，则为输入的绝对大小
    ///
    /// - Parameter originSize: 视频的原始大小
    /// - Returns: 计算后的大小
    func getFinalOutputSize(_ originSize: CGSize) -> CGSize {
        if  self.outputSize.width > 0.0,
            self.outputSize.width <= 1.0,
            self.outputSize.height > 0.0,
            self.outputSize.height <= 1.0
        {
            /// 正常的相对大小
            return CGSize(width: originSize.width * self.outputSize.width,
                          height: originSize.height * self.outputSize.height)
        } else {
            return self.outputSize
        }
    }
}

extension LGCameraCapture: LGFilterSelectionViewDelegate {
    /// 更换滤镜
    ///
    /// - Parameter filter: 新滤镜对象
    public func didSelectedFilter(_ filter: CIFilter) {
//        cropFilter.removeTarget(self.filter as? GPUImageInput)
//        cropFilter.removeTarget(self.movieWriter)
//        self.filter?.removeAllTargets()
//        
//        filter.removeAllTargets()
//        self.filter = filter
//        
//        cropFilter.addTarget(filter)
//        self.filter?.addTarget(self.movieWriter)
//        self.filter?.addTarget(_view)
    }
}

extension LGCameraCapture: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput,
                              didDrop sampleBuffer: CMSampleBuffer,
                              from connection: AVCaptureConnection)
    {
        
    }
    
    public func captureOutput(_ output: AVCaptureOutput,
                              didOutput sampleBuffer: CMSampleBuffer,
                              from connection: AVCaptureConnection)
    {
        
    }
}

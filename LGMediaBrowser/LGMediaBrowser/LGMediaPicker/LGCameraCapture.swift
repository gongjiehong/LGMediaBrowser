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
import GPUImage

/// 拍照或录像完成的回调
public protocol LGCameraCaptureDelegate: NSObjectProtocol {
    func captureDidCancel(_ capture: LGCameraCapture)
    func captureDidCapturedResult(_ result: LGCameraCapture.ResultModel, capture: LGCameraCapture)
}

/// 拍照和录制视频自定义类
public class LGCameraCapture: UIViewController {
    private var _view: GPUImageView = GPUImageView(frame: CGRect.zero)
    
    override open func loadView() {
        super.loadView()
        self.view = _view
        self.view.frame = UIScreen.main.bounds
    }
    
    /// 视频格式定义
    ///
    /// - mp4: mp4
    /// - mov: mov
    public enum VideoType {
        case mp4
        case mov
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
    
    /// 是否允许拍照
    public var allowTakePhoto: Bool = true
    
    /// 是否允许录制视频
    public var allowRecordVideo: Bool = true
    
    /// 是否允许切换摄像头，需配合devicePosition使用
    public var allowSwitchDevicePosition: Bool = true
    
    /// 指定使用前置还是后置摄像头
    public var devicePosition: AVCaptureDevice.Position = AVCaptureDevice.Position.back
    
    /// 输出文件大小
    /// 可以是相对坐标（(1.0, 0.5), (ScreenSize.width * 1.0 px, ScreenSize.height * 0.5 px)）
    /// 也可以是绝对坐标 ((320, 320) 所有设备都输出320px * 320px的视频)
    public var outputSize: CGSize = CGSize(width: 1, height: 1)
    
    /// 输出视频格式
    public var videoType: VideoType = .mp4
    
    /// 视频进度条颜色
    public var circleProgressColor: UIColor = UIColor.blue
    
    /// 拍照时是否播放快门音，默认开启
    public var isShutterSoundEnabled: Bool = true
    
    /// 回调
    public weak var delegate: LGCameraCaptureDelegate?
    
    /// 录制，返回，完成等按钮的工具条
    var toolView: LGCameraCaptureToolView!
    
    var videoCamera: GPUImageVideoCamera!
    
    var filter: GPUImageFilter?
    
    var cropFilter: GPUImageFilter!
    
    var movieWriter: GPUImageMovieWriter!
    
    /// 切换前后摄像头的按钮
    lazy var toggleCameraBtn: UIButton = {
        let tempBtn = UIButton(type: UIButtonType.custom)
        tempBtn.setImage(UIImage(namedFromThisBundle: "btn_toggle_camera"), for: UIControlState.normal)
        tempBtn.addTarget(self, action: #selector(toggleCameraBtnPressed(_:)), for: UIControlEvents.touchUpInside)
        return tempBtn
    }()
    
    /// 显示焦距反馈的图片视图
    lazy var focusCursorImageView: UIImageView = {
        let temp = UIImageView(image: UIImage(namedFromThisBundle: "camera_focus"))
        temp.contentMode = UIViewContentMode.scaleAspectFit
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
        temp.contentMode = UIViewContentMode.scaleAspectFill
        return temp
    }()
    
    /// 拍摄到的照片
    var takedImage: UIImage?
    
    /// 视频最终路径
    var destinationVideoURL: URL?
    
    lazy var playerView: LGPlayerView = {
        let playerView = LGPlayerView(frame: self.view.bounds,
                                      mediaURL: URL(fileURLWithPath: videoWritePath),
                                      isMuted: false)
        return playerView
    }()
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupSubviewsAndLayout()
        self.setupCamera()
        
        if self.allowTakePhoto == false && self.allowRecordVideo == false {
            fatalError("拍摄视频和拍照必须支持一个")
        }
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.after(0.1) {
            self.videoCamera.startCapture()
        }
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.videoCamera.stopCapture()
    }
    
    weak var focusPanGesture: UIPanGestureRecognizer?
    
    // MARK: -  初始化视图
    func setupSubviewsAndLayout() {
        self.view.backgroundColor = UIColor.black
        
        toolView = LGCameraCaptureToolView(frame: CGRect.zero)
        toolView.delegate = self
        toolView.allowRecordVideo = self.allowRecordVideo
        toolView.allowTakePhoto = self.allowTakePhoto
        toolView.circleProgressColor = self.circleProgressColor
        toolView.maximumVideoRecordingDuration = self.maximumVideoRecordingDuration
        self.view.addSubview(toolView)
        
        if self.allowRecordVideo {
            self.view.addSubview(focusCursorImageView)
            let pan = UIPanGestureRecognizer(target: self, action: #selector(adjustCameraFocus(_:)))
            pan.maximumNumberOfTouches = 1
            self.view.addGestureRecognizer(pan)
            focusPanGesture = pan
        }
        
        if self.allowSwitchDevicePosition {
            self.view.addSubview(toggleCameraBtn)
        }
    }
    
    // MARK: - 视图frame更改
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let toolViewHeight: CGFloat = 130.0
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
            let toggleCameraBtnSize = CGSize(width: 30.0, height: 30.0)
            let toggleCameraBtnMargin: CGFloat = 20.0
            self.toggleCameraBtn.frame = CGRect(x: self.view.lg_width - toggleCameraBtnMargin - toggleCameraBtnSize.width,
                                                y: toggleCameraBtnMargin + UIDevice.topSafeMargin,
                                                width: toggleCameraBtnSize.width,
                                                height: toggleCameraBtnSize.height)
        }
    }
    
    // MARK: -  获取摄像头设备
    var frontCamera: AVCaptureDevice? {
        return cameraWithPosition(AVCaptureDevice.Position.front)
    }
    
    var backCamera: AVCaptureDevice? {
        return cameraWithPosition(AVCaptureDevice.Position.back)
    }
    
    func cameraWithPosition(_ position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let devices = AVCaptureDevice.devices(for: AVMediaType.video)
        for device in devices where device.position == position {
            return device
        }
        return nil
    }

 
    // MARK: -  设置摄像头
    func setupCamera() {
        let preset = LGRecorderTools.bestCaptureSessionPresetCompatibleWithAllDevices
        
        videoCamera = GPUImageVideoCamera(sessionPreset: preset.rawValue,
                                          cameraPosition: self.devicePosition)
        videoCamera.outputImageOrientation = UIInterfaceOrientation.portrait
        videoCamera.horizontallyMirrorFrontFacingCamera = false
        videoCamera.horizontallyMirrorRearFacingCamera = false

        var fileType: AVFileType
        if self.videoType == .mov {
            fileType = AVFileType.mov
        } else {
            fileType = AVFileType.mp4
        }
        
        var outputSize = CGSize.zero
        
        if let output = self.videoCamera.captureSession.outputs.last as? AVCaptureVideoDataOutput {
            if let outputSettings = output.videoSettings {
                var width = outputSettings["Width"] as? Int
                var height = outputSettings["Height"] as? Int
                
                if self.videoCamera.outputImageOrientation.isPortrait {
                    let temp = width
                    width = height
                    height = temp
                }
                if let width = width, let height = height {
                    outputSize = CGSize(width: width, height: height)
                }
            }
        }
        
        
        
        
        movieWriter = GPUImageMovieWriter(movieURL: URL(fileURLWithPath: videoWritePath),
                                          size: getFinalOutputSize(outputSize),
                                          fileType: fileType.rawValue,
                                          outputSettings: nil)
        movieWriter.encodingLiveVideo = true
        
        
        let finalSize = getCropSize(outputSize)
        
        let cropedRect = CGRect(origin: CGPoint(x: ((outputSize.width - finalSize.width) / 2.0) / outputSize.width,
                                                y: ((outputSize.height - finalSize.height) / 2.0) / outputSize.height),
                                size: CGSize(width: finalSize.width / outputSize.width,
                                             height: finalSize.height / outputSize.height))
        
        cropFilter = GPUImageCropFilter(cropRegion: cropedRect)
        
        videoCamera.addTarget(cropFilter)
        videoCamera.audioEncodingTarget = movieWriter

        cropFilter.addTarget(movieWriter)
        if let filterView = self.view as? GPUImageView {
            cropFilter.addTarget(filterView)
        }
    }
    
    // MARK: -  获取权限
    
    func requestAccess() {
        AVCaptureDevice.requestAccess(for: AVMediaType.video) { [unowned self] (granted) in
            if granted {
                AVCaptureDevice.requestAccess(for: AVMediaType.audio, completionHandler: { [unowned self] (granted) in
                    if granted {
                        NotificationCenter.default.addObserver(self,
                                                               selector: #selector(LGCameraCapture.willResignActive(_:)),
                                                               name: NSNotification.Name.UIApplicationWillResignActive,
                                                               object: nil)
                    } else {
                        self.onDismiss()
                    }
                })
            } else {
                self.onDismiss()
            }
        }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            println(error)
        }
    }
    
    // MARK: -  焦距相关
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !self.videoCamera.isRunning { return }
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
        if let captureDevice = self.videoCamera.inputCamera {
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
            onStartRecord()
            break
        case .changed:
            if !isDragStart { return }
            let zoomFactor = (cameraViewRect.midY - point.y) / cameraViewRect.midY * 5.0
            setVideoZoomFactor(min(max(zoomFactor, 1.0), 5.0))
            break
        case .cancelled, .ended:
            if !isDragStart { return }
            isDragStart = false
            self.onFinishedRecord()
            self.toolView.stopAnimate()
            break
        default:
            break
        }
    }
    
    func setVideoZoomFactor(_ zoomFactor: CGFloat) {
        if let captureDevice = self.videoCamera.inputCamera{
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
    @objc func toggleCameraBtnPressed(_ sender: UIButton) {
        let cameraCount = AVCaptureDevice.devices(for: AVMediaType.video).count
        if cameraCount > 1 {
            self.videoCamera.rotateCamera()
        } else {
            println("摄像头数量不足")
        }
    }
    
    // MARK: - 程序将要不活跃的时候关闭本页面
    @objc func willResignActive(_ noti: Notification) {
        if self.videoCamera.isRunning {
            self.dismiss(animated: true, completion: nil)
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
        if videoCamera.isRunning {
            videoCamera.stopCapture()
        }
        do {
            try AVAudioSession.sharedInstance().setActive(false,
                                                          with: .notifyOthersOnDeactivation)
        } catch {
            println(error)
        }
        NotificationCenter.default.removeObserver(self)
    }
    
    /// 是否正在录制
    private var isRecording: Bool = false
}

extension LGCameraCapture: LGCameraCaptureToolViewDelegate {
    public func onTakePicture() {
        cropFilter.useNextFrameForImageCapture()
        if let image = cropFilter.imageFromCurrentFramebuffer() {
            self.videoCamera.stopCapture()
            self.takedImage = image
            self.takedImageView.image = image
            self.takedImageView.isHidden = false
        }
        
        self.toggleCameraBtn.isHidden = true
        
        if isShutterSoundEnabled {
            AudioServicesPlaySystemSound(1108)
        }
    }
    
    public func onStartRecord() {
        if !isRecording {
            self.movieWriter.startRecording()
        }
    }
    
    public func onFinishedRecord() {
        self.movieWriter.startRecording()
        self.setVideoZoomFactor(1)
        movieWriter.finishRecording()
        isRecording = false
        self.toggleCameraBtn.isHidden = true
        playVideo()
    }
    
    func playVideo() {
        if self.playerView.superview == nil {
            self.playerView.frame = self.view.bounds
            self.view.insertSubview(playerView, belowSubview: self.toolView)
        }
        self.playerView.play()
    }
    
    public func onRetake() {
        reset()
    }
    
    func reset() {
        self.toolView.resetLayout()
        self.videoCamera.startCapture()
        self.setFocusCursorWithPoint(self.view.center)
        self.takedImageView.isHidden = true
        self.takedImage = nil
        self.toggleCameraBtn.isHidden = false
        DispatchQueue.utility.async {
            do {
                try FileManager.default.removeItem(at: URL(fileURLWithPath: self.videoWritePath))
            } catch {
                println(error)
            }
        }
    }
    
    public func onDoneClick() {
        
    }
    
    public func onDismiss() {
        self.delegate?.captureDidCancel(self)
        self.dismiss(animated: true) {
            
        }
    }
}


extension LGCameraCapture {
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


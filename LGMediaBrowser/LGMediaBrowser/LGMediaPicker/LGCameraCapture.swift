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

/// 拍照或录像完成的回调
public protocol LGCameraCaptureDelegate: NSObjectProtocol {
    func captureDidCancel(_ capture: LGCameraCapture)
    func captureDidCapturedResult(_ result: LGCameraCapture.ResultModel, capture: LGCameraCapture)
}

/// 拍照和录制视频自定义类
public class LGCameraCapture: UIViewController {
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
    public var devicePosition: AVCaptureDevice.Position = AVCaptureDevice.Position.unspecified
    
    /// 输出文件大小
    /// 可以是相对坐标（(1.0, 0.5), (ScreenSize.width * 1.0 px, ScreenSize.height * 0.5 px)）
    /// 也可以是绝对坐标 ((320, 320) 所有设备都输出320px * 320px的视频)
    public var outputSize: CGSize = CGSize(width: 1, height: 1)
    
    /// 输出视频格式
    public var videoType: VideoType = .mp4
    
    /// 视频进度条颜色
    public var circleProgressColor: UIColor = UIColor.blue
    
    /// 回调
    public weak var delegate: LGCameraCaptureDelegate?
    
    /// 录制，返回，完成等按钮的工具条
    var toolView: LGCameraCaptureToolView!
    
    /// 录制Session
    var session: AVCaptureSession = AVCaptureSession()
    
    /// 输入设备
    var videoInput: AVCaptureDeviceInput?
    
    /// 图片输出
    var imageOutPut: AVCaptureStillImageOutput = AVCaptureStillImageOutput()
    
    /// 录制好的视频写入磁盘相关
    var videoFileOutput: AVCaptureMovieFileOutput = AVCaptureMovieFileOutput()
    
    /// 显示录制过程的Layer
    var previewLayer: AVCaptureVideoPreviewLayer!
    
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
    
    /// 拍摄到的视频播放器
    var playerView: LGPlayerView?
    
    /// 视频最终路径
    var destinationVideoURL: URL?
    
    /// 方向感应
    lazy var motionManager: CMMotionManager = {
        let temp = CMMotionManager()
        temp.deviceMotionUpdateInterval = 0.5
        return temp
    }()
    
    /// 视频方向
    var orientation: AVCaptureVideoOrientation = .portraitUpsideDown
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupSubviewsAndLayout()
        self.setupCamera()
        self.observeDeviceMotion()
        
        if self.allowTakePhoto == false && self.allowRecordVideo == false {
            fatalError("拍摄视频和拍照必须支持一个")
        }
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.session.startRunning()
        self.setFocusCursorWithPoint(self.view.center)
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.session.stopRunning()
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.motionManager.stopDeviceMotionUpdates()
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
        var finalSize = getFinalOutputSize(self.view.lg_size)
        if finalSize.width > self.view.lg_width {
            let ratio = finalSize.width / self.view.lg_width
            finalSize = CGSize(width: self.view.lg_width, height: finalSize.height / ratio)
        } else if finalSize.height > self.view.lg_height {
            let ratio = finalSize.height / self.view.lg_height
            finalSize = CGSize(width: finalSize.width / ratio, height: self.view.lg_height)
        }
        let previewFrame = CGRect(x: (self.view.lg_width - finalSize.width) / 2.0,
                                  y: (self.view.lg_height - finalSize.height) / 2.0,
                                  width: finalSize.width,
                                  height: finalSize.height)
        
        previewLayer.frame = previewFrame

        
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
        if let device = self.backCamera {
            do {
                self.videoInput = try AVCaptureDeviceInput(device: device)
                if self.session.canAddInput(self.videoInput!) {
                    self.session.addInput(self.videoInput!)
                }
            } catch {
                println(error)
            }
        }
        
        let outputSetting = [AVVideoCodecKey: AVVideoCodecJPEG]
        self.imageOutPut.outputSettings = outputSetting
        
        if let device = AVCaptureDevice.devices(for: AVMediaType.audio).first {
            do {
                let audioInput = try AVCaptureDeviceInput(device: device)
                
                if self.session.canAddInput(audioInput) {
                    self.session.addInput(audioInput)
                }
            } catch {
                println(error)
            }
        }
        
        if self.session.canAddOutput(self.imageOutPut) {
            self.session.addOutput(self.imageOutPut)
        }
        
        if self.session.canAddOutput(self.videoFileOutput) {
            self.session.addOutput(self.videoFileOutput)
        }
        
        if self.session.canSetSessionPreset(AVCaptureSession.Preset.high) {
            self.session.sessionPreset = AVCaptureSession.Preset.high
        }
        
        self.previewLayer = AVCaptureVideoPreviewLayer(session: self.session)
        self.previewLayer.frame = self.view.bounds
        self.previewLayer.masksToBounds = true
        self.previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        self.view.layer.insertSublayer(self.previewLayer, at: 0)
    }
    
    // MARK: -  监控设备方向，处理视频和图片的方向
    func observeDeviceMotion() {
        if motionManager.isDeviceMotionAvailable {
            motionManager.startDeviceMotionUpdates(to: OperationQueue.main) { [weak self] (motion, error) in
                if let motion = motion, error == nil {
                    self?.handleDeviceMotion(motion)
                }
            }
        } else {
            motionManager.stopDeviceMotionUpdates()
        }
    }
    
    func handleDeviceMotion(_ motion: CMDeviceMotion) {
        let x = motion.gravity.x
        let y = motion.gravity.y
        
        if fabs(y) >= fabs(x) {
            if y >= 0 {
                self.orientation = AVCaptureVideoOrientation.portraitUpsideDown
            } else {
                self.orientation = AVCaptureVideoOrientation.portrait
            }
        } else {
            if x >= 0 {
                self.orientation = AVCaptureVideoOrientation.landscapeLeft
            } else {
                self.orientation = AVCaptureVideoOrientation.landscapeRight
            }
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
        if !self.session.isRunning { return }
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
        
        let cameraPoint = self.previewLayer.captureDevicePointConverted(fromLayerPoint: point)
        focusWithMode(AVCaptureDevice.FocusMode.autoFocus,
                      exposureMode: AVCaptureDevice.ExposureMode.autoExpose,
                      atPoint: cameraPoint)
    }
    
    func focusWithMode(_ focusMode: AVCaptureDevice.FocusMode,
                       exposureMode: AVCaptureDevice.ExposureMode,
                       atPoint point: CGPoint)
    {
        if let captureDevice = self.videoInput?.device {
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
            if cameraViewRect.contains(point) { return }
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
        if let captureDevice = self.videoInput?.device {
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
            var newVideoInput: AVCaptureDeviceInput?
            do {
                if let position = self.videoInput?.device.position {
                    switch position {
                    case .back:
                        if let frontCamera = self.frontCamera {
                            newVideoInput = try AVCaptureDeviceInput(device: frontCamera)
                        }
                        break
                    case .front:
                        if let backCamera = self.backCamera {
                            newVideoInput = try AVCaptureDeviceInput(device: backCamera)
                        }
                        break
                    default:
                        break
                    }
                    
                }
            } catch {
                println(error)
            }
            if let newVideoInput = newVideoInput, let originInput = self.videoInput {
                self.session.beginConfiguration()
                self.session.removeInput(originInput)
                if self.session.canAddInput(newVideoInput) {
                    self.session.addInput(newVideoInput)
                    self.videoInput = newVideoInput
                } else {
                    self.session.addInput(originInput)
                }
                self.session.commitConfiguration()
            } else {
                println("originInput 或 newVideoInput 异常")
            }
        } else {
            println("摄像头数量不足")
        }
    }
    
    // MARK: - 程序将要不活跃的时候关闭本页面
    @objc func willResignActive(_ noti: Notification) {
        if self.session.isRunning {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    override open var prefersStatusBarHidden: Bool {
        return true
    }
    
    ///析构
    deinit {
        if session.isRunning {
            session.stopRunning()
        }
        do {
            try AVAudioSession.sharedInstance().setActive(false,
                                                          with: .notifyOthersOnDeactivation)
        } catch {
            println(error)
        }
        NotificationCenter.default.removeObserver(self)
    }
}

extension LGCameraCapture: LGCameraCaptureToolViewDelegate {
    public func onTakePicture() {
        if let videoConnection = self.imageOutPut.connection(with: AVMediaType.video) {
            videoConnection.videoOrientation = self.orientation
            if takedImageView.superview == nil {
                takedImageView.frame = self.view.bounds
                self.view.insertSubview(takedImageView, belowSubview: toolView)
            }
            
            
            
            self.imageOutPut.captureStillImageAsynchronously(from: videoConnection) { [weak self] (buffer, error) in
                guard let weakSelf = self else { return }
                if let buffer = buffer {
                    weakSelf.session.stopRunning()
                    guard let data = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer) else {
                        println("读取照片data失败")
                        return
                    }
                    
                    var image = UIImage(data: data)
                    
                    if let tempImage = image, let imageSize = image?.size {
                        let finalSize = weakSelf.getFinalOutputSize(imageSize)
                        image = tempImage.lg_imageByCropToRect(CGRect(x: (imageSize.height - finalSize.height) / 2.0,
                                                                      y: (imageSize.width - finalSize.width) / 2.0,
                                                                      width: finalSize.height,
                                                                      height: finalSize.width))
                    }
                    
                    weakSelf.takedImage = image
                    weakSelf.takedImageView.image = image
                    weakSelf.takedImageView.isHidden = false
                } else {
                    println("读取照片buffer失败")
                }
            }
            
        } else {
            println("拍照失败")
        }
    }
    
    public func onStartRecord() {
        focusPanGesture?.isEnabled = true
        
        let movieConnection = self.videoFileOutput.connection(with: AVMediaType.video)
        movieConnection?.videoOrientation = self.orientation
        movieConnection?.videoScaleAndCropFactor = 1.0
        
        if !videoFileOutput.isRecording {
            let url = URL(fileURLWithPath: self.videoWritePath)
            self.videoFileOutput.startRecording(to: url, recordingDelegate: self)
        }
    }
    
    public func onFinishedRecord() {
        focusPanGesture?.isEnabled = false
        self.session.stopRunning()
        self.setVideoZoomFactor(1)
    }
    
    public func onRetake() {
        self.toolView.resetLayout()
        self.session.startRunning()
        self.setFocusCursorWithPoint(self.view.center)
        self.takedImageView.isHidden = true
    }
    
    public func onDoneClick() {
        
    }
    
    public func onDismiss() {
        self.delegate?.captureDidCancel(self)
        self.dismiss(animated: true) {
            
        }
    }
}


extension LGCameraCapture: AVCaptureFileOutputRecordingDelegate {
    public func fileOutput(_ output: AVCaptureFileOutput,
                           didStartRecordingTo fileURL: URL,
                           from connections: [AVCaptureConnection])
    {
        self.toolView.startAnimate()
    }
    
    
    public func fileOutput(_ output: AVCaptureFileOutput,
                           didFinishRecordingTo outputFileURL: URL,
                           from connections: [AVCaptureConnection],
                           error: Error?)
    {
        if output.recordedDuration.seconds < 1 {
            self.onRetake()
            return
        }
        
        croppedVideo(outputFileURL) { (videoURL) in
            
        }
    }
    
    func croppedVideo(_ videoURL: URL, completed: @escaping (URL?) -> Void) {
        let videoAsset = AVAsset(url: videoURL)
        
        let mixComposition = AVMutableComposition()
        
        guard   let videoTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.video,
                                                                preferredTrackID: kCMPersistentTrackID_Invalid),
            let audioTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.audio,
                                                            preferredTrackID: kCMPersistentTrackID_Invalid)
            else
        {
            completed(nil)
            return
        }
        
        guard   let videoAssetTrack = videoAsset.tracks(withMediaType: AVMediaType.video).first,
            let audioAssertTrack = videoAsset.tracks(withMediaType: AVMediaType.audio).first
            else
        {
            completed(nil)
            return
        }
        
        do {
            try videoTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, videoAsset.duration),
                                           of: videoAssetTrack,
                                           at: kCMTimeZero)
            try audioTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, videoAsset.duration),
                                           of: audioAssertTrack,
                                           at: kCMTimeZero)
            
            let mainInstruction = AVMutableVideoCompositionInstruction()
            mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, videoAsset.duration)
            
            let videolayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
            
            var isVideoAssetPortrait = false
            
            let videoTransform = videoAssetTrack.preferredTransform
            
            if videoTransform.a == 0 && videoTransform.b == 1.0 && videoTransform.c == -1.0 && videoTransform.d == 0 {
                isVideoAssetPortrait = true
            }
            
            if videoTransform.a == 0 && videoTransform.b == -1.0 && videoTransform.c == 1.0 && videoTransform.d == 0 {
                isVideoAssetPortrait = true
            }
            
            videolayerInstruction.setTransform(videoTransform, at: kCMTimeZero)
            videolayerInstruction.setOpacity(0.0, at: videoAsset.duration)
            
            mainInstruction.layerInstructions = [videolayerInstruction]
            
            let mainCompositionInst = AVMutableVideoComposition()
            var naturalSize: CGSize
            if isVideoAssetPortrait {
                naturalSize = CGSize(width: videoAssetTrack.naturalSize.height,
                                     height: videoAssetTrack.naturalSize.width)
            } else {
                naturalSize = videoAssetTrack.naturalSize
            }
            
//            var renderWidth = naturalSize.width
//            var renderHeight = naturalSize.height
//
//            let value = (renderWidth > renderHeight) ? renderHeight : renderWidth
            mainCompositionInst.renderSize = getFinalOutputSize(naturalSize)
            mainCompositionInst.instructions = [mainInstruction]
            mainCompositionInst.frameDuration = CMTimeMake(1, framePerSecond)
            
            guard   let exporter = AVAssetExportSession(asset: mixComposition,
                                                        presetName: AVAssetExportPresetHighestQuality)
                else
            {
                completed(nil)
                return
            }
            let tempDir = NSTemporaryDirectory() + "LGCameraCapture"
            let tempPath = tempDir + UUID().uuidString + videoURL.pathExtension
            
            exporter.outputURL = URL(fileURLWithPath: tempPath)
            if self.videoType == .mov {
                exporter.outputFileType = AVFileType.mov
            } else {
                exporter.outputFileType = AVFileType.mp4
            }
            exporter.shouldOptimizeForNetworkUse = true
            exporter.videoComposition = mainCompositionInst
            exporter.exportAsynchronously {
                switch exporter.status {
                case .completed:
                    completed(exporter.outputURL)
                    break
                case .cancelled, .failed:
                    completed(nil)
                    break
                default:
                    break
                }
            }
            
        } catch {
            completed(nil)
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
        } else if self.outputSize.width > 1.0, self.outputSize.height > 1.0 {
            /// 正常的绝对大小
            let ratio = self.outputSize.width / self.outputSize.height
            if originSize.width / originSize.height > ratio {
                return CGSize(width: originSize.height * ratio, height: originSize.height)
            } else if originSize.width / originSize.height == ratio {
                return originSize
            } else {
                return CGSize(width: originSize.width, height: originSize.width * ratio)
            }
        } else {
            /// 异常
            return originSize
        }
    }
}


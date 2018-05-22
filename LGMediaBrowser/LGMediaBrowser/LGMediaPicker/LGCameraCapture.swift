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
    
    /// 是否允许拍照
    public var allowTakePhoto: Bool = true
    
    /// 是否允许录制视频
    public var allowRecordVideo: Bool = true
    
    /// 是否允许切换摄像头，需配合devicePosition使用
    public var allowSwitchDevicePosition: Bool = true
    
    /// 指定使用前置还是后置摄像头
    public var devicePosition: AVCaptureDevice.Position = AVCaptureDevice.Position.unspecified
    
    /// 输出文件大小
    public var outputSize: CGSize = UIScreen.main.bounds.size
    
    /// 输出视频格式
    public var videoType: VideoType = .mp4
    
    /// 视频进度条颜色
    public var circleProgressColor: UIColor = UIColor.blue
    
    /// 回调
    public weak var delegate: LGCameraCaptureDelegate?
    
    var toolView: LGCameraCaptureToolView!
    var session: AVCaptureSession = AVCaptureSession()
    var videoInput: AVCaptureDeviceInput?
    var imageOutPut: AVCaptureStillImageOutput = AVCaptureStillImageOutput()
    var videoFileOutPut: AVCaptureMovieFileOutput = AVCaptureMovieFileOutput()
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    lazy var toggleCameraBtn: UIButton = {
        let tempBtn = UIButton(type: UIButtonType.custom)
        tempBtn.setImage(UIImage(namedFromThisBundle: "btn_toggle_camera"), for: UIControlState.normal)
        tempBtn.addTarget(self, action: #selector(toggleCameraBtnPressed(_:)), for: UIControlEvents.touchUpInside)
        return tempBtn
    }()
    
    lazy var focusCursorImageView: UIImageView = {
        let temp = UIImageView(image: UIImage(namedFromThisBundle: "camera_focus"))
        temp.contentMode = UIViewContentMode.scaleAspectFit
        temp.clipsToBounds = true
        temp.alpha = 0.0
        temp.frame = CGRect(x: 0, y: 0, width: 80.0, height: 80.0)
        return temp
    }()
    
    var videoUrl: URL?
    var takedImageView: UIImageView!
    var takedImage: UIImage?
    var playerView: LGPlayerView?
    
    lazy var motionManager: CMMotionManager = {
        let temp = CMMotionManager()
        temp.deviceMotionUpdateInterval = 0.5
        return temp
    }()
    
    var orientation: AVCaptureVideoOrientation = .portraitUpsideDown
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupSubviewsAndLayout()
        self.setupCamera()
        self.observeDeviceMotion()
        
        if self.allowTakePhoto == false && self.allowRecordVideo == false {
            fatalError("拍摄视频和拍照必须选一个")
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
            pan.isEnabled = false
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
        
        self.previewLayer.frame = CGRect(x: 0,
                                         y: (self.view.lg_height - outputSize.height) / 2.0,
                                         width: outputSize.width,
                                         height: outputSize.height)
        
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
        
        if self.session.canAddOutput(self.videoFileOutPut) {
            self.session.addOutput(self.videoFileOutPut)
        }

        self.previewLayer = AVCaptureVideoPreviewLayer(session: self.session)
        self.previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        self.view.layer.masksToBounds = true
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
        
    }
    
    public func onStartRecord() {
        focusPanGesture?.isEnabled = true
    }
    
    public func onFinishedRecord() {
        focusPanGesture?.isEnabled = false
    }
    
    public func onRetake() {
        
    }
    
    public func onDoneClick() {
        
    }
    
    public func onDismiss() {
        
    }
}


// MARK: - LGCameraCaptureToolViewDelegate
protocol LGCameraCaptureToolViewDelegate: NSObjectProtocol {
    func onTakePicture()
    func onStartRecord()
    func onFinishedRecord()
    func onRetake()
    func onDoneClick()
    func onDismiss()
}

// MARK: - LGCameraCaptureToolView
class LGCameraCaptureToolView: UIView {
    
    /// 相关设置
    struct Settings {
        static var TopViewScale: CGFloat = 0.5
        static var BottomViewScale: CGFloat = 0.7
        static var AnimateDuration: TimeInterval = 0.1
    }
    
    /// 是否允许拍照
    var allowTakePhoto: Bool = true {
        didSet {
            setupTapGesture()
        }
    }
    
    /// 是否允许录制视频
    var allowRecordVideo: Bool = true {
        didSet {
            setupLongPressGesture()
        }
    }
    
    /// 是否允许切换摄像头，需配合devicePosition使用
    var allowSwitchDevicePosition: Bool = true {
        didSet {
            
        }
    }
    
    lazy var singleTapGes: UITapGestureRecognizer = {
        let tap = UITapGestureRecognizer()
        return tap
    }()
    
    lazy var longPressGes: UILongPressGestureRecognizer = {
        let longPress = UILongPressGestureRecognizer()
        longPress.minimumPressDuration = 0.3
        longPress.delegate = self
        return longPress
    }()
    
    
    /// 进度条颜色
    var circleProgressColor: UIColor?
    
    /// 最大录制长度
    var maximumVideoRecordingDuration: CFTimeInterval = 60.0
    
    weak var delegate: LGCameraCaptureToolViewDelegate?
    
    lazy var dismissBtn: UIButton = {
        let dismissBtn = UIButton(type: UIButtonType.custom)
        dismissBtn.frame = CGRect(x: 60, y: self.lg_height / 2 - 25.0 / 2, width: 25.0, height: 25.0)
        dismissBtn.setImage(UIImage(namedFromThisBundle: "btn_arrow_down"),
                            for: UIControlState.normal)
        dismissBtn.addTarget(self, action: #selector(dismissBtnPressed(_:)), for: UIControlEvents.touchUpInside)
        return dismissBtn
    }()
    
    lazy var cancelBtn: UIButton = {
        let cancelBtn = UIButton(type: UIButtonType.custom)
        cancelBtn.backgroundColor = UIColor(red: 244 / 255.0,
                                            green: 244 / 255.0,
                                            blue: 244 / 255.0,
                                            alpha: 0.9)
        cancelBtn.setImage(UIImage(namedFromThisBundle: "btn_retake"), for: UIControlState.normal)
        cancelBtn.addTarget(self, action: #selector(retakeBtnPressed(_:)), for: UIControlEvents.touchUpInside)
        cancelBtn.layer.masksToBounds = true
        cancelBtn.isHidden = true
        return cancelBtn
    }()
    
    lazy var doneBtn: UIButton = {
        let doneBtn = UIButton(type: UIButtonType.custom)
        doneBtn.frame = self.bottomView.frame
        doneBtn.backgroundColor = UIColor.white
        doneBtn.setImage(UIImage(namedFromThisBundle: "btn_take_done"), for: UIControlState.normal)
        doneBtn.addTarget(self, action: #selector(doneBtnPressed(_:)), for: UIControlEvents.touchUpInside)
        doneBtn.layer.masksToBounds = true
        doneBtn.isHidden = true
        return doneBtn
    }()
    
    lazy var topView: UIView = {
        let topView = UIView(frame: CGRect.zero)
        topView.layer.masksToBounds = true
        topView.backgroundColor = UIColor.white
        topView.isUserInteractionEnabled = false
        return topView
    }()
    
    lazy var bottomView: UIView = {
        let bottomView = UIView(frame: CGRect.zero)
        bottomView.layer.masksToBounds = true
        bottomView.backgroundColor = UIColor(red: 244 / 255.0,
                                             green: 244 / 255.0,
                                             blue: 244 / 255.0,
                                             alpha: 0.9)
        return bottomView
    }()
    
    var duration: CGFloat = 0.0


    
    /// 圆环动画Layer
    lazy var animateLayer: CAShapeLayer = {
        let temp = CAShapeLayer()
        let width = self.bottomView.lg_height * Settings.BottomViewScale
        let path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: width, height: width),
                                cornerRadius: width / 2.0)
        
        temp.strokeColor = self.circleProgressColor?.cgColor
        temp.fillColor = UIColor.clear.cgColor
        temp.path = path.cgPath
        temp.lineWidth = 8.0
        return temp
    }()
    
    // MARK: -  初始化
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupControls()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupControls()
    }
    
    func setupControls() {
        self.addSubview(bottomView)
        self.addSubview(topView)
        self.addSubview(doneBtn)
        self.addSubview(cancelBtn)
        self.addSubview(dismissBtn)
    }
    private var isSubiewsLayout: Bool = false
    override func layoutSubviews() {
        super.layoutSubviews()
        if isSubiewsLayout {
            return
        }
        
        isSubiewsLayout = true
        
        let height = self.lg_height
        self.bottomView.frame = CGRect(x: 0,
                                       y: 0,
                                       width: height * Settings.BottomViewScale,
                                       height: height * Settings.BottomViewScale)
        self.bottomView.center = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
        self.bottomView.layer.cornerRadius = (height * Settings.BottomViewScale) / 2.0

        self.topView.frame = CGRect(x: 0,
                                    y: 0,
                                    width: height * Settings.TopViewScale,
                                    height: height * Settings.TopViewScale)
        self.topView.center = self.bottomView.center
        self.topView.layer.cornerRadius = (height * Settings.TopViewScale) / 2.0

        self.dismissBtn.frame = CGRect(x: 60.0, y: self.lg_height / 2.0 - 25 / 2.0, width: 25, height: 25)
        
        
        
        self.cancelBtn.frame = self.bottomView.frame
        self.cancelBtn.layer.cornerRadius = (height * Settings.BottomViewScale) / 2.0
        
        self.doneBtn.frame = self.bottomView.frame
        self.doneBtn.layer.cornerRadius = (height * Settings.BottomViewScale) / 2.0
    }
    
    // MARK: -  controls actions
    @objc func dismissBtnPressed(_ sender: UIButton) {
        delegate?.onDismiss()
    }
    
    @objc func retakeBtnPressed(_ sender: UIButton) {
        delegate?.onRetake()
    }
    
    @objc func doneBtnPressed(_ sender: UIButton) {
        delegate?.onDoneClick()
    }
    
    
    // MARK: -  手势控制
    
    func setupTapGesture() {
        if self.allowTakePhoto {
            singleTapGes.addTarget(self, action: #selector(tapAction(_:)))
        } else {
            singleTapGes.removeTarget(self, action: #selector(tapAction(_:)))
        }
    }
    
    func setupLongPressGesture() {
        if self.allowRecordVideo {
            longPressGes.addTarget(self, action: #selector(longPressAction(_:)))
        } else {
            longPressGes.removeTarget(self, action: #selector(longPressAction(_:)))
        }
    }
    
    
    @objc func tapAction(_ ges: UITapGestureRecognizer) {
        delegate?.onTakePicture()
        stopAnimate()
    }
    
    private var isStopedpRecord: Bool = false
    @objc func longPressAction(_ ges: UILongPressGestureRecognizer) {
        switch ges.state {
        case .began:
            isStopedpRecord = false
            delegate?.onStartRecord()
            break
        case .cancelled, .ended:
            if isStopedpRecord { return }
            isStopedpRecord = true
            stopAnimate()
            delegate?.onFinishedRecord()
            break
        default:
            break
        }
    }
    
    // MARK: -  animations
    func startAnimate() {
        self.dismissBtn.isHidden = true
        UIView.animate(withDuration: Settings.AnimateDuration,
                       animations:
            {
                self.bottomView.layer.transform = CATransform3DScale(CATransform3DIdentity,
                                                                     1.0 / Settings.BottomViewScale,
                                                                     1.0 / Settings.BottomViewScale,
                                                                     1.0)
                self.topView.layer.transform = CATransform3DScale(CATransform3DIdentity, 0.7, 0.7, 1);
        }) { (isFinished) in
            let animation = CABasicAnimation(keyPath: "strokeEnd")
            animation.fromValue = 0.0
            animation.toValue = 1.0
            animation.duration = self.maximumVideoRecordingDuration
            animation.isRemovedOnCompletion = true
            animation.delegate = self
            self.animateLayer.add(animation, forKey: nil)
        }
    }
    
    func stopAnimate() {
        animateLayer.removeFromSuperlayer()
        animateLayer.removeAllAnimations()
        
        self.bottomView.isHidden = true
        self.topView.isHidden = true
        self.dismissBtn.isHidden = true
        
        self.bottomView.layer.transform = CATransform3DIdentity
        self.topView.layer.transform = CATransform3DIdentity
        showCancelAndDoneBtn()
    }
    
    func showCancelAndDoneBtn() {
        self.cancelBtn.isHidden = false
        self.doneBtn.isHidden = false
        
        var cancelRect = self.cancelBtn.frame
        cancelRect.origin.x = 40
        
        var doneRect = self.doneBtn.frame
        doneRect.origin.x = self.lg_width - doneRect.width - 40.0

        UIView.animate(withDuration: Settings.AnimateDuration) {
            self.cancelBtn.frame = cancelRect
            self.doneBtn.frame = doneRect
        }
    }
    
    /// 重置坐标
    func resutLayout() {
        animateLayer.removeFromSuperlayer()
        animateLayer.removeAllAnimations()
        self.dismissBtn.isHidden = false
        self.bottomView.isHidden = false
        self.topView.isHidden = false
        self.cancelBtn.isHidden = true
        
        self.doneBtn.isHidden = true
        self.cancelBtn.frame = self.bottomView.frame
        self.doneBtn.frame = self.bottomView.frame
    }
}

// MARK: - 动画结束后完成视频录制
extension LGCameraCaptureToolView: CAAnimationDelegate {
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if isStopedpRecord { return }
        stopAnimate()
        delegate?.onFinishedRecord()
    }
}

// MARK: - 设置手势同时生效
extension LGCameraCaptureToolView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool
    {
        if otherGestureRecognizer.isKind(of: UILongPressGestureRecognizer.self) ||
            otherGestureRecognizer.isKind(of: UIPanGestureRecognizer.self)
        {
            return true
        } else {
            return false
        }
    }
}

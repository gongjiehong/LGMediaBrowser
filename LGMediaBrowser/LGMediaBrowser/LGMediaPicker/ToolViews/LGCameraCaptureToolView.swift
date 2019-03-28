//
//  LGCameraCaptureToolView.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/5/23.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import Foundation
import UIKit

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
        willSet {
            if allowTakePhoto != newValue {
                setupTapGesture(newValue)
            }
        }
        
    }
    
    /// 是否允许录制视频
    var allowRecordVideo: Bool = true {
        willSet {
            if allowRecordVideo != newValue {
                setupLongPressGesture(newValue)
            }
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
    
    lazy var dismissButton: UIButton = {
        let dismissButton = UIButton(type: UIButton.ButtonType.custom)
        dismissButton.frame = CGRect(x: 60, y: self.lg_height / 2 - 25.0 / 2, width: 25.0, height: 25.0)
        dismissButton.setImage(UIImage(namedFromThisBundle: "btn_arrow_down"),
                            for: UIControl.State.normal)
        dismissButton.addTarget(self, action: #selector(dismissButtonPressed(_:)), for: UIControl.Event.touchUpInside)
        return dismissButton
    }()
    
    lazy var cancelButton: UIButton = {
        let cancelButton = UIButton(type: UIButton.ButtonType.custom)
        cancelButton.backgroundColor = UIColor(red: 244 / 255.0,
                                            green: 244 / 255.0,
                                            blue: 244 / 255.0,
                                            alpha: 0.9)
        cancelButton.setImage(UIImage(namedFromThisBundle: "btn_retake"), for: UIControl.State.normal)
        cancelButton.addTarget(self, action: #selector(retakeButtonPressed(_:)), for: UIControl.Event.touchUpInside)
        cancelButton.layer.masksToBounds = true
        cancelButton.isHidden = true
        return cancelButton
    }()
    
    lazy var doneButton: UIButton = {
        let doneButton = UIButton(type: UIButton.ButtonType.custom)
        doneButton.frame = self.bottomView.frame
        doneButton.backgroundColor = UIColor.white
        doneButton.setImage(UIImage(namedFromThisBundle: "btn_take_done"), for: UIControl.State.normal)
        doneButton.addTarget(self, action: #selector(doneButtonPressed(_:)), for: UIControl.Event.touchUpInside)
        doneButton.layer.masksToBounds = true
        doneButton.isHidden = true
        return doneButton
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
        self.addSubview(doneButton)
        self.addSubview(cancelButton)
        self.addSubview(dismissButton)
        setupTapGesture(true)
        setupLongPressGesture(true)
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
        
        self.dismissButton.frame = CGRect(x: 60.0, y: self.lg_height / 2.0 - 25 / 2.0, width: 25, height: 25)
        
        
        
        self.cancelButton.frame = self.bottomView.frame
        self.cancelButton.layer.cornerRadius = (height * Settings.BottomViewScale) / 2.0
        
        self.doneButton.frame = self.bottomView.frame
        self.doneButton.layer.cornerRadius = (height * Settings.BottomViewScale) / 2.0
    }
    
    // MARK: -  controls actions
    @objc func dismissButtonPressed(_ sender: UIButton) {
        delegate?.onDismiss()
    }
    
    @objc func retakeButtonPressed(_ sender: UIButton) {
        delegate?.onRetake()
    }
    
    @objc func doneButtonPressed(_ sender: UIButton) {
        delegate?.onDoneClick()
    }
    
    
    // MARK: -  手势控制
    
    func setupTapGesture(_ allow: Bool) {
        if allow {
            singleTapGes.addTarget(self, action: #selector(tapAction(_:)))
            self.bottomView.addGestureRecognizer(singleTapGes)
        } else {
            singleTapGes.removeTarget(self, action: #selector(tapAction(_:)))
            self.bottomView.removeGestureRecognizer(singleTapGes)
        }
    }
    
    func setupLongPressGesture(_ allow: Bool) {
        if allow {
            longPressGes.addTarget(self, action: #selector(longPressAction(_:)))
            self.bottomView.addGestureRecognizer(longPressGes)
        } else {
            longPressGes.removeTarget(self, action: #selector(longPressAction(_:)))
            self.bottomView.removeGestureRecognizer(longPressGes)
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
        self.dismissButton.isHidden = true
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
            
            self.bottomView.layer.addSublayer(self.animateLayer)
        }
    }
    
    func stopAnimate() {
        animateLayer.removeFromSuperlayer()
        animateLayer.removeAllAnimations()
        
        self.bottomView.isHidden = true
        self.topView.isHidden = true
        self.dismissButton.isHidden = true
        
        self.bottomView.layer.transform = CATransform3DIdentity
        self.topView.layer.transform = CATransform3DIdentity
        showCancelAnddoneButton()
    }
    
    func showCancelAnddoneButton() {
        self.cancelButton.isHidden = false
        self.doneButton.isHidden = false
        
        var cancelRect = self.cancelButton.frame
        cancelRect.origin.x = 40
        
        var doneRect = self.doneButton.frame
        doneRect.origin.x = self.lg_width - doneRect.width - 40.0
        
        UIView.animate(withDuration: Settings.AnimateDuration) {
            self.cancelButton.frame = cancelRect
            self.doneButton.frame = doneRect
        }
    }
    
    /// 重置坐标
    func resetLayout() {
        animateLayer.removeFromSuperlayer()
        animateLayer.removeAllAnimations()
        self.dismissButton.isHidden = false
        self.bottomView.isHidden = false
        self.topView.isHidden = false
        self.cancelButton.isHidden = true
        
        self.doneButton.isHidden = true
        self.cancelButton.frame = self.bottomView.frame
        self.doneButton.frame = self.bottomView.frame
    }
}

// MARK: - 动画结束后完成视频录制
extension LGCameraCaptureToolView: CAAnimationDelegate {
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if isStopedpRecord { return }
        isStopedpRecord = true
        stopAnimate()
        delegate?.onFinishedRecord()
    }
}

// MARK: - 设置手势同时生效
extension LGCameraCaptureToolView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool
    {
        if gestureRecognizer.isKind(of: UILongPressGestureRecognizer.self),
            otherGestureRecognizer.isKind(of: UIPanGestureRecognizer.self)
        {
            return true
        } else {
            return false
        }
    }
}

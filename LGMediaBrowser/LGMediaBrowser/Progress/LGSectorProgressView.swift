//
//  LGCircleProgressView.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/5/7.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import Foundation

/// 扇形进度条，可显示进度，也可显示错误
open class LGSectorProgressView: UIView {
    
    /// 进度，默认0
    public var progress: CGFloat = 0.0 {
        didSet {
            updateProgressLayer()
        }
    }
    
    /// 是否为显示错误的叉
    public var isShowError: Bool = false {
        didSet {
            if isShowError {
                fanshapedLayer.isHidden = true
                errorLayer.isHidden = false
                if errorLayer.superlayer == nil {
                    self.layer.addSublayer(errorLayer)
                }
            } else {
                fanshapedLayer.isHidden = false
                errorLayer.isHidden = true
                if fanshapedLayer.superlayer == nil {
                    self.layer.addSublayer(fanshapedLayer)
                }
            }
        }
    }
    
    /// 最外层的圆环
    internal lazy var circleLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.strokeColor = UIColor(red: 255.0 / 255.0,
                                    green: 255.0 / 255.0,
                                    blue: 255.0 / 255.0,
                                    alpha: 0.8).cgColor
        layer.fillColor = UIColor(red: 0.0 / 255.0,
                                 green: 0.0 / 255.0,
                                 blue: 0.0 / 255.0,
                                 alpha: 0.2).cgColor
        layer.path = circlePath.cgPath
        layer.contentsScale = UIScreen.main.scale
        layer.allowsEdgeAntialiasing = true
        return layer
    }()
    
    /// 圆环路径
    internal lazy var circlePath: UIBezierPath = {
        let path = UIBezierPath(arcCenter: CGPoint(x: self.bounds.width / 2.0, y: self.bounds.height / 2.0),
                                radius: LGSectorProgressView.staticCircleSize.width / 2.0,
                                startAngle: 0.0,
                                endAngle: CGFloat.pi * 2,
                                clockwise: true)
        path.lineWidth = 1.0
        return path
    }()
    
    /// 中间的扇形进度
    internal lazy var fanshapedLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = UIColor(red: 255.0 / 255.0,
                                  green: 255.0 / 255.0,
                                  blue: 255.0 / 255.0,
                                  alpha: 0.8).cgColor
        layer.contentsScale = UIScreen.main.scale
        layer.allowsEdgeAntialiasing = true
        return layer
    }()
    
    /// 显示错误的一个叉，通过将十字旋转45度实现
    internal lazy var errorLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.frame = self.bounds
        layer.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat.pi / 4))
        layer.fillColor = UIColor(red: 255.0 / 255.0,
                                  green: 255.0 / 255.0,
                                  blue: 255.0 / 255.0,
                                  alpha: 0.8).cgColor
        layer.path = errorPath.cgPath
        layer.contentsScale = UIScreen.main.scale
        layer.allowsEdgeAntialiasing = true
        return layer
    }()
    
    /// 叉路径
    internal lazy var errorPath: UIBezierPath = {
        let lineLength: CGFloat = 30.0
        let lineWidth: CGFloat = 5.0
        let verticalLine = UIBezierPath(rect: CGRect(x: self.bounds.width / 2.0 - lineWidth / 2.0,
                                                     y: (self.bounds.width - lineLength) / 2.0,
                                                     width: lineWidth,
                                                     height: lineLength))
        let horizontalLinePath = UIBezierPath(rect: CGRect(x: (self.bounds.width - lineLength) / 2.0,
                                                           y: self.bounds.width / 2.0 - lineWidth / 2.0,
                                                           width: lineLength,
                                                           height: lineWidth))
        verticalLine.append(horizontalLinePath)
        return verticalLine
    }()
    
    /// 默认大小
    static var staticCircleSize: CGSize {
        return CGSize(width: 50, height: 50)
    }
    
    /// 初始化
    ///
    /// - Parameters:
    ///   - frame: 视图位置和大小
    ///   - isShowError: 是否是显示错误叉
    public init(frame: CGRect, isShowError: Bool = false) {
        super.init(frame: frame)
        setupDefault(isShowError)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupDefault(false)
    }
    
    /// 初始化部分layer展示
    ///
    /// - Parameter isShowError: 是否是显示错误叉
    internal func setupDefault(_ isShowError: Bool) {
        self.bounds.size = LGSectorProgressView.staticCircleSize
        self.backgroundColor = UIColor.clear
        if isShowError {
            self.layer.addSublayer(circleLayer)
            self.layer.addSublayer(errorLayer)
        } else {
            self.layer.addSublayer(circleLayer)
            self.layer.addSublayer(fanshapedLayer)
        }
    }
    
    /// 根据进度获取路径
    ///
    /// - Parameter progress: 进度
    /// - Returns: 路径
    func pathForProgress(_ progress: CGFloat) -> UIBezierPath {
        let center = CGPoint(x: self.bounds.width / 2.0, y: self.bounds.height / 2.0)
        let radius = self.bounds.height / 2.0 - 2.5
        let path = UIBezierPath()
        path.move(to: center)
        path.addLine(to: CGPoint(x: self.frame.width / 2.0, y: center.y - radius))
        path.addArc(withCenter: center,
                    radius: radius,
                    startAngle: CGFloat.pi / -2.0,
                    endAngle: CGFloat.pi / -2.0 + CGFloat.pi * 2.0 * progress,
                    clockwise: true)
        path.close()
        return path
    }
    
    /// 更新progress
    func updateProgressLayer() {
        fanshapedLayer.path = pathForProgress(self.progress).cgPath
    }
}

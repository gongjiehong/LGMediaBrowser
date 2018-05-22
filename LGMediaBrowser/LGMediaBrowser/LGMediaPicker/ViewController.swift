//
//  ViewController.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/5/22.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import Foundation
class ViewController: UIViewController , AVCaptureFileOutputRecordingDelegate {
    
    //视频捕获会话。它是input和output的桥梁。它协调着intput到output的数据传输
    let captureSession = AVCaptureSession()
    //视频输入设备
    let videoDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
    //音频输入设备
    let audioDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeAudio)
    //将捕获到的视频输出到文件
    let fileOutput = AVCaptureMovieFileOutput()
    
    //录制、保存按钮
    var recordButton, saveButton : UIButton!
    
    //保存所有的录像片段数组
    var videoAssets = [AVAsset]()
    //保存所有的录像片段url数组
    var assetURLs = [String]()
    //单独录像片段的index索引
    var appendix: Int32 = 1
    
    //最大允许的录制时间（秒）
    let totalSeconds: Float64 = 15.00
    //每秒帧数
    var framesPerSecond:Int32 = 30
    //剩余时间
    var remainingTime : NSTimeInterval = 15.0
    
    //表示是否停止录像
    var stopRecording: Bool = false
    //剩余时间计时器
    var timer: NSTimer?
    //进度条计时器
    var progressBarTimer: NSTimer?
    //进度条计时器时间间隔
    var incInterval: NSTimeInterval = 0.05
    //进度条
    var progressBar: UIView = UIView()
    //当前进度条终点位置
    var oldX: CGFloat = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //背景色设为黑色
        self.view.backgroundColor = UIColor.blackColor()
        
        //添加视频、音频输入设备
        let videoInput = try! AVCaptureDeviceInput(device: self.videoDevice)
        self.captureSession.addInput(videoInput)
        let audioInput = try! AVCaptureDeviceInput(device: self.audioDevice)
        self.captureSession.addInput(audioInput);
        
        //添加视频捕获输出
        let maxDuration = CMTimeMakeWithSeconds(totalSeconds, framesPerSecond)
        self.fileOutput.maxRecordedDuration = maxDuration
        self.captureSession.addOutput(self.fileOutput)
        
        //使用AVCaptureVideoPreviewLayer可以将摄像头的拍摄的实时画面显示在ViewController上
        let videoLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        //预览窗口是正方形，在屏幕居中（显示的也是摄像头拍摄的中心区域）
        videoLayer.frame = CGRectMake(0, self.view.bounds.height/4,
                                      self.view.bounds.width, self.view.bounds.width)
        videoLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        videoLayer.pointForCaptureDevicePointOfInterest(CGPoint(x: 0, y: 0))
        self.view.layer.addSublayer(videoLayer)
        
        //创建按钮
        self.setupButton()
        //启动session会话
        self.captureSession.startRunning()
        
        //添加进度条
        progressBar.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width,
                                   height: self.view.bounds.height * 0.1)
        progressBar.backgroundColor = UIColor(red: 4, green: 3, blue: 3, alpha: 0.5)
        self.view.addSubview(progressBar)
    }
    
    //创建按钮
    func setupButton(){
        //创建录制按钮
        self.recordButton = UIButton(frame: CGRectMake(0,0,120,50))
        self.recordButton.backgroundColor = UIColor.redColor();
        self.recordButton.layer.masksToBounds = true
        self.recordButton.setTitle("按住录像", forState: .Normal)
        self.recordButton.layer.cornerRadius = 20.0
        self.recordButton.layer.position = CGPoint(x: self.view.bounds.width/2,
                                                   y:self.view.bounds.height-50)
        self.recordButton.addTarget(self, action: #selector(onTouchDownRecordButton(_:)),
                                    forControlEvents: .TouchDown)
        self.recordButton.addTarget(self, action: #selector(onTouchUpRecordButton(_:)),
                                    forControlEvents: .TouchUpInside)
        
        //创建保存按钮
        self.saveButton = UIButton(frame: CGRectMake(0,0,70,50))
        self.saveButton.backgroundColor = UIColor.grayColor();
        self.saveButton.layer.masksToBounds = true
        self.saveButton.setTitle("保存", forState: .Normal)
        self.saveButton.layer.cornerRadius = 20.0
        
        self.saveButton.layer.position = CGPoint(x: self.view.bounds.width - 60,
                                                 y:self.view.bounds.height-50)
        self.saveButton.addTarget(self, action: #selector(onClickStopButton(_:)),
                                  forControlEvents: .TouchUpInside)
        
        //添加按钮到视图上
        self.view.addSubview(self.recordButton);
        self.view.addSubview(self.saveButton);
    }
    
    //按下录制按钮，开始录制片段
    func  onTouchDownRecordButton(sender: UIButton){
        if(!stopRecording) {
            let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory,
                                                            .UserDomainMask, true)
            let documentsDirectory = paths[0] as String
            let outputFilePath = "\(documentsDirectory)/output-\(appendix).mov"
            appendix += 1
            let outputURL = NSURL(fileURLWithPath: outputFilePath)
            let fileManager = NSFileManager.defaultManager()
            if(fileManager.fileExistsAtPath(outputFilePath)) {
                
                do {
                    try fileManager.removeItemAtPath(outputFilePath)
                } catch _ {
                }
            }
            print("开始录制：\(outputFilePath) ")
            fileOutput.startRecordingToOutputFileURL(outputURL, recordingDelegate: self)
        }
    }
    
    //松开录制按钮，停止录制片段
    func  onTouchUpRecordButton(sender: UIButton){
        if(!stopRecording) {
            timer?.invalidate()
            progressBarTimer?.invalidate()
            fileOutput.stopRecording()
        }
    }
    
    //录像开始的代理方法
    func captureOutput(captureOutput: AVCaptureFileOutput!,
                       didStartRecordingToOutputFileAtURL fileURL: NSURL!,
                       fromConnections connections: [AnyObject]!) {
        startProgressBarTimer()
        startTimer()
    }
    
    //录像结束的代理方法
    func captureOutput(captureOutput: AVCaptureFileOutput!,
                       didFinishRecordingToOutputFileAtURL outputFileURL: NSURL!,
                       fromConnections connections: [AnyObject]!, error: NSError!) {
        let asset : AVURLAsset = AVURLAsset(URL: outputFileURL, options: nil)
        var duration : NSTimeInterval = 0.0
        duration = CMTimeGetSeconds(asset.duration)
        print("生成视频片段：\(asset)")
        videoAssets.append(asset)
        assetURLs.append(outputFileURL.path!)
        remainingTime = remainingTime - duration
        
        //到达允许最大录制时间，自动合并视频
        if remainingTime <= 0 {
            mergeVideos()
        }
    }
    
    //剩余时间计时器
    func startTimer() {
        timer = NSTimer(timeInterval: remainingTime, target: self,
                        selector: #selector(ViewController.timeout), userInfo: nil,
                        repeats:true)
        NSRunLoop.currentRunLoop().addTimer(timer!, forMode: NSDefaultRunLoopMode)
    }
    
    //录制时间达到最大时间
    func timeout() {
        stopRecording = true
        print("时间到。")
        fileOutput.stopRecording()
        timer?.invalidate()
        progressBarTimer?.invalidate()
    }
    
    //进度条计时器
    func startProgressBarTimer() {
        progressBarTimer = NSTimer(timeInterval: incInterval, target: self,
                                   selector: #selector(ViewController.progress),
                                   userInfo: nil, repeats: true)
        NSRunLoop.currentRunLoop().addTimer(progressBarTimer!,
                                            forMode: NSDefaultRunLoopMode)
    }
    
    //修改进度条进度
    func progress() {
        let progressProportion: CGFloat = CGFloat(incInterval / totalSeconds)
        let progressInc: UIView = UIView()
        progressInc.backgroundColor = UIColor(red: 55/255, green: 186/255, blue: 89/255,
                                              alpha: 1)
        let newWidth = progressBar.frame.width * progressProportion
        progressInc.frame = CGRect(x: oldX , y: 0, width: newWidth,
                                   height: progressBar.frame.height)
        oldX = oldX + newWidth
        progressBar.addSubview(progressInc)
    }
    
    //保存按钮点击
    func onClickStopButton(sender: UIButton){
        mergeVideos()
    }
    
    //合并视频片段
    func mergeVideos() {
        let duration = totalSeconds
        
        let composition = AVMutableComposition()
        //合并视频、音频轨道
        let firstTrack = composition.addMutableTrackWithMediaType(
            AVMediaTypeVideo, preferredTrackID: CMPersistentTrackID())
        let audioTrack = composition.addMutableTrackWithMediaType(
            AVMediaTypeAudio, preferredTrackID: CMPersistentTrackID())
        
        var insertTime: CMTime = kCMTimeZero
        for asset in videoAssets {
            print("合并视频片段：\(asset)")
            do {
                try firstTrack.insertTimeRange(
                    CMTimeRangeMake(kCMTimeZero, asset.duration),
                    ofTrack: asset.tracksWithMediaType(AVMediaTypeVideo)[0] ,
                    atTime: insertTime)
            } catch _ {
            }
            do {
                try audioTrack.insertTimeRange(
                    CMTimeRangeMake(kCMTimeZero, asset.duration),
                    ofTrack: asset.tracksWithMediaType(AVMediaTypeAudio)[0] ,
                    atTime: insertTime)
            } catch _ {
            }
            
            insertTime = CMTimeAdd(insertTime, asset.duration)
        }
        //旋转视频图像，防止90度颠倒
        firstTrack.preferredTransform = CGAffineTransformMakeRotation(CGFloat(M_PI_2))
        
        //定义最终生成的视频尺寸（矩形的）
        print("视频原始尺寸：", firstTrack.naturalSize)
        let renderSize = CGSizeMake(firstTrack.naturalSize.height, firstTrack.naturalSize.height)
        print("最终渲染尺寸：", renderSize)
        
        //通过AVMutableVideoComposition实现视频的裁剪(矩形，截取正中心区域视频)
        let videoComposition = AVMutableVideoComposition()
        videoComposition.frameDuration = CMTimeMake(1, framesPerSecond)
        videoComposition.renderSize = renderSize
        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRangeMake(
            kCMTimeZero,CMTimeMakeWithSeconds(Float64(duration), framesPerSecond))
        
        let transformer: AVMutableVideoCompositionLayerInstruction =
            AVMutableVideoCompositionLayerInstruction(assetTrack: firstTrack)
        let t1 = CGAffineTransformMakeTranslation(firstTrack.naturalSize.height,
                                                  -(firstTrack.naturalSize.width-firstTrack.naturalSize.height)/2)
        let t2 = CGAffineTransformRotate(t1, CGFloat(M_PI_2))
        let finalTransform: CGAffineTransform = t2
        transformer.setTransform(finalTransform, atTime: kCMTimeZero)
        
        instruction.layerInstructions = [transformer]
        videoComposition.instructions = [instruction]
        
        //获取合并后的视频路径
        let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory,
                                                                .UserDomainMask,true)[0]
        let destinationPath = documentsPath + "/mergeVideo-\(arc4random()%1000).mov"
        print("合并后的视频：\(destinationPath)")
        let videoPath: NSURL = NSURL(fileURLWithPath: destinationPath as String)
        let exporter = AVAssetExportSession(asset: composition,
                                            presetName:AVAssetExportPresetHighestQuality)!
        exporter.outputURL = videoPath
        exporter.outputFileType = AVFileTypeQuickTimeMovie
        exporter.videoComposition = videoComposition //设置videoComposition
        exporter.shouldOptimizeForNetworkUse = true
        exporter.timeRange = CMTimeRangeMake(
            kCMTimeZero,CMTimeMakeWithSeconds(Float64(duration), framesPerSecond))
        exporter.exportAsynchronouslyWithCompletionHandler({
            //将合并后的视频保存到相册
            self.exportDidFinish(exporter)
        })
    }
    
    //将合并后的视频保存到相册
    func exportDidFinish(session: AVAssetExportSession) {
        print("视频合并成功！")
        let outputURL: NSURL = session.outputURL!
        //将录制好的录像保存到照片库中
        PHPhotoLibrary.sharedPhotoLibrary().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideoAtFileURL(outputURL)
        }, completionHandler: { (isSuccess: Bool, error: NSError?) in
            dispatch_async(dispatch_get_main_queue(),{
                //重置参数
                self.reset()
                
                //弹出提示框
                let alertController = UIAlertController(title: "视频保存成功",
                                                        message: "是否需要回看录像？", preferredStyle: .Alert)
                let okAction = UIAlertAction(title: "确定", style: .Default, handler: {
                    action in
                    //录像回看
                    self.reviewRecord(outputURL)
                })
                let cancelAction = UIAlertAction(title: "取消", style: .Cancel,
                                                 handler: nil)
                alertController.addAction(okAction)
                alertController.addAction(cancelAction)
                self.presentViewController(alertController, animated: true,
                                           completion: nil)
            })
        })
    }
    
    //视频保存成功，重置各个参数，准备新视频录制
    func reset() {
        //删除视频片段
        for assetURL in assetURLs {
            if(NSFileManager.defaultManager().fileExistsAtPath(assetURL)) {
                do {
                    try NSFileManager.defaultManager().removeItemAtPath(assetURL)
                } catch _ {
                }
                print("删除视频片段: \(assetURL)")
            }
        }
        
        //进度条还原
        let subviews = progressBar.subviews
        for subview in subviews {
            subview.removeFromSuperview()
        }
        
        //各个参数还原
        videoAssets.removeAll(keepCapacity: false)
        assetURLs.removeAll(keepCapacity: false)
        appendix = 1
        oldX = 0
        stopRecording = false
        remainingTime = totalSeconds
    }
    
    //录像回看
    func reviewRecord(outputURL: NSURL) {
        //定义一个视频播放器，通过本地文件路径初始化
        let player = AVPlayer(URL: outputURL)
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        self.presentViewController(playerViewController, animated: true) {
            playerViewController.player!.play()
        }
    }
}

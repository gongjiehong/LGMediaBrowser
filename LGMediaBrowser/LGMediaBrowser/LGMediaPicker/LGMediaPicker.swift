//
//  LGMediaPicker.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/6/1.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import UIKit
import Photos

public protocol LGMediaPickerDelegate: NSObjectProtocol {
    func pickerDidCancel(_ picker: LGMediaPicker)
    func picker(_ picker: LGMediaPicker, didDoneWith photoList: [LGAlbumAssetModel], isOriginalPhoto isOriginal: Bool)
    func picker(_ picker: LGMediaPicker, didDoneWith resultImage: UIImage?)
}

internal var globleSelectedDataArray: [LGAlbumAssetModel]! = []

internal weak var globleMainPicker: LGMediaPicker!

public class LGMediaPicker: LGMPNavigationController {
    
    public struct Configuration {
        /// 状态栏显示方式，默认lightContent
        public var statusBarStyle: UIStatusBarStyle = .lightContent
        
        /// 可选择的最大张数，默认9
        public var maxSelectCount: Int = 9
        
        /// cell的圆角大小，默认0.0没有圆角
        public var cellCornerRadius: CGFloat = 0.0
        
        /// 是否允许混合选择，默认可以，如果为true，可以同时选择视频和图片
        public var allowMixSelect: Bool = true
        
        /// 可选的数据类型，默认选择全部 .all
        /// 仅支持4种模式，.all, .image, .animatedImage, .livePhoto, 不支持如 [.animatedImage, .livePhoto]
        public var resultMediaTypes: LGMediaType = .all
        
        /// 是否支持选择GIF和APNG，默认支持true
        public var allowSelectAnimatedImage: Bool = true
        
        /// 是否支持选择LivePhoto，默认支持true
        public var allowSelectLivePhoto: Bool = true
        
        /// 是否允许在相册内部直接拍照，默认允许true
        public var allowTakePhotoInLibrary: Bool = true
        
        /// 是否支持3Dtouch预览
        public var allowForceTouch: Bool = true
        
        /// 是否允许编辑图片，单张图片时有效，默认允许true
        public var allowEditImage: Bool = false
        
        /// 是否允许编辑视频，单张选择时有效，默认允许true
        public var allowEditVideo: Bool = false
        
        /// 是否允许选择原图，默认允许，true
        public var allowSelectOriginal: Bool = false

        /// 可编辑的视频最大长度，默认CMTime.zero，表示不限制长度
        public var maxVideoEditDuration: CMTime = CMTime.zero
        
        /// 最大视频长度，默认CMTime.zero，表示不限制
        public var maxVideoDuration: CMTime = CMTime.zero
        
        /// 是否允许滑动选择，默认允许true
        public var allowSlideSelect: Bool = true
        
        /// 是否允许拖动选择，默认允许true
        public var allowDragSelect: Bool = true
        
        /// 是否隐藏图片裁切工具条
        public var isHideClipRatiosToolBar: Bool = true
        
        /// 图片裁切比例数组，使用CGSize标示,预置1:1, 4:3, 3:2, 16:9四种
        public var clipRatios: [CGSize] = [CGSize(width: 1, height: 1),
                                           CGSize(width: 4, height: 3),
                                           CGSize(width: 3, height: 2),
                                           CGSize(width: 16, height: 9)]
        
        /// 是否在点击缩略图后马上进入编辑模式，只在single模式下有效
        public var editAfterSelectingThumbnailImage: Bool = false
        
        /// 是否在编辑图像完成后将图像存储到相册中
        public var saveNewImageAfterEdit: Bool = false
        
        /// 是否在拍照按钮上显示当前拍摄到的内容
        public var isShowCaptureImageOnTakePhotoButton: Bool = true
        
        /// 排序方式，升序还是降序
        public var sortBy: LGAssetExportManager.SortBy = .ascending
        
        /// 单选模式下是否显示选择按钮
        public var isShowSelectButtonAtSingleMode: Bool = false
        
        /// 是否在选中的图片上显示蒙层，默认不显示，false
        public var isShowSelectedMask: Bool = false

        /// 是否允许录制视频，默认true，但resultMediaTypes.contains(.video) == false时不生效
        public var allowRecordVideo: Bool = true
        
        /// 视频最大录制时长，默认60.0S
        public var maximumVideoRecordingDuration: CFTimeInterval = 60.0
        
        /// 输出视频格式, 默认mp4，仅支持mp4和mov
        public var videoExportType: LGCameraCapture.VideoType = .mp4
        
        /// 是否为头像模式， 头像模式不能使用3DTouch
        public var isHeadPortraitMode: Bool = false {
            didSet {
                if isHeadPortraitMode {
                    self.allowForceTouch = false
                }
            }
        }
        
        public init() {
        }
        
        /// 默认配置
        public static var `default`: Configuration {
            return Configuration()
        }
    }
    
    public override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
        setupGloble()
    }
    
    public override init(navigationBarClass: AnyClass?, toolbarClass: AnyClass?) {
        super.init(navigationBarClass: navigationBarClass, toolbarClass: toolbarClass)
        setupGloble()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupGloble()
    }
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setupGloble()
    }
    
    public convenience init(delegate: LGMediaPickerDelegate) {
        self.init(nibName: nil, bundle: nil)
        self.pickerDelegate = delegate
    }
    
    func setupGloble() {
        if globleSelectedDataArray == nil {
            globleSelectedDataArray = []
        }
        
        globleMainPicker = self
    }
    
    /// 配置，默认使用默认配置
    public var configs: Configuration = Configuration.default
    
    public var selectedDataArray: [LGAlbumAssetModel] = [] {
        didSet {
            for (index, photo) in selectedDataArray.enumerated() {
                photo.currentSelectedIndex = index + 1
            }
            globleSelectedDataArray = selectedDataArray
        }
    }
    
    public weak var pickerDelegate: LGMediaPickerDelegate?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        LGAssetExportManager.default.sort = self.configs.sortBy
        
        self.title = LGLocalizedString("Albums")
        
        self.view.backgroundColor = UIColor.white
        
        self.navigationBar.tintColor = UIColor(named: "NavigationBarTint", in: Bundle.this, compatibleWith: nil)
    }
    
    public override func loadView() {
        super.loadView()
        requestAccessAndSetupLayout()
    }
    
    public override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    public func requestAccessAndSetupLayout() {
        do {
            let status = try LGAuthorizationStatusManager.default.status(withPrivacyType: .photos)
            if status == .notDetermined {
                try LGAuthorizationStatusManager.default.requestPrivacy(withType: .photos,
                                                                        callback:
                    { [weak self] (type, status) in
                        guard let weakSelf = self else {return}
                        switch type {
                        case .photos:
                            weakSelf.setupControllersWith(status)
                            break
                        default:
                            break
                        }
                })
            } else {
                setupControllersWith(status)
            }
        } catch {
            LGStatusBarTips.show(withStatus: error.localizedDescription,
                                 style: LGStatusBarConfig.Style.error)
            DispatchQueue.main.after(0.5) { [weak self] in
                guard let weakSelf = self else {return}
                weakSelf.pickerDelegate?.pickerDidCancel(weakSelf)
            }
        }
    }
    
    func setupControllersWith(_ status: LGAuthorizationStatusManager.Status) {
        switch status {
        case .authorized:
            let albumList = LGMPAlbumListController()
            albumList.configs = self.configs
            albumList.delegate = self.pickerDelegate
            
            let allPhotosList = LGMPAlbumDetailController()
            allPhotosList.configs = self.configs
            allPhotosList.delegate = self.pickerDelegate
            self.viewControllers = [albumList, allPhotosList]
            break
        case .denied, .restricted:
            let controller = LGUnauthorizedController()
            controller.unauthorizedType = .ablum
            self.viewControllers = [controller]
            break
        case .notDetermined:
            break
        case .unSupport:
            break
        }
    }
    
    deinit {
        globleSelectedDataArray = nil
        globleMainPicker = nil
        LGAssetExportManager.default.stopCachingImages()
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

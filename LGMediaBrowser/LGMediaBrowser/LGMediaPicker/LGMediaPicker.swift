//
//  LGMediaPicker.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/6/1.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import UIKit
import Photos

public class LGMediaPicker: LGMPNavigationController {

    public struct Configuration {
        
        public var statusBarStyle: UIStatusBarStyle = .lightContent
        
        public var maxSelectCount: Int = 9
        
        public var cellCornerRadius: CGFloat = 0.0
        
        public struct SelectMediaType: OptionSet {
            public var rawValue: RawValue
            
            public typealias RawValue = Int
            
            public init(rawValue: Int) {
                self.rawValue = rawValue
            }
            
            public static var image: SelectMediaType = SelectMediaType(rawValue: 1 << 0)
            public static var video: SelectMediaType = SelectMediaType(rawValue: 1 << 1)
        }
        
        public var allowSelectMediaType: SelectMediaType = [SelectMediaType.image, SelectMediaType.video]
        
        public var allowSelectGif: Bool = true
        
        public var allowSelectLivePhoto: Bool = true
        
        public var allowTakePhotoInLibrary: Bool = true
        
        public var allowForceTouch: Bool = true
        
        public var allowEditImage: Bool = true
        
        public var allowEditVideo: Bool = true
        
        public var allowSelectOriginal: Bool = true

        public var maxVideoEditDuration: CMTime = kCMTimeZero
        
        public var maxVideoDuration: CMTime = kCMTimeZero
        
        public var allowSlideSelect: Bool = true
        
        public var allowDragSelect: Bool = true
        
        public var hideClipRatiosToolBar: Bool = true
        
        public var clipRatios: [CGSize] = []

        /**
         根据需要设置自身需要的裁剪比例
         
         @discussion e.g.:1:1，请使用ZLDefine中所提供方法 GetClipRatio(NSInteger value1, NSInteger value2)，该数组可不设置，有默认比例，为（Custom, 1:1, 4:3, 3:2, 16:9），如果所设置比例只有一个且 为 Custom 或 1:1，则编辑图片界面隐藏下方比例工具条
         */
        @property (nonatomic, strong) NSArray<NSDictionary *> *clipRatios;
        
        /**
         在小图界面选择 图片/视频 后直接进入编辑界面，默认NO
         
         @discussion 编辑图片 仅在allowEditImage为YES 且 maxSelectCount为1 的情况下，置为YES有效，编辑视频则在 allowEditVideo为YES 且 maxSelectCount为1情况下，置为YES有效
         */
        @property (nonatomic, assign) BOOL editAfterSelectThumbnailImage;
        
        /**
         编辑图片后是否保存编辑后的图片至相册，默认YES
         */
        @property (nonatomic, assign) BOOL saveNewImageAfterEdit;
        
        /**
         是否在相册内部拍照按钮上面实时显示相机俘获的影像 默认 YES
         */
        @property (nonatomic, assign) BOOL showCaptureImageOnTakePhotoBtn;
        
        /**
         是否升序排列，预览界面不受该参数影响，默认升序 YES
         */
        @property (nonatomic, assign) BOOL sortAscending;
        
        /**
         控制单选模式下，是否显示选择按钮，默认 NO，多选模式不受控制
         */
        @property (nonatomic, assign) BOOL showSelectBtn;
        
        /**
         导航条颜色，默认 rgb(19, 153, 231)
         */
        @property (nonatomic, strong) UIColor *navBarColor;
        
        /**
         导航标题颜色，默认 rgb(255, 255, 255)
         */
        @property (nonatomic, strong) UIColor *navTitleColor;
        
        /**
         底部工具条底色，默认 rgb(255, 255, 255)
         */
        @property (nonatomic, strong) UIColor *bottomViewBgColor;
        
        /**
         底部工具栏按钮 可交互 状态标题颜色，底部 toolbar 按钮可交互状态title颜色均使用这个，确定按钮 可交互 的背景色为这个，默认rgb(80, 180, 234)
         */
        @property (nonatomic, strong) UIColor *bottomBtnsNormalTitleColor;
        
        /**
         底部工具栏按钮 不可交互 状态标题颜色，底部 toolbar 按钮不可交互状态颜色均使用这个，确定按钮 不可交互 的背景色为这个，默认rgb(200, 200, 200)
         */
        @property (nonatomic, strong) UIColor *bottomBtnsDisableBgColor;
        
        /**
         是否在已选择的图片上方覆盖一层已选中遮罩层，默认 NO
         */
        @property (nonatomic, assign) BOOL showSelectedMask;
        
        /**
         遮罩层颜色，内部会默认调整颜色的透明度为0.2， 默认 blackColor
         */
        @property (nonatomic, strong) UIColor *selectedMaskColor;
        
        /**
         支持开发者自定义图片，但是所自定义图片资源名称必须与被替换的bundle中的图片名称一致
         @example: 开发者需要替换选中与未选中的图片资源，则需要传入的数组为 @[@"btn_selected", @"btn_unselected"]，则框架内会使用开发者项目中的图片资源，而其他图片则用框架bundle中的资源
         */
        @property (nonatomic, strong) NSArray<NSString *> *customImageNames;
        
        /**
         回调时候是否允许框架解析图片，默认YES
         
         @discussion 如果选择了大量图片，框架一下解析大量图片会耗费一些内存，开发者此时可置为NO，拿到assets数组后使用 ZLPhotoManager 中提供的 "anialysisAssets:original:completion:" 方法进行逐个解析，以达到缓解内存瞬间暴涨的效果，该值为NO时，回调的图片数组为nil
         */
        @property (nonatomic, assign) BOOL shouldAnialysisAsset;
        
        /**
         框架语言，默认 ZLLanguageSystem (跟随系统语言)
         */
        @property (nonatomic, assign) ZLLanguageType languageType;
        
        /**
         支持开发者自定义多语言提示，但是所自定义多语言的key必须与原key一致
         @example: 开发者需要替换 key: "ZLPhotoBrowserLoadingText"，value:"正在处理..." 的多语言，则需要传入的字典为 @{@"ZLPhotoBrowserLoadingText": @"需要替换的文字"}，而其他多语言则用框架中的（更改时请注意多语言中包含的占位符，如%ld、%@）
         */
        @property (nonatomic, strong) NSDictionary<NSString *, NSString *> *customLanguageKeyValue;
        
        /**
         使用系统相机，默认NO
         */
        @property (nonatomic, assign) BOOL useSystemCamera;
        
        /**
         是否允许录制视频，默认YES
         */
        @property (nonatomic, assign) BOOL allowRecordVideo;
        
        /**
         最大录制时长，默认 10s，最小为 1s
         */
        @property (nonatomic, assign) NSInteger maxRecordDuration;
        
        /**
         视频清晰度，默认ZLCaptureSessionPreset1280x720
         */
        @property (nonatomic, assign) ZLCaptureSessionPreset sessionPreset;
        
        /**
         录制视频及编辑视频时候的视频导出格式，默认ZLExportVideoTypeMov
         */
        @property (nonatomic, assign) ZLExportVideoType exportVideoType;
    }
    
    
    public override func viewDidLoad() {
        super.viewDidLoad()

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
        PHPhotoLibrary.requestAuthorization { [weak self] (status) in
            DispatchQueue.main.async { [weak self] in
                switch status {
                case .authorized:
                    break
                case .denied, .restricted:
                    let controller = LGUnauthorizedController()
                    self?.viewControllers = [controller]
                    break
                case .notDetermined:
                    break
                }
            }
            println(status)
        }
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

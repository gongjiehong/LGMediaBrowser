//
//  LGAuthorizationStatus.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/11/24.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import Foundation
import Photos
import CoreBluetooth
import Contacts
import EventKit
import HealthKit
import HomeKit
import CoreMotion
import StoreKit
import Intents
import Speech
import CoreNFC
import LocalAuthentication

/// 获取权限过程中的错误枚举
///
/// - unableToReadImmediately: 无法即时读取权限，需要调用特定方法获取
/// - privacyDescriptionNotSet: 该类型未在info.plist中设置对应的申请描述
/// - 类型不被支持
/// - 请求HealthKit权限时读取和写入项必须有一个不为空
public enum LGAuthorizationStatusError: Error {
    case unableToReadImmediately
    case privacyDescriptionNotSet(_ type: LGAuthorizationStatusManager.PrivacyType)
    case unSupportType(_ type: LGAuthorizationStatusManager.PrivacyType)
    case healthReadTypesOrShareTypesMustHaveOne
}

extension LGAuthorizationStatusError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .unableToReadImmediately:
            return "不支持即时读取权限，需要调用特定方法获取" +
            "requestPrivacy(withType type: PrivacyType, callback: PrivacyStatusCallback)"
        case .privacyDescriptionNotSet(let type):
            return "类型\(type)未在Info.plist中设置对应的申请理由"
        case .unSupportType(let type):
            return "类型\(type)不被支持"
        case .healthReadTypesOrShareTypesMustHaveOne:
            return "请求HealthKit权限时读取和写入项必须有一个不为空"
        }
    }
    
    public var localizedDescription: String {
        return errorDescription ?? "\(self)"
    }
}

/// 整合机器的各方面权限
public class LGAuthorizationStatusManager: NSObject {
    /// 权限类型穷举
    ///
    /// - location: 定位
    /// - contacts: 联系人
    /// - calendars: 日历
    /// - reminders: 提醒事项
    /// - photos: 相册
    /// - microphone: 麦克风
    /// - camera: 摄像头
    /// - healthWith: 健康
    /// - homeKit: 异步
    /// - motionAndFitness: 加速计
    /// - appleMusic: 苹果音乐
    /// - speechRecognition: 语音识别
    /// - siri: siri
    /// - bluetooth: 蓝牙
    /// - NFC: NFC
    /// - faceID: faceID
    /// - other: 其它，不支持
    public enum PrivacyType {
        case location
        case contacts
        case calendars
        case reminders
        case photos
        case microphone
        case camera
        case healthWith(shareTypes: Set<HKSampleType>?, readTypes: Set<HKObjectType>?)
        case homeKit
        case motionAndFitness
        @available(iOS 9.3, *)
        case appleMusic
        @available(iOS 10.0, *)
        case speechRecognition
        @available(iOS 10.0, *)
        case siri
        @available(iOS 10.0, *)
        case bluetooth
        @available(iOS 11.0, *)
        case NFC
        @available(iOS 11.0, *)
        case faceID
        case other
    }
    
    /// 权限在Info.plist中对应的key
    /// see: https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/CocoaKeys.html
    /// see: https://developer.apple.com/library/archive/samplecode/PrivacyPrompts/Introduction/Intro.html#//apple_ref/doc/uid/DTS40013410
    public struct PrivacyKeys {
        public static var LocationWhenInUseUsage = "NSLocationWhenInUseUsageDescription"
        public static var LocationAlwaysUsage = "NSLocationAlwaysUsageDescription"
        
        public static var NFCReaderUsage = "NFCReaderUsageDescription"
        
        public static var AppleMusicUsage = "NSAppleMusicUsageDescription"
        
        public static var CalendarsUsage = "NSCalendarsUsageDescription"
        
        public static var CameraUsage = "NSCameraUsageDescription"
        
        public static var ContactsUsage = "NSContactsUsageDescription"
        
        public static var FaceIDUsage = "NSFaceIDUsageDescription"
        
        public static var HealthClinicalHealthRecordsShareUsage = "NSHealthClinicalHealthRecordsShareUsageDescription"
        
        public static var HealthShareUsage = "NSHealthShareUsageDescription"
        
        public static var HealthUpdateUsage = "NSHealthUpdateUsageDescription"
        
        public static var HomeKitUsage = "NSHomeKitUsageDescription"
        
        public static var MicrophoneUsage = "NSMicrophoneUsageDescription"
        
        public static var MotionUsage = "NSMotionUsageDescription"
        
        public static var PhotoLibraryUsage = "NSPhotoLibraryUsageDescription"
        
        public static var PhotoLibraryAddUsage = "NSPhotoLibraryAddUsageDescription"
        
        public static var RemindersUsage = "NSRemindersUsageDescription"
        
        public static var SiriUsage = "NSSiriUsageDescription"
        
        public static var SpeechRecognition = "NSSpeechRecognitionUsageDescription"
        
        public static var BluetoothPeripheralUsage = "NSBluetoothPeripheralUsageDescription"
    }
    
    /// 权限状态定义
    ///
    /// - notDetermined: 未向用户获取该权限
    /// - restricted: 受限，家长控制什么的
    /// - denied: 用户拒绝
    /// - authorized: 用户已授权
    /// - serviceDisabled: 用户关闭该服务
    public enum Status: Int {
        case notDetermined
        
        case restricted
        
        case denied
        
        case authorized
        
        case unSupport
        
        public var isGranted: Bool {
            return self == LGAuthorizationStatusManager.Status.authorized
        }
    }
    
    public override init() {
        super.init()
    }
    
    // MARK: - 默认单例
    public static let `default`: LGAuthorizationStatusManager = {
        return LGAuthorizationStatusManager()
    }()
    
    
    // MARK: - 组装一些可以直接读取的状态
    public var albumStatus: Status {
        let status = PHPhotoLibrary.authorizationStatus()
        return Status(rawValue: status.rawValue) ?? .notDetermined
    }
    
    public var cameraStatus: Status {
        let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        return Status(rawValue: status.rawValue) ?? .notDetermined
    }
    
    public var microphoneStatus: Status {
        let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.audio)
        return Status(rawValue: status.rawValue) ?? .notDetermined
    }
    
    public var locationStatus: Status {
        if CLLocationManager.locationServicesEnabled() {
            return .unSupport
        }
        
        let status = CLLocationManager.authorizationStatus()
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            return .authorized
        case .denied:
            return .denied
        case .notDetermined:
            return .notDetermined
        case.restricted:
            return .restricted
        }
    }
    
    public var contactsStatus: Status {
        let status = CNContactStore.authorizationStatus(for: CNEntityType.contacts)
        return Status(rawValue: status.rawValue) ?? .notDetermined
    }
    
    public var calendarsStatus: Status {
        let status = EKEventStore.authorizationStatus(for: EKEntityType.event)
        return Status(rawValue: status.rawValue) ?? .notDetermined
    }
    
    public var remindersStatus: Status {
        let status = EKEventStore.authorizationStatus(for: EKEntityType.reminder)
        return Status(rawValue: status.rawValue) ?? .notDetermined
    }
    
    @available(iOS 11.0, *)
    public var motionStatus: Status {
        let status = CMMotionActivityManager.authorizationStatus()
        return Status(rawValue: status.rawValue) ?? .notDetermined
    }
    
    @available(iOS 9.3, *)
    public var appleMusicStatus: Status {
        let status = SKCloudServiceController.authorizationStatus()
        return Status(rawValue: status.rawValue) ?? .notDetermined
    }
    
    @available(iOS 10.0, *)
    public var siriStatus: Status {
        let status = INPreferences.siriAuthorizationStatus()
        return Status(rawValue: status.rawValue) ?? .notDetermined
    }
    
    @available(iOS 10.0, *)
    public var speechRecognitionStatus: Status {
        let status = SFSpeechRecognizer.authorizationStatus()
        return Status(rawValue: status.rawValue) ?? .notDetermined
    }
    
    @available(iOS 10.0, *)
    public var bluetoothStatus: Status {
        let status = bluetoothManager.state
        switch status {
        case .unknown:
            return .notDetermined
        case .unauthorized:
            return .denied
        case .unsupported:
            return .unSupport
        default:
            return .authorized
        }
    }
    
    // MARK: - 主线程直接读取状态，一部分不能读取的会抛出异常
    public func status(withPrivacyType type: PrivacyType) throws -> Status  {
        switch type {
        case .camera:
            return cameraStatus
        case .photos:
            return albumStatus
        case .microphone:
            return microphoneStatus
        case .location:
            return locationStatus
        case .contacts:
            return contactsStatus
        case .reminders:
            return remindersStatus
        case .motionAndFitness:
            if #available(iOS 11.0, *) {
                return motionStatus
            } else {
                throw LGAuthorizationStatusError.unSupportType(type)
            }
        case .appleMusic:
            if #available(iOS 9.3, *) {
                return appleMusicStatus
            } else {
                throw LGAuthorizationStatusError.unSupportType(type)
            }
        case .siri:
            if #available(iOS 10.0, *) {
                return siriStatus
            } else {
                throw LGAuthorizationStatusError.unSupportType(type)
            }
        case .speechRecognition:
            if #available(iOS 10.0, *) {
                return speechRecognitionStatus
            } else {
                throw LGAuthorizationStatusError.unSupportType(type)
            }
        case .bluetooth:
            if #available(iOS 10.0, *) {
                return bluetoothStatus
            } else {
                throw LGAuthorizationStatusError.unSupportType(type)
            }
        default:
            throw LGAuthorizationStatusError.unableToReadImmediately
        }
    }
    
    // MARK: - 根据不同的类型获取权限
    public typealias PrivacyStatusCallback = (PrivacyType, Status) -> Void
    public var callbackBlcok: PrivacyStatusCallback?
    public func requestPrivacy(withType type: PrivacyType, callback: @escaping PrivacyStatusCallback) throws {
        callbackBlcok = callback
        switch type {
        case .location:
            try requestLocationPrivacy(callback: callback)
            break
        case .contacts:
            try requestContactsPrivacy(callback: callback)
        case .calendars, .reminders:
            try requestEventPrivacy(callback: callback, type: type)
            break
        case .motionAndFitness:
            try requestMotionPrivacy(callback: callback)
            break
        case .photos:
            try requestPhotosPrivacy(callback: callback)
            break
        case .microphone:
            try requestMicrophonePrivacy(callback: callback)
            break
        case .camera:
            try requestCameraPrivacy(callback: callback)
            break
        case .homeKit:
            try requestHomeKitPrivacy(callback: callback)
            break
        case .healthWith(shareTypes: _, readTypes: _):
            try requestHealthPrivacy(callback: callback, type: type)
            break
        case .speechRecognition:
            try requestSpeechRecognitionPrivacy(callback: callback)
            break
        case .siri:
            try requestSiriPrivacy(callback: callback)
            break
        case .bluetooth:
            try requestBluetoothPrivacy(callback: callback)
            break
        case .NFC:
            try requestNFCPrivacy(callback: callback)
            break
        case .faceID:
            try requestFaceIDPrivacy(callback: callback)
            break
        default:
            break
        }
    }
    
    // MARK: - 定位
    var locationManager: CLLocationManager?
    func requestLocationPrivacy(callback: @escaping PrivacyStatusCallback) throws {
        let whenInUse = Bundle.main.infoDictionary?[PrivacyKeys.LocationWhenInUseUsage]
        let alwaysUse = Bundle.main.infoDictionary?[PrivacyKeys.LocationAlwaysUsage]
        
        guard whenInUse != nil || alwaysUse != nil else {
            println("需要在plist中设置如下内容:",
                    PrivacyKeys.LocationWhenInUseUsage,
                    "或:",
                    PrivacyKeys.LocationAlwaysUsage)
            throw LGAuthorizationStatusError.privacyDescriptionNotSet(.location)
        }
        
        
        if CLLocationManager.locationServicesEnabled() {
            if locationStatus == .notDetermined {
                if self.locationManager != nil {
                    self.locationManager = nil
                    
                }
                
                let locationManager = CLLocationManager()
                locationManager.delegate = self
                if alwaysUse != nil {
                    locationManager.requestAlwaysAuthorization()
                } else {
                    locationManager.requestWhenInUseAuthorization()
                }
                self.locationManager = locationManager
            } else {
                callback(.location, locationStatus)
            }
        } else {
            callback(.location, .unSupport)
        }
    }
    
    // MARK: - 联系人相关
    func requestContactsPrivacy(callback: @escaping PrivacyStatusCallback) throws {
        let contactsDes = Bundle.main.infoDictionary?[PrivacyKeys.ContactsUsage]
        
        guard contactsDes != nil else {
            println("需要在plist中设置如下内容:",
                    PrivacyKeys.ContactsUsage)
            throw LGAuthorizationStatusError.privacyDescriptionNotSet(.contacts)
        }
        
        if contactsStatus == .notDetermined {
            let contanctsStore = CNContactStore()
            contanctsStore.requestAccess(for: CNEntityType.contacts) { (granted, error) in
                DispatchQueue.main.async {
                    if let error = error {
                        println(error.localizedDescription)
                        callback(.contacts, .unSupport)
                    } else {
                        if granted {
                            callback(.contacts, .authorized)
                        } else {
                            callback(.contacts, .denied)
                        }
                    }
                }
            }
        } else {
            callback(.contacts, contactsStatus)
        }
    }
    
    // MARK: - 日历和提醒
    func requestEventPrivacy(callback: @escaping PrivacyStatusCallback, type: PrivacyType) throws {
        var descriptionKey: String
        var status: Status
        var entityType: EKEntityType
        switch type {
        case .calendars:
            status = calendarsStatus
            entityType = .event
            descriptionKey = PrivacyKeys.CalendarsUsage
            break
        case .reminders:
            status = remindersStatus
            entityType = .reminder
            descriptionKey = PrivacyKeys.RemindersUsage
            break
        default:
            throw LGAuthorizationStatusError.unSupportType(type)
        }
        
        
        let description = Bundle.main.infoDictionary?[descriptionKey]
        guard description != nil else {
            println("需要在plist中设置如下内容:",
                    descriptionKey)
            throw LGAuthorizationStatusError.privacyDescriptionNotSet(type)
        }
        
        
        if status == .notDetermined {
            let store = EKEventStore()
            store.requestAccess(to: entityType) { (granted, error) in
                DispatchQueue.main.async {
                    if let error = error {
                        println(error.localizedDescription)
                        callback(type, .unSupport)
                    } else {
                        if granted {
                            callback(.contacts, .authorized)
                        } else {
                            callback(.contacts, .denied)
                        }
                    }
                }
            }
        } else {
            callback(.calendars, calendarsStatus)
        }
    }
    
    // MARK: - 相册
    func requestPhotosPrivacy(callback: @escaping PrivacyStatusCallback) throws {
        let photoLibraryUsageDes = Bundle.main.infoDictionary?[PrivacyKeys.PhotoLibraryUsage]
        let photoLibraryAddUsageDes = Bundle.main.infoDictionary?[PrivacyKeys.PhotoLibraryAddUsage]
        
        guard photoLibraryUsageDes != nil && photoLibraryAddUsageDes != nil else {
            println("需要在plist中设置如下内容:",
                    PrivacyKeys.PhotoLibraryUsage,
                    PrivacyKeys.PhotoLibraryAddUsage)
            throw LGAuthorizationStatusError.privacyDescriptionNotSet(.photos)
        }
        
        if albumStatus == .notDetermined {
            PHPhotoLibrary.requestAuthorization { (status) in
                DispatchQueue.main.async { [weak self] in
                    guard let weakSelf = self else {return}
                    callback(.photos, weakSelf.albumStatus)
                }
            }
        } else {
            callback(.photos, albumStatus)
        }
    }
    
    // MARK: - 麦克风
    func requestMicrophonePrivacy(callback: @escaping PrivacyStatusCallback) throws {
        let description = Bundle.main.infoDictionary?[PrivacyKeys.MicrophoneUsage]
        guard description != nil else {
            println("需要在plist中设置如下内容:",
                    PrivacyKeys.MicrophoneUsage)
            throw LGAuthorizationStatusError.privacyDescriptionNotSet(.microphone)
        }
        
        if microphoneStatus == .notDetermined {
            AVCaptureDevice.requestAccess(for: AVMediaType.audio) { (granted) in
                DispatchQueue.main.async { [weak self] in
                    guard let weakSelf = self else {return}
                    callback(.microphone, weakSelf.microphoneStatus)
                }
            }
        } else {
            callback(.microphone, microphoneStatus)
        }
    }
    
    // MARK: - 摄像头
    func requestCameraPrivacy(callback: @escaping PrivacyStatusCallback) throws {
        let description = Bundle.main.infoDictionary?[PrivacyKeys.CameraUsage]
        guard description != nil else {
            println("需要在plist中设置如下内容:",
                    PrivacyKeys.CameraUsage)
            throw LGAuthorizationStatusError.privacyDescriptionNotSet(.camera)
        }
        
        if cameraStatus == .notDetermined {
            AVCaptureDevice.requestAccess(for: AVMediaType.video) { (granted) in
                DispatchQueue.main.async { [weak self] in
                    guard let weakSelf = self else {return}
                    callback(.camera, weakSelf.cameraStatus)
                }
            }
        } else {
            callback(.camera, cameraStatus)
        }
    }
    
    // MARK: - HealthKit
    public func requestHealthPrivacy(callback: @escaping PrivacyStatusCallback, type: PrivacyType) throws {
        switch type {
        case .healthWith(shareTypes: let shareTypes, readTypes: let readTypes):
            if (shareTypes != nil && readTypes != nil) || (shareTypes != nil && readTypes == nil) {
                let clinicalDes = Bundle.main.infoDictionary?[PrivacyKeys.HealthClinicalHealthRecordsShareUsage]
                let shareDes = Bundle.main.infoDictionary?[PrivacyKeys.HealthShareUsage]
                let updateDes = Bundle.main.infoDictionary?[PrivacyKeys.HealthUpdateUsage]
                guard clinicalDes != nil, shareDes != nil, updateDes != nil else {
                    println("需要在plist中设置如下内容:",
                            PrivacyKeys.HealthClinicalHealthRecordsShareUsage,
                            PrivacyKeys.HealthShareUsage,
                            PrivacyKeys.HealthUpdateUsage)
                    throw LGAuthorizationStatusError.privacyDescriptionNotSet(type)
                }
            } else if shareTypes == nil && readTypes != nil {
                let clinicalDes = Bundle.main.infoDictionary?[PrivacyKeys.HealthClinicalHealthRecordsShareUsage]
                let shareDes = Bundle.main.infoDictionary?[PrivacyKeys.HealthShareUsage]
                guard clinicalDes != nil, shareDes != nil else {
                    println("需要在plist中设置如下内容:",
                            PrivacyKeys.HealthClinicalHealthRecordsShareUsage,
                            PrivacyKeys.HealthShareUsage)
                    throw LGAuthorizationStatusError.privacyDescriptionNotSet(type)
                }
            } else {
                throw LGAuthorizationStatusError.healthReadTypesOrShareTypesMustHaveOne
            }
            
            HKHealthStore().requestAuthorization(toShare: shareTypes,
                                                 read: readTypes)
            { (granted, error) in
                if let error = error {
                    println(error.localizedDescription)
                    DispatchQueue.main.async {
                        callback(type, .unSupport)
                    }
                } else {
                    DispatchQueue.main.async {
                        callback(type, .authorized)
                    }
                }
            }
            break
        default:
            throw LGAuthorizationStatusError.unSupportType(type)
        }
    }
    
    // MARK: - HomeKit
    var homeManager: HMHomeManager?
    func requestHomeKitPrivacy(callback: @escaping PrivacyStatusCallback) throws {
        guard let _ = Bundle.main.infoDictionary?[PrivacyKeys.HomeKitUsage] else {
            println("需要在plist中设置如下内容:",
                    PrivacyKeys.HomeKitUsage)
            throw LGAuthorizationStatusError.privacyDescriptionNotSet(.homeKit)
        }
        if homeManager != nil {
            homeManager = nil
        }
        
        let manager = HMHomeManager()
        manager.delegate = self
        self.homeManager = manager
    }
    
    // MARK: - 加速计
    var motionManager: CMMotionActivityManager?
    lazy var motionQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.qualityOfService = .background
        return queue
    }()
    func requestMotionPrivacy(callback: @escaping PrivacyStatusCallback) throws {
        guard let _ = Bundle.main.infoDictionary?[PrivacyKeys.MotionUsage] else {
            println("需要在plist中设置如下内容:",
                    PrivacyKeys.MotionUsage)
            throw LGAuthorizationStatusError.privacyDescriptionNotSet(.motionAndFitness)
        }
        
        self.motionManager = CMMotionActivityManager()
        self.motionManager?.startActivityUpdates(to: motionQueue, withHandler: { (activity) in
            DispatchQueue.main.async {
                if #available(iOS 11.0, *) {
                    self.callbackBlcok?(.motionAndFitness, .authorized)
                } else {
                }
            }
        })
    }
    
    // MARK: - AppleMusic
    func requestAppleMusicPrivacy(callback: @escaping PrivacyStatusCallback) throws {
        guard let _ = Bundle.main.infoDictionary?[PrivacyKeys.AppleMusicUsage] else {
            println("需要在plist中设置如下内容:",
                    PrivacyKeys.AppleMusicUsage)
            if #available(iOS 9.3, *) {
                throw LGAuthorizationStatusError.privacyDescriptionNotSet(.appleMusic)
            } else {
                return
            }
        }
        
        if #available(iOS 9.3, *) {
            if self.appleMusicStatus == .notDetermined {
                SKCloudServiceController.requestAuthorization { (authorizationStatus) in
                    DispatchQueue.main.async { [weak self] in
                        guard let weakSelf = self else {return}
                        callback(.appleMusic, weakSelf.appleMusicStatus)
                    }
                }
            }
        } else {
        }
    }
    
    // MARK: - Siri
    func requestSiriPrivacy(callback: @escaping PrivacyStatusCallback) throws {
        guard let _ = Bundle.main.infoDictionary?[PrivacyKeys.SiriUsage] else {
            println("需要在plist中设置如下内容:",
                    PrivacyKeys.SiriUsage)
            if #available(iOS 10.0, *) {
                throw LGAuthorizationStatusError.privacyDescriptionNotSet(.siri)
            } else {
                return
            }
        }
        
        if #available(iOS 10.0, *) {
            if self.siriStatus == .notDetermined {
                INPreferences.requestSiriAuthorization { (authorizationStatus) in
                    DispatchQueue.main.async { [weak self] in
                        guard let weakSelf = self else {return}
                        callback(.siri, weakSelf.siriStatus)
                    }
                }
            }
        } else {
        }
    }
    
    // MARK: - 语音识别
    func requestSpeechRecognitionPrivacy(callback: @escaping PrivacyStatusCallback) throws {
        guard let _ = Bundle.main.infoDictionary?[PrivacyKeys.SpeechRecognition] else {
            println("需要在plist中设置如下内容:",
                    PrivacyKeys.SpeechRecognition)
            if #available(iOS 10.0, *) {
                throw LGAuthorizationStatusError.privacyDescriptionNotSet(.speechRecognition)
            } else {
                return
            }
        }
        
        if #available(iOS 10.0, *) {
            if self.speechRecognitionStatus == .notDetermined {
                SFSpeechRecognizer.requestAuthorization { (authorizationStatus) in
                    DispatchQueue.main.async { [weak self] in
                        guard let weakSelf = self else {return}
                        callback(.speechRecognition, weakSelf.speechRecognitionStatus)
                    }
                }
            }
        } else {
        }
        
    }
    
    // MARK: - 蓝牙BLE
    lazy var bluetoothManager: CBCentralManager =  {
        return CBCentralManager(delegate: self, queue: nil)
    }()
    func requestBluetoothPrivacy(callback: @escaping PrivacyStatusCallback) throws {
        guard let _ = Bundle.main.infoDictionary?[PrivacyKeys.BluetoothPeripheralUsage] else {
            println("需要在plist中设置如下内容:",
                    PrivacyKeys.BluetoothPeripheralUsage)
            if #available(iOS 10.0, *) {
                throw LGAuthorizationStatusError.privacyDescriptionNotSet(.bluetooth)
            } else {
                return
            }
        }
        
        if #available(iOS 10.0, *) {
            if self.bluetoothStatus == .notDetermined {
                bluetoothManager.scanForPeripherals(withServices: nil, options: nil)
            }
        } else {
        }
    }
    
    // MARK: - NFC
    var readerSession: AnyObject?
    func requestNFCPrivacy(callback: @escaping PrivacyStatusCallback) throws {
        guard let _ = Bundle.main.infoDictionary?[PrivacyKeys.NFCReaderUsage] else {
            println("需要在plist中设置如下内容:",
                    PrivacyKeys.NFCReaderUsage)
            if #available(iOS 11.0, *) {
                throw LGAuthorizationStatusError.privacyDescriptionNotSet(.NFC)
            } else {
                return
            }
        }
        
        if #available(iOS 11.0, *) {
            if NFCNDEFReaderSession.readingAvailable {
                readerSession = NFCNDEFReaderSession(delegate: self,
                                                     queue: nil,
                                                     invalidateAfterFirstRead: true)
            } else {
                callback(.NFC, .unSupport)
            }
        } else {
        }
    }
    
    // MARK: - faceID
    func requestFaceIDPrivacy(callback: @escaping PrivacyStatusCallback) throws {
        guard let _ = Bundle.main.infoDictionary?[PrivacyKeys.FaceIDUsage] else {
            println("需要在plist中设置如下内容:",
                    PrivacyKeys.FaceIDUsage)
            if #available(iOS 11.0, *) {
                throw LGAuthorizationStatusError.privacyDescriptionNotSet(.faceID)
            } else {
                return
            }
        }
        
        if #available(iOS 11.0, *) {
            let authenticationContext = LAContext()
            
            let reason = LGLocalizedString("Authentication is required to reset your password.")
            var authenticationError: NSError?
            if authenticationContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                                                       error: &authenticationError)
            {
                guard authenticationContext.biometryType == .faceID else {
                    DispatchQueue.main.async { [weak self] in
                        guard let weakSelf = self else {return}
                        weakSelf.callbackBlcok?(.faceID, .unSupport)
                    }
                    return
                }
                
                authenticationContext.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                                                     localizedReason: reason)
                { success, evaluateError in
                    if success {
                        DispatchQueue.main.async { [weak self] in
                            guard let weakSelf = self else {return}
                            weakSelf.callbackBlcok?(.faceID, .authorized)
                        }
                    } else {
                        DispatchQueue.main.async { [weak self] in
                            guard let weakSelf = self else {return}
                            weakSelf.callbackBlcok?(.faceID, .denied)
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    DispatchQueue.main.async { [weak self] in
                        guard let weakSelf = self else {return}
                        weakSelf.callbackBlcok?(.faceID, .notDetermined)
                    }
                }
            }
        } else {
        }
    }
}

// MARK: - CLLocationManagerDelegate定位状态更新回调
extension LGAuthorizationStatusManager: CLLocationManagerDelegate {
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async { [weak self] in
            guard let weakSelf = self else {return}
            weakSelf.callbackBlcok?(.location, weakSelf.locationStatus)
        }
    }
}

// MARK: - HMHomeManagerDelegate HomeKit状态回调
extension LGAuthorizationStatusManager: HMHomeManagerDelegate {
    public func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        if manager.homes.count > 0 {
            callbackBlcok?(.homeKit, .authorized)
        } else {
            manager.addHome(withName: "LGAuthorizationStatusManager.RequestPermission") { (home, error) in
                DispatchQueue.main.async { [weak self] in
                    guard let weakSelf = self else {return}
                    if error == nil {
                        weakSelf.callbackBlcok?(.homeKit, .authorized)
                    } else {
                        if (error as? HMError)?.code == HMError.homeAccessNotAuthorized {
                            weakSelf.callbackBlcok?(.homeKit, .denied)
                        } else {
                            weakSelf.callbackBlcok?(.homeKit, .authorized)
                        }
                    }
                }
                
                if let home = home {
                    manager.removeHome(home, completionHandler: { (error) in
                        if let error = error {
                            println(error.localizedDescription)
                        }
                    })
                }
            }
        }
    }
}

// MARK: - CBCentralManagerDelegate 蓝牙BLE状态回调
extension LGAuthorizationStatusManager: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        DispatchQueue.main.async { [weak self] in
            guard let weakSelf = self else {return}
            if #available(iOS 10.0, *) {
                weakSelf.callbackBlcok?(.bluetooth, weakSelf.bluetoothStatus)
            } else {
            }
        }
    }
}

// MARK: - NFCNDEFReaderSessionDelegate NFC回调
extension LGAuthorizationStatusManager: NFCNDEFReaderSessionDelegate {
    @available(iOS 11.0, *)
    public func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        DispatchQueue.main.async {[weak self] in
            guard let weakSelf = self else {return}
            weakSelf.callbackBlcok?(.NFC, .denied)
        }
    }
    
    @available(iOS 11.0, *)
    public func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        DispatchQueue.main.async {[weak self] in
            guard let weakSelf = self else {return}
            weakSelf.callbackBlcok?(.NFC, .authorized)
        }
    }
}

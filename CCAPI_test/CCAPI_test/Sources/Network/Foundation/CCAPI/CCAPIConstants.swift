//
//  CCAPIConstants.swift
//  CCAPI_test
//
//  Created by Subeen on 10/9/25.
//

/// CCAPI path 상수

import Foundation

struct CCAPIConstants {
    
    // MARK: - Versions
    enum Version {
        static let ver100 = "ver100"
        static let ver110 = "ver110"
        static let ver120 = "ver120"
        static let ver130 = "ver130"
        static let ver140 = "ver140"
        
        static let supported: [String] = [ver100, ver110, ver120, ver130, ver140]
    }
    
    // MARK: - HTTP Methods
    enum Method {
        static let get = "GET"
        static let put = "PUT"
        static let post = "POST"
        static let delete = "DELETE"
    }
    
    // MARK: - API Keys (계층 구조!)
    enum Key {
        
        static let topURLForDev = "topurlfordev"
        
        // MARK: - Device Status
        enum DeviceStatus {
            static let storage = "devicestatus/storage"
        }
        
        // MARK: - Functions
        enum Functions {
            static let datetime = "functions/datetime"
            static let wifiSetting = "functions/wifisetting"
            static let networkSetting = "functions/networksetting"
            static let cardFormat = "functions/cardformat"
            static let sensorCleaning = "functions/sensorcleaning"
            static let wifiConnection = "functions/wificonnection"
            static let networkConnection = "functions/networkconnection"
            
            enum SSL {
                static let cacert = "functions/ssl/cacert"
            }
            
            enum NetworkSetting {
                static let currentConnectionSetting = "functions/networksetting/currentconnectionsetting"
                static let connectionSetting = "functions/networksetting/connectionsetting"
                static let commSetting = "functions/networksetting/commsetting"
                static let functionSetting = "functions/networksetting/functionsetting"
            }
            
            enum Directory {
                static let create = "functions/directory/createdirectory"
            }
        }
        
        // MARK: - Contents
        enum Contents {
            static let root = "contents"
        }
        
        // MARK: - Shooting
        enum Shooting {
            
            // MARK: Control
            enum Control {
                static let shootingMode = "shooting/control/shootingmode"
                static let shutterButton = "shooting/control/shutterbutton"
                static let shutterButtonManual = "shooting/control/shutterbutton/manual"
                static let movieMode = "shooting/control/moviemode"
                static let ignoreShootingModeDialMode = "shooting/control/ignoreshootingmodedialmode"
                static let recButton = "shooting/control/recbutton"
                static let zoom = "shooting/control/zoom"
                static let driveFocus = "shooting/control/drivefocus"
                static let af = "shooting/control/af"
                static let flickerDetection = "shooting/control/flickerdetection"
                static let hfFlickerDetection = "shooting/control/hfflickerdetection"
                static let hfFlickerTV = "shooting/control/hfflickertv"
                static let powerZoom = "shooting/control/powerzoom"
            }
            
            // MARK: Settings
            enum Settings {
                static let antiFlickerShoot = "shooting/settings/antiflickershoot"
                static let hfAntiFlickerShoot = "shooting/settings/hfantiflickershoot"
                static let hfFlickerTV = "shooting/settings/hfflickertv"
            }
            
            // MARK: Liveview
            enum Liveview {
                static let root = "shooting/liveview"
                static let flip = "shooting/liveview/flip"
                static let flipDetail = "shooting/liveview/flipdetail"
                static let scroll = "shooting/liveview/scroll"
                static let scrollDetail = "shooting/liveview/scrolldetail"
                static let rtpSessionDesc = "shooting/liveview/rtpsessiondesc"
                static let rtp = "shooting/liveview/rtp"
                static let angleInformation = "shooting/liveview/angleinformation"
                static let afFramePosition = "shooting/liveview/afframeposition"
                static let clickWB = "shooting/liveview/clickwb"
            }
            
            // MARK: Optical Finder
            enum OpticalFinder {
                static let afAreaSelectionMode = "shooting/opticalfinder/afareaselectionmode"
                static let afAreaSelection = "shooting/opticalfinder/afareaselection"
                static let afFrameInformation = "shooting/opticalfinder/afframeinformation"
                static let afAreaInformation = "shooting/opticalfinder/afareainformation"
            }
        }
        
        // MARK: - Event
        enum Event {
            static let polling = "event/polling"
            static let monitoring = "event/monitoring"
        }
    }
    
    // MARK: - JSON Field Names (이것도 분류 가능!)
    enum Field {
        
        // MARK: Common
        static let message = "message"
        static let urlList = "url"
        static let value = "value"
        static let ability = "ability"
        static let action = "action"
        static let status = "status"
        static let result = "result"
        
        // MARK: Range
        static let min = "min"
        static let max = "max"
        static let step = "step"
        
        // MARK: Shooting
        enum Shooting {
            static let movieMode = "moviemode"
            static let recButton = "recbutton"
            static let liveview = "liveview"
            static let liveviewSize = "liveviewsize"
            static let cameraDisplay = "cameradisplay"
            
            enum Flicker {
                static let antiFlickerShoot = "antiflickershoot"
                static let hfAntiFlickerShoot = "hfantiflickershoot"
                static let hfFlickerTV = "hfflickertv"
                static let frequency = "frequency"
                static let tv = "tv"
            }
            
            enum AF {
                static let afAreaSelectionMode = "afareaselectionmode"
                static let afAreaSelection = "afareaselection"
                static let afFrame = "afframe"
                static let afArea = "afarea"
                static let select = "select"
            }
        }
        
        // MARK: Live View
        enum LiveView {
            static let histogram = "histogram"
            static let image = "image"
            static let visible = "visible"
            static let zoom = "zoom"
            static let magnification = "magnification"
            
            enum Position {
                static let x = "x"
                static let y = "y"
                static let width = "width"
                static let height = "height"
                static let positionX = "positionx"
                static let positionY = "positiony"
                static let positionWidth = "positionwidth"
                static let positionHeight = "positionheight"
            }
        }
        
        // MARK: Storage
        enum Storage {
            static let storage = "storage"
            static let storageList = "storagelist"
            static let storageName = "name"
            static let storageURL = "url"
            static let storagePath = "path"
        }
        
        // MARK: Battery
        enum Battery {
            static let battery = "battery"
            static let batteryList = "batterylist"
        }
        
        // MARK: Contents
        enum Contents {
            static let contentsNumber = "contentsnumber"
            static let pageNumber = "pagenumber"
            static let addedContents = "addedcontents"
            static let deletedContents = "deletedcontents"
        }
        
        // MARK: WiFi
        enum WiFi {
            static let ssid = "ssid"
            static let method = "method"
            static let channel = "channel"
            static let authentication = "authentication"
            static let encryption = "encryption"
            static let keyIndex = "keyindex"
            static let password = "password"
            
            enum IP {
                static let ipAddressSet = "ipaddressset"
                static let ipAddress = "ipaddress"
                static let subnetMask = "subnetmask"
                static let gateway = "gateway"
            }
            
            enum IPv4 {
                static let ipAddressSet = "ipv4_ipaddressset"
                static let ipAddress = "ipv4_ipaddress"
                static let subnetMask = "ipv4_subnetmask"
                static let gateway = "ipv4_gateway"
            }
            
            enum IPv6 {
                static let useIPv6 = "ipv6_useipv6"
                static let manualSetting = "ipv6_manual_setting"
                static let manualAddress = "ipv6_manual_address"
                static let prefixLength = "ipv6_prefixlength"
                static let gateway = "ipv6_gateway"
            }
        }
        
        // MARK: Settings
        static let datetime = "datetime"
        static let dst = "dst"
        static let recordFunctions = "recordfunctions"
        static let cardSelection = "cardselection"
        static let cardFormat = "cardformat"
        static let sensorCleaning = "sensorcleaning"
    }
    
    // MARK: - API Values
    enum Value {
        static let on = "on"
        static let off = "off"
        static let enable = "enable"
        static let disable = "disable"
        static let auto = "auto"
        static let manual = "manual"
        
        enum WiFi {
            static let infrastructure = "infrastructure"
            static let cameraAP = "cameraap"
            static let open = "open"
            static let sharedKey = "sharedkey"
            static let wpaWPA2PSK = "wpawpa2psk"
            static let none = "none"
            static let wep = "wep"
            static let tkipAES = "tkipaes"
            static let aes = "aes"
        }
        
        enum Zoom {
            static let stop = "stop"
            static let wide = "wide"
            static let tele = "tele"
        }
        
        enum AFSelect {
            static let notSelected: Int = 0x00
            static let selected: Int = 0x01
            static let notSelectable: Int = 0x02
        }
    }
}

// MARK: - Typealiases
typealias APIKey = CCAPIConstants.Key
typealias APIField = CCAPIConstants.Field
typealias APIValue = CCAPIConstants.Value
typealias HTTPMethod = CCAPIConstants.Method

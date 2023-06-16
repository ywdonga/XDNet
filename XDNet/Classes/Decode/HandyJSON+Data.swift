//
//  HandyRequest.swift
//  KfangNet
//
//  Created by matt on 2021/3/19.
//  Copyright © 2021 深圳市看房网科技有限公司. All rights reserved.
//

import Foundation
@_exported import XDFoundation
@_exported import HandyJSON

/// 因为MOYA返回的是Data数据格式，但是HandyJson默认接受是jsonString，所以拓展了一个方法，来接收Data
extension HandyJSON {
    
    public static func deserialize(from data: Data, designatedPath: String? = nil) -> Self? {
        return JSONDeserializer<Self>.deserializeFrom(data: data, designatedPath: designatedPath)
    }
}

/// Data数据格式转换JsonString
extension JSONDeserializer {
    public static func deserializeFrom(data: Data, designatedPath: String? = nil) -> T? {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
            if let jsonDict = jsonObject as? NSDictionary {
                return self.deserializeFrom(dict: jsonDict, designatedPath: designatedPath)
            }
        } catch let error {
            logError(error)
        }
        return nil
    }
}

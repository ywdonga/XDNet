//
//  Response+HandyJSON.swift
//  KfangNet
//
//  Created by matt on 2021/3/19.
//  Copyright © 2021 深圳市看房网科技有限公司. All rights reserved.
//

import Foundation
import HandyJSON

public struct HandyResponseModel<T: HandyJSON>: HandyJSON {
    public init() {
        code = .status(.success)
        message = nil
        data = nil
    }
    
    public var code: String
    public var message: String?
    public var data: T?
    
    mutating public func mapping(mapper: HelpingMapper) {
        
        mapper <<<
            code <-- "status"
        mapper <<<
            message <-- "message"
        mapper <<<
            data <-- "result"
    }
}

/// 当业务层只需要关心接口成功，不关心接口返回数据，使用该类型（当传入NoResult时，不会检查result字段，是基于HandyJSON协议）
extension NoResult: HandyJSON {
    // 对于声明为struct的Model，由于struct默认提供了空的init方法，所以不需要额外实现init方法。
}

/// 遵循AsResult，为ResponseModel增加一个get计算属性，在该方法中重新包装数据，传递到业务层
extension HandyResponseModel: AsResult {
    
    public var result: KFResult<T> {
        if code == .status(.success) {
            if let result = data {
                return .success(result)
            }
            if NoResult() is T {
                return .success(NoResult() as! T) // swiftlint:disable:this force_cast
            }
        }
        return .failure(.init(code: code, message: message ?? "请求失败"))
    }
}

extension Array: _ExtendCustomModelType where Element: HandyJSON {
    
}

extension Array: HandyJSON where Element: HandyJSON {
    
}

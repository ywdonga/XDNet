//
//  ApiDriverData.swift
//  KfangNet
//
//  Created by Matt on 2021/3/3.
//  Copyright © 2021 深圳市看房网科技有限公司. All rights reserved.
//

import Foundation

public typealias KFResult<T> = Result<T, KFError>
// public enum ApiResult<T> {
//    case value(T)
//    case message(KfangError)
// }
extension KFResult {
    
    /// 获取成功状态的值
    var value: Success? {
        if case .success(let val) = self {
            return val
        }
        return nil
    }
}

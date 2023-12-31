//
//  DataFrom.swift
//  KfangNet
//
//  Created by matt on 2021/3/19.
//  Copyright © 2021 深圳市看房网科技有限公司. All rights reserved.
//

import Foundation


/// 网络接口数据，默认缓存上一次网络请求数据
public enum NetworkData<T> {
    /// 来自本地缓存
    case cache(T)
    /// 来自网络请求
    case network(T)
}

extension NetworkData {
    
    /// 数据处理封装方法
    func received(onCache: (T) -> Void, onNework: (T) -> Void) {
        switch self {
        case .cache(let model):
            onCache(model)
        case .network(let model):
            onNework(model)
        }
    }
}

extension NetworkData where T == Data {
    
    public func mapTo<U>(_ type: U.Type) -> KFResult<NetworkData<U>> where U: HandyJSON {

        switch self {
        case .cache(let data):
            if let responseModel = HandyResponseModel<U>.deserialize(from: data), let responseModelData = responseModel.data {
                return .success(.cache(responseModelData))
            }
        case .network(let data):
            if let responseModel = HandyResponseModel<U>.deserialize(from: data), let responseModelData = responseModel.data {
                return .success(.network(responseModelData))
            }
        }
        return .failure(.decodeError)
    }
    
    public func mapTo<U>(_ type: U.Type) -> KFResult<NetworkData<U>> where U: Codable {
        
        switch self {
        case .cache(let data):
            switch data.useCodableDecode(U.self) {
            case .success(let model):
                return .success(.cache(model))
            case .failure(let err):
                return .failure(err)
            }
        case .network(let data):
            switch data.useCodableDecode(U.self) {
            case .success(let model):
                return .success(.network(model))
            case .failure(let err):
                return .failure(err)
            }
        }
    }
}

public extension Data {
    
    func useCodableDecode<T>(_ type: T.Type) -> KFResult<T> where T: Codable {
        do {
            let model = try JSONDecoder().decode(ResponseModel<T>.self, from: self)
            return model.result
        } catch let err as KFError {
            logError(err)
            return .failure(err)
        } catch {
            return .failure(KFError.decodeError)
        }
    }
    
    func useHandyJSONDecode<T>(_ type: T.Type) -> KFResult<T> where T: HandyJSON {
        if let responseModel = HandyResponseModel<T>.deserialize(from: self) {
            if responseModel.code == .status(.success) {
                if let responseModelData = responseModel.data {
                    return .success(responseModelData)
                } else {
                    if NoResult() is T {
                        return .success(NoResult() as! T)
                    } else {
                        return .failure(.noResultFieldError)
                    }
                }
            } else {
                return .failure(.init(code: responseModel.code, message: responseModel.message ?? "请求失败"))
            }
        }
        return .failure(.decodeError)
    }
    
}

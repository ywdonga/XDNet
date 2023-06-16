//
//  Modelable.swift
//  KfangNet
//
//  Created by matt on 2021/3/17.
//  Copyright © 2021 深圳市看房网科技有限公司. All rights reserved.
//

import Foundation
@_exported import RxSwift
@_exported import HandyJSON

/// 基于Observable的扩展 提供Codable解码能力
public struct UsingCodable<T> {
    var base: Observable<T>
}

/// 基于Observable的扩展 提供HandyJSON解码能力
public struct UsingHandyJSON<T> {
    var base: Observable<T>
}

/// 锚定到 Observable<NetworkData<Data>>类型
extension Observable where Element == NetworkData<Data> {
    
    public var useCodable: UsingCodable<Element> {
        return UsingCodable(base: self)
    }
    
    public var useHandyJSON: UsingHandyJSON<Element> {
        return UsingHandyJSON(base: self)
    }
}

/// 锚定到 Observable<Data>类型
extension Observable where Element == Data {
    
    public var useCodable: UsingCodable<Element> {
        return UsingCodable(base: self)
    }
    
    public var useHandyJSON: UsingHandyJSON<Element> {
        return UsingHandyJSON(base: self)
    }
}


extension UsingHandyJSON where T == NetworkData<Data> {
    
    public func decodeTo<U>(_ type: U.Type) -> Observable<NetworkData<U>> where U: HandyJSON {
        return base.map { (result) -> NetworkData<U> in
            switch result.mapTo(U.self) {
            case .success(let model):
                return model
            case .failure(let err):
                throw err
            }
        }
    }
}

extension UsingHandyJSON where T == Data {
    
    public func decodeTo<U>(_ type: U.Type) -> Observable<U> where U: HandyJSON {
        return base.map { (data) -> U in
            switch data.useHandyJSONDecode(U.self) {
            case .success(let model):
                return model
            case .failure(let err):
                throw err
            }
        }
    }
}


extension UsingCodable where T == NetworkData<Data> {
    
    public func decodeTo<U>(_ type: U.Type) -> Observable<NetworkData<U>> where U: Codable {
        return base.map { (result) -> NetworkData<U> in
            switch result.mapTo(U.self) {
            case .success(let model):
                return model
            case .failure(let err):
                throw err
            }
        }
    }
}

extension UsingCodable where T == Data {
    
    public func decodeTo<U>(_ type: U.Type) -> Observable<U> where U: Codable {
        return base.map { (data) -> U in
            switch data.useCodableDecode(U.self) {
            case .success(let model):
                return model
            case .failure(let err):
                throw err
            }
        }
    }
}

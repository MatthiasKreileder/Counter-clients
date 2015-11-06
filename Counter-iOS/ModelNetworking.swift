//
//  ModelNetworking.swift
//  Counter-iOS
//
//  Created by Honza Dvorsky on 11/5/15.
//  Copyright © 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import ReactiveCocoa
import Alamofire
import Keys

class ModelNetworkingFactory {
    
    static func create() -> ModelNetworking {
        let baseUrl = CounteriosKeys().baseURL()
        let modelNetworking = ModelNetworking(baseUrl: baseUrl)
        return modelNetworking
    }
}

class ModelNetworking {
    
    let baseUrl: String
    init(baseUrl: String) {
        self.baseUrl = baseUrl
    }
    
    func get() -> SignalProducer<Model, NSError> {
        
        let urlComps = NSURLComponents(string: self.baseUrl)!
        urlComps.path = "/sync"
        let url = urlComps.string!
        
        return SignalProducer {
            sink, disposable in
            
            Alamofire
                .request(.GET, url)
                .responseJSON {
                    (response) -> Void in
                    
                    if case let .Failure(error) = response.result {
                        sendError(sink, error)
                    } else if case let .Success(value) = response.result {
                        let dict = value as! NSDictionary
                        let model = try! Model(json: dict)
                        sendNext(sink, model)
                        sendCompleted(sink)
                    }
            }
        }.observeOn(UIScheduler())
    }
    
    func post(model: Model) -> SignalProducer<Model, NSError> {
        
        let urlComps = NSURLComponents(string: self.baseUrl)!
        urlComps.path = "/sync"
        urlComps.queryItems = [NSURLQueryItem(name: "clock", value: "\(model.clock)")]
        let url = urlComps.string!
        
        return SignalProducer {
            sink, disposable in
            
            Alamofire
                .request(.GET, url)
                .responseJSON {
                    (response) -> Void in
                    
                    if case let .Failure(error) = response.result {
                        sendError(sink, error)
                    } else if case let .Success(value) = response.result {
                        let dict = value as! NSDictionary
                        let newClock = dict["newClock"] as! Int
                        var updatedModel = model
                        updatedModel.clock = newClock
                        sendNext(sink, updatedModel)
                        sendCompleted(sink)
                    }
            }
        }.observeOn(UIScheduler())
    }
}

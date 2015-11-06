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
    let imageCache: NSCache
    
    init(baseUrl: String) {
        self.baseUrl = baseUrl
        self.imageCache = NSCache()
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
                        self.cacheImages(model, sink: sink)
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
    
    private func cacheImages(model: Model, sink: Event<Model, NSError> -> ()) {
        
        let toDownload = model
            .users
            .filter { $0.avatarUrl != nil }
            .filter { self.imageCache.objectForKey($0.id) == nil }
        if toDownload.count == 0 {
            sendCompleted(sink)
            return
        }
        
        let group = dispatch_group_create()
        toDownload.forEach { user in
            dispatch_group_enter(group)
            Alamofire
                .request(.GET, user.avatarUrl!)
                .responseData({ (response) -> Void in
                    let result = response.result
                    if case let .Failure(error) = result {
                        print("Failed to download image, error \(error)")
                    } else if case let .Success(value) = result {
                        //parse image
                        if let image = UIImage(data: value) {
                            self.imageCache.setObject(image, forKey: user.id)
                        }
                    }
                    dispatch_group_leave(group)
                })
        }
        
        dispatch_group_notify(group, dispatch_get_main_queue()) { () -> Void in
            
            var updatedModel = model
            updatedModel.users = model.users.map { (user) -> User in
                var upUser = user
                if user.avatarUrl != nil {
                    upUser.avatar = self.imageCache.objectForKey(user.id) as? UIImage
                }
                return upUser
            }

            sendNext(sink, updatedModel)
            sendCompleted(sink)
        }
    }
}

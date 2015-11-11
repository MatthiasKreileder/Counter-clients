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
        
        let body = model.jsonify() as! [String : AnyObject]
        
        return SignalProducer {
            sink, disposable in
            
            Alamofire
                .request(.POST, url, parameters: body, encoding: .JSON)
                .responseJSON {
                    (response) -> Void in
                    
                    if case let .Failure(error) = response.result {
                        sendError(sink, error)
                    } else if case let .Success(value) = response.result {
                        let dict = value as! NSDictionary
                        
                        if let errorCode = dict["code"] as? Int {
                            let errorDescription = dict["description"] as! String
                            sendError(sink, NSError(domain: "counter-ios", code: errorCode, userInfo: [
                                NSLocalizedDescriptionKey: errorDescription
                                ]))
                            return
                        }
                        
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
        
        let avatarsToDownload = model
            .users
            .filter { $0.avatarUrl != nil }
            .filter { self.imageCache.objectForKey($0.id) == nil }
            .map { ($0.id, $0.avatarUrl!) }
        let iconsToDownload = model
            .categories
            .filter { $0.iconUrl != nil }
            .filter { self.imageCache.objectForKey($0.id) == nil }
            .map { ($0.id, $0.iconUrl!) }
        let toDownload = avatarsToDownload + iconsToDownload
        
        if toDownload.count == 0 {
            let updatedModel = self.updateImagesFromCache(model)
            sendNext(sink, updatedModel)
            sendCompleted(sink)
            return
        }
        
        let group = dispatch_group_create()
        toDownload.forEach { task in
            dispatch_group_enter(group)
            Alamofire
                .request(.GET, task.1)
                .responseData({ (response) -> Void in
                    let result = response.result
                    if case let .Failure(error) = result {
                        print("Failed to download image, error \(error)")
                    } else if case let .Success(value) = result {
                        //parse image
                        if let image = UIImage(data: value) {
                            self.imageCache.setObject(image, forKey: task.0)
                        }
                    }
                    dispatch_group_leave(group)
                })
        }
        
        dispatch_group_notify(group, dispatch_get_main_queue()) { () -> Void in
            
            let updatedModel = self.updateImagesFromCache(model)
            sendNext(sink, updatedModel)
            sendCompleted(sink)
        }
    }
    
    private func updateImagesFromCache(model: Model) -> Model {
        
        var updatedModel = model
        
        //user avatars
        updatedModel.users = model.users.map { (user) -> User in
            var upUser = user
            if let image = self.imageCache.objectForKey(user.id) as? UIImage {
                upUser.avatar = image
            } else {
                upUser.avatar = UIImage(named: "no_avatar")
            }
            return upUser
        }
        
        //category icons
        updatedModel.categories = model.categories.map { (category) -> Category in
            var upCat = category
            if let icon = self.imageCache.objectForKey(category.id) as? UIImage {
                upCat.icon = icon
            } else {
                upCat.icon = UIImage(named: "no_icon")
            }
            return upCat
        }
        
        return updatedModel
    }
}

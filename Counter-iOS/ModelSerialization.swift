//
//  ModelSerialization.swift
//  Counter-iOS
//
//  Created by Honza Dvorsky on 11/5/15.
//  Copyright © 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import SwiftyJSON

protocol JSONFriendly {
    init(json: NSDictionary) throws
    func jsonify() -> NSDictionary
}

extension Category: JSONFriendly {
    
    init(json: NSDictionary) throws {
        let parsed = JSON(json)
        self.id = parsed["id"].stringValue
        self.name = parsed["name"].stringValue
    }
    
    func jsonify() -> NSDictionary {
        var json = JSON([:])
        json["id"].stringValue = self.id
        json["name"].stringValue = self.name
        return json.dictionaryObject!
    }
}

extension Scores: JSONFriendly {
    
    init(json: NSDictionary) throws {
        self.dict = json as! [String : Int]
    }
    
    func jsonify() -> NSDictionary {
        return self.dict
    }
}

extension User: JSONFriendly {
    
    init(json: NSDictionary) throws {
        let parsed = JSON(json)
        self.id = parsed["id"].stringValue
        self.name = parsed["name"].stringValue
        self.avatarUrl = parsed["avatarUrl"].string
        self.scores = try Scores(json: parsed["scores"].dictionaryObject!)
        self.avatar = nil
    }
    
    func jsonify() -> NSDictionary {
        var json = JSON([:])
        json["id"].stringValue = self.id
        json["name"].stringValue = self.name
        json["avatarUrl"].string = self.avatarUrl
        json["scores"].dictionaryObject = (self.scores.jsonify() as! [String : AnyObject])
        return json.dictionaryObject!
    }
}

extension Model: JSONFriendly {
    
    init(json: NSDictionary) throws {
        let parsed = JSON(json)
        self.clock = parsed["clock"].intValue
        self.users = try parsed["users"].arrayValue.map { try User(json: $0.dictionaryObject!) }
        self.categories = try parsed["categories"].arrayValue.map { try Category(json: $0.dictionaryObject!) }
    }
    
    func jsonify() -> NSDictionary {
        var json = JSON([:])
        json["clock"].intValue = self.clock
        json["users"].arrayObject = self.users.map { $0.jsonify() }
        json["categories"].arrayObject = self.categories.map { $0.jsonify() }
        return json.dictionaryObject!
    }
}


//
//  Model.swift
//  Counter-iOS
//
//  Created by Honza Dvorsky on 11/5/15.
//  Copyright © 2015 Honza Dvorsky. All rights reserved.
//

import UIKit

struct Model {
    var clock: Int
    var users: [User]
    var categories: [Category]
    
    init() {
        self.clock = 1
        self.users = []
        self.categories = []
    }
    
    mutating func merge(other: Model) {
        
        self.clock = max(self.clock, other.clock)
        
        var selfUsers = self.users.dictionarify { $0.id }
        let otherUsers = other.users.dictionarify { $0.id }
        
        for (key, value) in otherUsers {
            if let selfUser = selfUsers[key] {
                var mergedUser = value
                mergedUser.scores.merge(selfUser.scores)
                selfUsers[key] = mergedUser
            } else {
                selfUsers[key] = value
            }
        }
        
        self.users = selfUsers.values.sort { $0.0.name < $0.1.name }
        
        var selfCats = self.categories.dictionarify { $0.id }
        for category in other.categories {
            selfCats[category.id] = category
        }
        
        self.categories = selfCats.values.sort { $0.0.name < $0.1.name }
    }
}

struct Category {
    let id: String
    let name: String
    let iconUrl: String?
    
    //supplied by a local cache
    var icon: UIImage?
}

struct User {
    let id: String
    let name: String
    let avatarUrl: String?
    var scores: Scores
    
    //supplied by a local cache
    var avatar: UIImage?
}

struct Scores {
    var dict: [String: Int]
    
    mutating func merge(other: Scores) {
        
        for (key, value) in other.dict {
            if let selfValue = self.dict[key] {
                self.dict[key] = max(value, selfValue)
            } else {
                self.dict[key] = value
            }
        }
    }
}

extension Array {
    
    func dictionarify(key: Element -> String) -> [String: Element] {
        var dict = [String: Element]()
        self.forEach {
            dict[key($0)] = $0
        }
        return dict
    }
}

//
//  Model.swift
//  Counter-iOS
//
//  Created by Honza Dvorsky on 11/5/15.
//  Copyright © 2015 Honza Dvorsky. All rights reserved.
//

import Foundation

struct Model {
    var clock: Int
    var users: [User]
    let categories: [Category]
}

struct Category {
    let id: String
    let name: String
}

struct User {
    let id: String
    let name: String
    let avatarUrl: String?
    var scores: Scores
}

struct Scores {
    var dict: [String: Int]
}

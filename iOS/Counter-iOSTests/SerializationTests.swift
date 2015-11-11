//
//  SerializationTests.swift
//  Counter-iOS
//
//  Created by Honza Dvorsky on 11/5/15.
//  Copyright © 2015 Honza Dvorsky. All rights reserved.
//

import XCTest
@testable import Counter_iOS
import Nimble

class SerializationTests: XCTestCase {
    
    var testRaw: NSDictionary = [
        "clock": 434,
        "users": [
            [
                "name": "Honza Dvorsky",
                "id": "1471255F-3F5E-47E3-93C1-5D4F536E63F5",
                "avatarUrl": "http://honzadvorsky.com/pages/portfolio/images/hd1.jpg",
                "scores": [
                    "651425FD-F3AD-47CB-A8BC-BE88340C515C": 14,
                ]
            ]
        ],
        "categories": [
            [
                "name": "Dad Jokes",
                "id": "651425FD-F3AD-47CB-A8BC-BE88340C515C",
                "iconUrl": "https://maxcdn.icons8.com/iOS7/PNG/50/Messaging/lol-50.png"
            ],
            [
                "name": "Overslept",
                "id": "50546704-1B1E-416B-900A-A81FFC2C42FE",
                "iconUrl": "https://maxcdn.icons8.com/iOS7/PNG/50/Household/sleeping_in_bed-50.png"
            ]
        ]
    ]
    
    func testSerializationIsSymmetric() {
        
        let orig = self.testRaw
        let model = try! Model(json: orig)
        let generated = model.jsonify()
        expect(generated) == orig
    }
    
}

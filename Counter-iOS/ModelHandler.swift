//
//  ModelHandler.swift
//  Counter-iOS
//
//  Created by Honza Dvorsky on 11/5/15.
//  Copyright © 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import ReactiveCocoa

class ModelHandler {
    
    let net: ModelNetworking
    
    let model = MutableProperty<Model?>(nil)
    let isRefreshing = MutableProperty<Bool>(false)
    
    init(net: ModelNetworking) {
        self.net = net
    }
    
    func refresh(completion: (() -> ())?) {
        self.net.get().start(Event.sink(error: { (error) -> () in
            print("Error \(error)")
            }, completed: { () -> () in
                completion?()
            }, next: { [weak self] model in
                self?.model.value = model
                print("Updated model to \(model)")
            }
            )
        )
    }
}

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
        
        self.model.producer.startWithNext {
            print("Updated model to \($0?.clock ?? 0)")
        }
    }
    
    func refresh(completion: (() -> ())?) {
        self.net.get().start(Event.sink(error: { (error) -> () in
            print("Error \(error)")
            }, completed: { () -> () in
                completion?()
            }, next: { [weak self] model in
                var newModel = self?.model.value ?? Model()
                newModel.merge(model)
                self?.model.value = newModel
            })
        )
    }
    
    func performUpdate(update: Model -> Model) {
        
        let model = self.model.value ?? Model()
        let updatedModel = update(model)
        self.model.value = updatedModel
        
        self.attemptPost(updatedModel, retry: false)
    }
    
    func attemptPost(model: Model, retry: Bool) {
        
        //try to post
        self.net
            .post(model)
            .start(Event.sink(error:
                { [weak self] (error) -> () in
                    print(error)
                    
                    //handle known errors
                    switch error.code {
                    case 1000:
                        
                        if !retry {
                            //clock mismatch, get, merge and try again
                            self?.refresh({ () -> () in
                                var newModel = self?.model.value ?? Model()
                                newModel.merge(model)
                                self?.model.value = newModel
                                self?.attemptPost(newModel, retry: true)
                            })
                        }
                        
                    default: break
                    }
                    
                }, next: { [weak self] model in
                    self?.model.value = model
                })
        )
    }
}

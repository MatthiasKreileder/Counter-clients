//
//  UsersViewController.swift
//  Counter-iOS
//
//  Created by Honza Dvorsky on 11/5/15.
//  Copyright © 2015 Honza Dvorsky. All rights reserved.
//

import UIKit
import ReactiveCocoa

class UsersViewController: UICollectionViewController {
    
    var modelHandler: ModelHandler!
    let model = MutableProperty<Model?>(nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //TODO: move
        let net = ModelNetworkingFactory.create()
        self.modelHandler = ModelHandler(net: net)
        
        self.model <~ self.modelHandler.model
        self.model.producer.startWithNext { [weak self] _ in
            self?.collectionView?.reloadData()
        }
        
        //TODO: add a connection indicator
        
        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = UIColor.whiteColor()
        refreshControl.addTarget(self, action: "refresh:", forControlEvents: UIControlEvents.ValueChanged)
        self.collectionView?.addSubview(refreshControl)
    }
    
    func refresh(refreshControl: UIRefreshControl) {
        
        self.modelHandler.refresh {
            refreshControl.endRefreshing()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.modelHandler.refresh(nil)
    }
    
    //data source
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.model.value?.users.count ?? 0
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("userCell", forIndexPath: indexPath) as! UserViewCell
        
        let model = self.model.value!
        let user = model.users[indexPath.item]
        
        cell.configureForUser(user, categories: model.categories)
        return cell
    }
}

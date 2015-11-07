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
        
        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = UIColor.whiteColor()
        refreshControl.addTarget(self, action: "refresh:", forControlEvents: UIControlEvents.ValueChanged)
        self.collectionView?.addSubview(refreshControl)
        
        NSNotificationCenter
            .defaultCenter()
            .rac_notifications("UIApplicationDidBecomeActiveNotification", object: nil)
            .startWithNext { [weak self] _ in
                self?.modelHandler.refresh(nil)
        }
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
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let user = self.model.value!.users[indexPath.item]
        self.showActionsForUser(user)
        collectionView.deselectItemAtIndexPath(indexPath, animated: true)
    }
    
    //showing action sheets
    func showActionsForUser(user: User) {
        print("Showing actions for user \(user.name)")
        
        let model = self.model.value!
        
        //gather categories that can be incremented
        let categories = model.categories
        
        let alert = UIAlertController(title: "Categories", message: "What has \(user.name) done this time?", preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        categories.forEach { cat in
            
            let score = user.scores.dict[cat.id] ?? 0
            let desc = "\(cat.name) (\(score))"

            alert.addAction(UIAlertAction(title: desc, style: UIAlertActionStyle.Default, handler: { [ weak self] _ in
                self?.categorySelected(user, category: cat)
            }))
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func categorySelected(var user: User, category: Category) {
        print("Action \(category.name) selected for \(user.name)")
    
        self.modelHandler.performUpdate { (var model) -> Model in
            let newVal = (user.scores.dict[category.id] ?? 0) + 1
            user.scores.dict[category.id] = newVal
            let idx = model.users.indexOf { $0.id == user.id }!
            model.users[idx] = user
            return model
        }
    }
}









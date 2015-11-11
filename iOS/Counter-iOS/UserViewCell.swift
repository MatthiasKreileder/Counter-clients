//
//  UserViewCell.swift
//  Counter-iOS
//
//  Created by Honza Dvorsky on 11/5/15.
//  Copyright © 2015 Honza Dvorsky. All rights reserved.
//

import UIKit

class UserViewCell: UICollectionViewCell {
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var scoresCollectionView: UICollectionView!
    
    private var user: User?
    private var categories: [Category]?
    
    func configureForUser(user: User, categories: [Category]) {
        
        self.user = user
        self.categories = categories
        
        self.imageView.image = user.avatar
        self.nameLabel.text = user.name
        self.scoresCollectionView.reloadData()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let nib = UINib(nibName: "ScoreCell", bundle: nil)
        self.scoresCollectionView.registerNib(nib, forCellWithReuseIdentifier: "ScoreCell")
        self.scoresCollectionView.dataSource = self
    }
}

extension UserViewCell: UICollectionViewDataSource {
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.user?.scores.dict.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("ScoreCell", forIndexPath: indexPath) as! ScoreCell
        
        let scores = self.user!.scores.dict
        let categoryId = scores.keys.sort()[indexPath.item]
        let count = scores[categoryId]!
        let category = self.categories!.filter { $0.id == categoryId }.first!
        
        cell.imageView.image = category.icon
        cell.scoreLabel.text = "\(count)"
        
        return cell
    }
}

class ScoreCell: UICollectionViewCell {
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var scoreLabel: UILabel!
}




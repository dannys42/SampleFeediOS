//
//  PostCell.swift
//  SampleFeediOS
//
//  Created by Danny Sung on 02/02/2020.
//  Copyright © 2020 Sung Heroes. All rights reserved.
//

import UIKit
import CoreData

class PostCell: UITableViewCell {
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var userLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!

    var post: Post? {
        didSet {
            if let post = post {
                self.update(post: post)
            } else {
                self.clear()
            }
        }
    }
        
    override func prepareForReuse() {
        self.clear()
    }

}

fileprivate extension PostCell {
    func clear() {
        self.textView.text = nil
        self.userLabel.text = nil
        self.timeLabel.text = nil
    }
    func update(post: Post) {
        self.textView.text = post.text
        self.userLabel.text = post.author?.name
        self.timeLabel.text = nil
    }
}

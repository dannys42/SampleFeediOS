//
//  DetailViewController.swift
//  SampleFeediOS
//
//  Created by Danny Sung on 02/01/2020.
//  Copyright © 2020 Sung Heroes. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {

    @IBOutlet weak var detailDescriptionLabel: UILabel!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var postButton: UIButton!
    public var wallId: Int? {
        didSet {
            guard let wallId = self.wallId else {
                return
            }
            FeedController.shared.updatePosts(wallId: wallId)
        }
    }

    func configureView() {
        // Update the user interface for the detail item.
        if let detail = detailItem {
            if let label = detailDescriptionLabel {
                label.text = detail.topic ?? "(no topic)"
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        configureView()
    }

    var detailItem: Wall? {
        didSet {
            // Update the view.
            configureView()
        }
    }

    @IBAction func postButtonDidPress(_ sender: UIButton) {
        guard let wallId = self.wallId else {
            return
        }
        guard let text = self.textView.text,
            text != "" else {
            // silently ignore post if no text
            return
        }
        
        let post = FeedController.PostCreateModel(text: text)
        FeedController.shared.createPost(wallId: wallId, post: post) { result in
            switch result {
            case .failure(let error):
                print("create post error: \(error.localizedDescription)")
            case .success(let postModel):
                print("created post: \(postModel)")
            }
        }
    }
}


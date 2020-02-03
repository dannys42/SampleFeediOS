//
//  DetailViewController.swift
//  SampleFeediOS
//
//  Created by Danny Sung on 02/01/2020.
//  Copyright © 2020 Sung Heroes. All rights reserved.
//

import UIKit
import CoreData

class DetailViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var detailDescriptionLabel: UILabel!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var postButton: UIButton!
    public var wallId: Int? {
        willSet {
            if wallId != newValue {
                self._fetchedResultsController = nil
            }
        }
        didSet {
            guard let wallId = self.wallId else {
                return
            }
            FeedController.shared.updatePosts(wallId: wallId)
            try? self.fetchedResultsController.performFetch()
        }
    }
    var managedObjectContext: NSManagedObjectContext? = nil

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
        let q = DispatchQueue.main
        
        q.async { self.postInProgress() }
        
        FeedController.shared.createPost(wallId: wallId, post: post) { result in
            defer { q.async { self.postComplete() } }
            
            switch result {
            case .failure(let error):
                print("create post error: \(error.localizedDescription)")
            case .success(let postModel):
                print("created post: \(postModel)")
            }
        }
    }
    
    private func postInProgress() {
        self.textView.textColor = .lightText
        self.postButton.alpha = 0.5
    }
    
    private func postComplete() {
        self.textView.textColor = .darkText
        self.postButton.alpha = 1.0
        self.textView.text = ""
    }
    
    // MARK: - Fetched results controller

    var fetchedResultsController: NSFetchedResultsController<Post> {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let fetchRequest: NSFetchRequest<Post> = Post.fetchRequest()
        
        if let wallId = self.wallId {
            fetchRequest.predicate = NSPredicate(format: "wall.id = %d", wallId)
        } else {
            fetchRequest.predicate = NSPredicate(value: false)
        }
        // Set the batch size to a suitable number.
        fetchRequest.fetchBatchSize = 20
        
        // Edit the sort key as appropriate.
        let sortDescriptor = NSSortDescriptor(key: "id", ascending: false)
        
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // Edit the section name key path and cache name if appropriate.
        // nil for section name key path means "no sections".
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: nil, cacheName: "Detail")
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController
        
        do {
            try _fetchedResultsController!.performFetch()
        } catch {
             // Replace this implementation with code to handle the error appropriately.
             // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
             let nserror = error as NSError
             fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
        
        return _fetchedResultsController!
    }
    var _fetchedResultsController: NSFetchedResultsController<Post>? = nil

}

// MARK: - UITableViewDataSource
extension DetailViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section]
        
        return sectionInfo.numberOfObjects
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TextPostCell", for: indexPath) as! PostCell
        let post = fetchedResultsController.object(at: indexPath)
        configureCell(cell, withPost: post)
        return cell
    }
    
    func configureCell(_ cell: PostCell, withPost post: Post) {
        cell.post = post
    }
}

// MARK: - UITableViewDelegate
extension DetailViewController: UITableViewDelegate {
    
}

// MARK: - NSFetchedResultsControllerDelegate
extension DetailViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
            case .insert:
                tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
            case .delete:
                tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
            default:
                return
        }
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
            case .insert:
                tableView.insertRows(at: [newIndexPath!], with: .fade)
            case .delete:
                tableView.deleteRows(at: [indexPath!], with: .fade)
            case .update:
                guard let post = anObject as? Post else {
                    assertionFailure("fetch controller can only return Post objects")
                    return
                }
                if let postCell = tableView.cellForRow(at: indexPath!) as? PostCell {
                    postCell.post = post
                }
                break
            case .move:
                guard let post = anObject as? Post else {
                    assertionFailure("fetch controller can only return Post objects")
                    return
                }

                if let postCell = tableView.cellForRow(at: indexPath!) as? PostCell {
                    postCell.post = post
                }
                tableView.moveRow(at: indexPath!, to: newIndexPath!)
            default:
                return
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
}

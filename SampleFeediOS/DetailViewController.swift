//
//  DetailViewController.swift
//  SampleFeediOS
//
//  Created by Danny Sung on 02/01/2020.
//  Copyright © 2020 Sung Heroes. All rights reserved.
//

import UIKit
import CoreData
import MBProgressHUD

class DetailViewController: UIViewController {

    @IBOutlet var keyboardToolbar: UIToolbar!
    @IBOutlet weak var keyboardSpacerView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var detailDescriptionLabel: UILabel!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var postButton: UIButton!
    
    /// Constraint used to keep textview visible when keyboard is displayed
    private var keyboardSpacerConstraint: NSLayoutConstraint? {
        willSet {
            // remove old constraint
            if let constraint = self.keyboardSpacerConstraint {
                DispatchQueue.main.async { [weak self] in
                    self?.keyboardSpacerView.removeConstraint(constraint)
                }
            }
        }
        didSet {
            // add new constraint
            if let constraint = self.keyboardSpacerConstraint {
                DispatchQueue.main.async { [weak self] in
                    self?.keyboardSpacerView.addConstraint(constraint)
                }
            }
        }
    }
    
    public var topic: String? {
        didSet {
            self.navigationController?.title = topic
        }
    }
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
    
    var wallEntry: Wall? {
        didSet {
            // Update the view.
            configureView()
            self.title = self.wallEntry?.topic
        }
    }

    func configureView() {
        // Update the user interface for the detail item.
        if let detail = wallEntry {
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let noteCenter = NotificationCenter.default
    
        noteCenter.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        noteCenter.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)

        self.keyboardSpacerConstraint = nil
        self.textView.inputAccessoryView = self.keyboardToolbar
    }
    
    @IBAction func keyboardDismissButtonPressed(_ sender: UIBarButtonItem) {
        self.textView.resignFirstResponder()
    }
    
    
    /// Send a post through the network.
    /// The post is not visible immediately, but instead triggers a sync action.
    /// - Parameter sender: the button that triggered the press event
    @IBAction func postButtonDidPress(_ sender: UIButton) {
        self.textView.resignFirstResponder()
        
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
        
        let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
        hud.mode = .indeterminate
        hud.label.text = "Sending post..."
        
        FeedController.shared.createPost(wallId: wallId, post: post) { result in
            defer { q.async {
                self.postComplete()
                hud.hide(animated: true)
            }}
            
            switch result {
            case .failure(let error):
                print("create post error: \(error.localizedDescription)")
            case .success(let postModel):
                print("created post: \(postModel)")
            }
        }
    }
    
    /// Convenience method to handle setup when a post operation is starting
    private func postInProgress() {
        self.textView.textColor = .lightText
        self.postButton.alpha = 0.5
        self.textView.resignFirstResponder()
        self.postButton.isEnabled = false
    }
    
    /// Convenience method to handle setup when a post operation has ended
    private func postComplete() {
        self.textView.textColor = .darkText
        self.postButton.alpha = 1.0
        self.textView.text = ""
        self.textView.resignFirstResponder()
        self.postButton.isEnabled = true
    }
    
    // MARK: - Fetched results controller

    // Setup fetched results controller to show all posts in a wall.
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

    
    // MARK: keyboard handler
    
    /// Add vertical spacing when keyboard appears.
    @objc
    func keyboardWillShow(_ note: Notification) {
        guard keyboardSpacerConstraint == nil else { return }

        if let keyboardSize = (note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            self.keyboardSpacerConstraint = NSLayoutConstraint(item: self.keyboardSpacerView as Any,
                                                               attribute: .height,
                                                               relatedBy: .equal,
                                                               toItem: nil,
                                                               attribute: .notAnAttribute,
                                                               multiplier: 1.0,
                                                               constant: keyboardSize.height)
        }
    }
    
    /// Remove veritcal spacing for keyboard
    @objc
    func keyboardWillHide(_ note: Notification) {
        self.keyboardSpacerConstraint = nil
    }
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
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        // if the user taps a cell, dismiss the textView
        self.textView.resignFirstResponder()
        
        // no cell selections
        return false
    }
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


//
//  UserSelectionViewController.swift
//  Scoops
//
//  Created by Verónica Cordobés on 23/10/16.
//  Copyright © 2016 Verónica Cordobés. All rights reserved.
//

import UIKit

class UserSelectionViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func showAuthorInterface(_ sender: AnyObject) {
        let author = Author(name: "Pedro")
        let newsVC = NewsTableTableViewController(author: author)
        navigationController?.pushViewController(newsVC, animated: true)
    }

    @IBAction func showReaderInterface(_ sender: AnyObject) {
        let newsVC = ReaderNewsTableTableViewController(nibName: nil, bundle: nil)
        navigationController?.pushViewController(newsVC, animated: true)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

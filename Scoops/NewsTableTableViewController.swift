//
//  NewsTableTableViewController.swift
//  Scoops
//
//  Created by Verónica Cordobés on 23/10/16.
//  Copyright © 2016 Verónica Cordobés. All rights reserved.
//

import UIKit

typealias AutorRecord = Dictionary<String, AnyObject>

class NewsTableTableViewController: UITableViewController {
    
    var client : MSClient = MSClient(applicationURL: URL(string: "https://boot3labsv.azurewebsites.net")!)
    var model : [Dictionary<String, AnyObject>]? = []
    
    var userIdentity : [Dictionary<String, AnyObject>]? = []
    
    var author : Author
    
    
    init(author: Author){
        self.author = author
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()

        if let _ = client.currentUser{
            readAllItemsInTable()
        } else {
            doLoginInFacebook()
        }
        
        addNewsButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        readAllItemsInTable()
        
        tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // Setup for the login with Facebook
    func doLoginInFacebook() {
        
        client.login(withProvider: "facebook", parameters: nil, controller: self, animated: true) { (user, error) in
            
            if let _ = error {
                print(error)
                return
            }
            
            if let _ = user {
                self.readAllItemsInTable()
                self.getUserIdentity()
            }
        }
    }
    
    func addNewsButton(){
        let btn = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addNews))
        
        navigationItem.rightBarButtonItem = btn
    }
    
    // MARK: - Actions
    func addNews(){
        let news = News(author: author, title: "", text: "", photo: nil)
        let newsDetailVC = NewsDetailViewController(author: author, news: news)
        navigationController?.pushViewController(newsDetailVC, animated: true)
    }
    
    
    // Download the news saved in the table
    func readAllItemsInTable(){
        client.invokeAPI("readAllRecords", body: nil, httpMethod: "GET", parameters: nil, headers: nil) { (result, respose, error) in
            
            
            if let _ = error {
                print(error)
                return
            }
            
            if !((self.model?.isEmpty)!) {
                self.model?.removeAll()
            }
            
            if let _ = result {
                
                let json = result as! [AutorRecord]
                
                for item in json {
                    self.model?.append(item)
                }
                
                DispatchQueue.main.async {
                    
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    func deleteRecord(_ item: AutorRecord) {
        
        let tableMS = client.table(withName: "Authors")
        
        tableMS.delete(item) { (reult, error) in
            
            if let _ = error {
                print(error)
                return
            }
            self.readAllItemsInTable()
        }
    }
    
    
    // Download the news saved in the table
    func getUserIdentity(){
        client.invokeAPI("getUserIdentity", body: nil, httpMethod: "GET", parameters: nil, headers: nil) { (result, respose, error) in
            
            
            if let _ = error {
                print(error)
                return
            }
            
            if !((self.userIdentity!.isEmpty)) {
                self.userIdentity?.removeAll()
            }
            
            if let _ = result {
                
                let json = result as! [AutorRecord]
                
                for item in json {
                    self.userIdentity?.append(item)
                }
                
                DispatchQueue.main.async {
                    
                    print("User udentity conseguida")
                }
            }
        }
    }

    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        if (model?.isEmpty)! && author.news.isEmpty {
            return 0
        }
        return 2
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var title : String
        if section == 0 {
            title = "Noticias publicadas"
        } else {
            title = "Noticias pendientes"
        }
        return title
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (model?.isEmpty)! && author.news.isEmpty {
            return 0
        } else {
            if !(model?.isEmpty)! && section == 0 {
                return (model?.count)!
            }
            if !author.news.isEmpty && section == 1 {
                return author.news.count
            }
        }
        
        return 0
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cellId = "News"
        var cell = tableView.dequeueReusableCell(withIdentifier: cellId)
        

        if cell == nil{
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: cellId)
        }
        
        if !(model?.isEmpty)! && indexPath.section == 0 {
            let item = model?[indexPath.row]
            cell?.textLabel?.text = item?["title"] as! String?
            cell?.detailTextLabel?.text = item?["author"] as! String?
        }

        
        if !author.news.isEmpty && indexPath.section == 1 {
            cell?.textLabel?.text = author.news[indexPath.row].title
            cell?.detailTextLabel?.text = author.name
        }
        
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            
            let item = model?[indexPath.row]
            
            let news = News(author: author,
                            title: item?["title"] as! String,
                            text: item?["text"] as! String,
                            photo: nil)
            news.id = item?["id"] as! String
            news.blobId = item?["image"] as! String
            if (item?["latitude"] as! Double) != 0.0 {
                news.latitude = item?["latitude"] as! Double
                news.longitude = item?["longitude"] as! Double
            }
            news.views = item?["views"] as! Int
            let newsDetailVC = NewsDetailViewController(author: author, news: news)
            navigationController?.pushViewController(newsDetailVC, animated: true)

        } else {
            let news = author.news[indexPath.row]
            let newsDetailVC = NewsDetailViewController(author: author, news: news)
            navigationController?.pushViewController(newsDetailVC, animated: true)
        }
        
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.beginUpdates()
            tableView.deleteRows(at: [indexPath], with: .fade)
            let item = self.model?[indexPath.row]
            
            self.deleteRecord(item!)
            self.model?.remove(at: indexPath.row)
            
            tableView.endUpdates()
            
        } else if editingStyle == .insert {

        }
    }
    

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
}

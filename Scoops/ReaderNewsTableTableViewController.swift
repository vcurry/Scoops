//
//  ReaderNewsTableTableViewController.swift
//  Scoops
//
//  Created by Verónica Cordobés on 26/10/16.
//  Copyright © 2016 Verónica Cordobés. All rights reserved.
//

import UIKit



class ReaderNewsTableTableViewController: UITableViewController {

    var client : MSClient = MSClient(applicationURL: URL(string: "https://boot3labsv.azurewebsites.net")!)

    var model : [Dictionary<String, AnyObject>]? = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        readAllItemsInTable()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        readAllItemsInTable()
        tableView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func doLoginInFacebook() {
        
        client.login(withProvider: "facebook", parameters: nil, controller: self, animated: true) { (user, error) in
            
            if let _ = error {
                print(error)
                return
            }
            
            if let _ = user {
                self.readAllItemsInTable()
            }
        }
    }

    
    
    // MARK: - Actions

    
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
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {

        return 1
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Noticias publicadas"
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (model?.count)!
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cellId = "News"
        var cell = tableView.dequeueReusableCell(withIdentifier: cellId)
        
        
        if cell == nil{
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: cellId)
        }
        
        if !(model?.isEmpty)! {
            let item = model?[indexPath.row]
            cell?.textLabel?.text = item?["title"] as! String?
            cell?.detailTextLabel?.text = item?["author"] as! String?
        }
        
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var item = model?[indexPath.row]
        let author = Author(name: item?["author"] as! String)
        let news = News(author: author,
                        title: item?["title"] as! String,
                        text: item?["text"] as! String,
                        photo: nil)
        news.id = item?["id"] as! String
        news.blobId = item?["image"] as! String
        news.views = item?["views"] as! Int + 1
        
        let tableAz = client.table(withName: "Authors")
        item!["views"] = news.views as AnyObject?
        tableAz.update(item!, completion: { (result, error) in
            if let _ = error {
                print(error)
                return
            }
            
            print(result)
            
        })
        
        let newsDetailVC = ReaderNewsDetailViewController(news: news)
        navigationController?.pushViewController(newsDetailVC, animated: true)

        
    }
    

}

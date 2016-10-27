//
//  ReaderNewsTableTableViewController.swift
//  Scoops
//
//  Created by Verónica Cordobés on 26/10/16.
//  Copyright © 2016 Verónica Cordobés. All rights reserved.
//

import UIKit



class ReaderNewsTableTableViewController: UITableViewController {

    var client : MSClient = MSClient(applicationURL: URL(string: "http://boot3labsv.azurewebsites.net")!)

    var model : [Dictionary<String, AnyObject>]? = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let _ = client.currentUser{
            readAllItemsInTable()
            print(model?.count)
        } else {
            doLoginInFacebook()
        }
        

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
            
            print("Result \(result)")
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
            //El optional está vació: hay que crearla a pelo
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: cellId)
        }
        //     let item = model?[indexPath.row]
        
        //     cell?.textLabel?.text = item?["name"] as! String?
        
        if !(model?.isEmpty)! {
            let item = model?[indexPath.row]
            cell?.textLabel?.text = item?["title"] as! String?
            cell?.detailTextLabel?.text = item?["author"] as! String?
        }
        
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = model?[indexPath.row]
        let author = Author(name: item?["author"] as! String)
        let news = News(author: author,
                        title: item?["title"] as! String,
                        text: item?["text"] as! String,
                        photo: nil)
        news.id = item?["id"] as! String
    //    let newsDetailVC = NewsDetailViewController(author: author, news: news)
      //  navigationController?.pushViewController(newsDetailVC, animated: true)

        
    }
    

}

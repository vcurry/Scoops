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
    
    var client : MSClient = MSClient(applicationURL: URL(string: "http://boot3labsv.azurewebsites.net")!)
    var model : [Dictionary<String, AnyObject>]? = []
    
    var blobClient: AZSCloudBlobClient?
    var photoContainer: AZSCloudBlobContainer?
    
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

        setupAzureClient()
        if let _ = client.currentUser{
            readAllItemsInTable()
             print(model?.count)
        } else {
            doLoginInFacebook()
        }
        
        self.newContainer("Photos")
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
        let newsDetailVC = NewsDetailViewController(author: author, news: news, container: photoContainer!)
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
            
            // refrescar la tabla
            self.readAllItemsInTable()
        }
    }
    
    func setupAzureClient(){
        do {
            let credentials = AZSStorageCredentials(accountName: "labboot3storagev",
                                                    accountKey: "6w7YXVXiqaxOmLCtptliUxpAjKUJHMn4N61HIl9zZBlVSNrLtkMsgSvXUAUqCYvjC8i8NE7kKzS1JAOXS41xtA==")
            let account = try AZSCloudStorageAccount(credentials: credentials, useHttps: true)
            
            blobClient = account.getBlobClient()
            
            self.readAllContainers()
            
        } catch let error {
            print(error)
        }
        
    }

    func readAllContainers()  {
        photoContainer = (blobClient?.containerReference(fromName: "photos"))!
//        blobClient?.listContainersSegmented(with: nil,
//                                        prefix: nil,
//                                        containerListingDetails: AZSContainerListingDetails.all,
//                                        maxResults: -1,
//                                        completionHandler: { (error, containersResults) in
//                                            
//                                            if let _ = error {
//                                                print(error)
//                                                return
//                                            }
//                                            
//                                            if !self.photoModel.isEmpty {
//                                                self.photoModel.removeAll()
//                                            }
//                                            
//                                            
//                                            for item in (containersResults?.results)! {
//                                                print(item)
//                                                self.photoModel.append((item as? AZSCloudBlobContainer)!)
//                                            }
//                                            
//                                            DispatchQueue.main.async {
//                                                self.tableView.reloadData()
//                                            }
//                                            
//                                            
//        })
        
    }
    
    func newContainer(_ name: String) {
        let blobContainer = blobClient?.containerReference(fromName: name.lowercased())
        
        blobContainer?.createContainerIfNotExists(with: AZSContainerPublicAccessType.container,
                                                  requestOptions: nil,
                                                  operationContext: nil,
                                                  completionHandler: { (error, result) in
                                                    
                                                    if let _  = error {
                                                        print(error)
                                                        return
                                                    }
                                                    if result {
                                                        print("Container creado")
                                                        self.readAllContainers()
                                                    } else {
                                                        print("Ya existe el container")
                                                    }
                                                    
        })
    }
    
    func downloadBlobFromStorage(_ theBlob: AZSCloudBlockBlob) {
        
        theBlob.downloadToData { (error, data) in
            
            if let _ = error {
                print(error)
                return
            }
            
            if let _ = data {
                var img = UIImage(data: data!)
                print("Imagen ok")
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
            //El optional está vació: hay que crearla a pelo
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: cellId)
        }
   //     let item = model?[indexPath.row]
        
   //     cell?.textLabel?.text = item?["name"] as! String?
        
        if !(model?.isEmpty)! && indexPath.section == 0 {
            let item = model?[indexPath.row]
            cell?.textLabel?.text = item?["title"] as! String?
            cell?.detailTextLabel?.text = item?["author"] as! String?
      //      cell?.imageView?.image = photoContainer?.blockBlobReference(fromName: (item?["image"] as! String?)!)
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
            let newsDetailVC = NewsDetailViewController(author: author, news: news, container: photoContainer!)
            navigationController?.pushViewController(newsDetailVC, animated: true)
//            print(item?["id"] as! String)
//            for n in author.news {
//                if n.id == item?["id"] as! String {
//                    let newsDetailVC = NewsDetailViewController(author: author, news: n)
//                    navigationController?.pushViewController(newsDetailVC, animated: true)
//                }
//            }
        } else {
            let news = author.news[indexPath.row]
            let newsDetailVC = NewsDetailViewController(author: author, news: news, container: photoContainer!)
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

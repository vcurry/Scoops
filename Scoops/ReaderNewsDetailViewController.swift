//
//  ReaderNewsDetailViewController.swift
//  Scoops
//
//  Created by Verónica Cordobés on 28/10/16.
//  Copyright © 2016 Verónica Cordobés. All rights reserved.
//

import UIKit

class ReaderNewsDetailViewController: UIViewController {
    
    
    var blobClient: AZSCloudBlobClient?
    var container: AZSCloudBlobContainer?
    var photoModel: [AZSCloudBlockBlob] = []
    var blob: AZSCloudBlockBlob?
    
    @IBOutlet weak var displayTitle: UILabel!
    @IBOutlet weak var displayText: UILabel!
    @IBOutlet weak var showImage: UIImageView!
    
    
    let news : News
    
    init(news: News){
        self.news = news
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        displayTitle.lineBreakMode = .byTruncatingTail
        displayText.lineBreakMode = .byTruncatingTail
        displayTitle.text = news.title
        displayText.text = news.text
        showImage.image = news.photo
        
        self.setupAzureClient()
        readAllBlobs()
        
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
        container = (blobClient?.containerReference(fromName: "photos"))!
        
    }
    
    func readAllBlobs()  {
        
        container?.listBlobsSegmented(with: nil,
                                      prefix: nil,
                                      useFlatBlobListing: true,
                                      blobListingDetails: AZSBlobListingDetails.all,
                                      maxResults: -1,
                                      completionHandler: { (error, results) in
                                        
                                        if let _ = error {
                                            print(error)
                                            return
                                        }
                                        
                                        if !self.photoModel.isEmpty {
                                            self.photoModel.removeAll()
                                        }
                                        
                                        for items in (results?.blobs)! {
                                            self.photoModel.append(items as! AZSCloudBlockBlob)
                                        }
                                        
                                        DispatchQueue.main.async {
                                            for b in self.photoModel{
                                                if b.blobName == self.news.blobId {
                                                    self.downloadBlobFromStorage(b, news: self.news)
                                                }
                                                
                                            }
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
                let img = UIImage(data: data!)
                self.showImage.image = img
                self.news.photo = img
            }
        }
    }
    
    func downloadBlobFromStorage(_ theBlob: AZSCloudBlockBlob, news: News) {
        
        theBlob.downloadToData { (error, data) in
            
            if let _ = error {
                print(error)
                return
            }
            
            if let _ = data {
                let img = UIImage(data: data!)
                news.photo = img
                self.showImage.image = img

            }
            
        }
        
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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

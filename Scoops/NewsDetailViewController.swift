//
//  NewsDetailViewController.swift
//  Scoops
//
//  Created by Verónica Cordobés on 23/10/16.
//  Copyright © 2016 Verónica Cordobés. All rights reserved.
//

import UIKit
import CoreLocation

class NewsDetailViewController: UIViewController, CLLocationManagerDelegate {
    var client: MSClient = MSClient(applicationURL: URL(string: "https://boot3labsv.azurewebsites.net")!)
    var model: [Dictionary<String, AnyObject>]? = []
    
    var blobClient: AZSCloudBlobClient?
    var container: AZSCloudBlobContainer?
    var photoModel: [AZSCloudBlockBlob] = []
    var blob: AZSCloudBlockBlob?
    
    let author : Author
    let news : News

    let locationManager = CLLocationManager()
    
    @IBOutlet weak var titulo: UITextView!
    @IBOutlet weak var text: UITextView!
    @IBOutlet weak var photoView: UIImageView!
    @IBOutlet weak var latLabel: UILabel!
    @IBOutlet weak var readerViews: UILabel!
    @IBOutlet weak var longLabel: UILabel!
    
    init(author: Author, news: News){
        self.author = author
        self.news = news
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    
    override func viewDidLoad() {

        super.viewDidLoad()
        if let _ = client.currentUser{

        } else {
            doLoginInFacebook()
        }
        
        self.setupAzureClient()
        self.newContainer("Photos")
        readAllBlobs()
        if (news.latitude == 0.0) {
            self.getLocation()
        } else {
            latLabel.text = "\(news.latitude)"
            longLabel.text = "\(news.longitude)"
        }
        
        readerViews.text = "\(news.views)"
        

        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(NewsDetailViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        titulo.text = news.title
        text.text = news.text
        photoView.image = news.photo

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

    
    func downloadBlobFromStorage(_ theBlob: AZSCloudBlockBlob) {
        
        theBlob.downloadToData { (error, data) in
            
            if let _ = error {
                print(error)
                return
            }
            
            if let _ = data {
                let img = UIImage(data: data!)
                self.news.photo = img
                print("Imagen ok")
            }
            
        }
        
    }
    
    func doLoginInFacebook() {
        
        client.login(withProvider: "facebook", parameters: nil, controller: self, animated: true) { (user, error) in
            
            if let _ = error {
                print(error)
                return
            }
            
            if let _ = user {
                
            }
        }
    }

    
    func dismissKeyboard(){
        view.endEditing(true)
    }


    @IBAction func createNews(_ sender: AnyObject) {
        news.title = titulo.text
        news.text = text.text
        news.photo = photoView.image
        if news.id == "" {
            news.id = UUID().uuidString
            author.news.append(news)
            
        }
        print(news.title)

        
        
    }
    
    @IBAction func uploadNews(_ sender: AnyObject) {
        news.title = titulo.text
        news.text = text.text
        news.photo = photoView.image
        if news.id == "" {
            news.id = UUID().uuidString
        }

        if (news.title == "" || news.text == "") {
            let alert = UIAlertController(title: "Campos incompletos", message: "Los campos de título y de texto de la noticia no pueden estar vacíos", preferredStyle: .alert)
            let actionOk = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alert.addAction(actionOk)
            present(alert, animated: true, completion: nil)
        } else {
            let alert = UIAlertController(title: "Uploading", message: "¿Seguro que quieres publicar la noticia?", preferredStyle: .alert)
            let actionOK = UIAlertAction(title: "OK", style: .default, handler: { (alertAction) in
                self.insertNews()
            })
            let actionCancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alert.addAction(actionOK)
            alert.addAction(actionCancel)
            present(alert, animated: true, completion: nil)
        }
    }
    
    //TODO, añadir los campos long y lat a la tabla y en el tables
    func insertNews(){
        if news.photo != nil {
            self.uploadBlob()
        }
        
        let tableMS = client.table(withName: "Authors")
        tableMS.insert(
            ["id": news.id,
             "author": author.name,
             "title" : news.title,
             "text" : news.text,
             "image": news.blobId,
             "latitude": news.latitude,
             "longitude": news.longitude,
             "views": news.views]) { (result, error) in
                if let _ = error{
                    print(error)
                    return
                }
                print(result)
        }

    }
    
    @IBAction func takePhoto(_ sender: AnyObject) {
        
        let picker = UIImagePickerController()
        
        if UIImagePickerController.isCameraDeviceAvailable(.rear){
            picker.sourceType = .camera
        }else{
            picker.sourceType = .photoLibrary
        }
        
        
        picker.delegate = self
        
        self.present(picker, animated: true) {
            
        }
        
    }
    
    func uploadBlob(){
        let blobId = UUID().uuidString
        news.blobId = blobId
        print("news blobId \(news.blobId)")
        let myBlob = container?.blockBlobReference(fromName: blobId)
        myBlob?.upload(from: UIImageJPEGRepresentation(news.photo!, 0.5)!, completionHandler: { (error) in
            
            if error != nil {
                print(error)
                return
            }
        //    self.readAllBlobs()
            
        })
    }
    
    func readAllContainers()  {
        container = (blobClient?.containerReference(fromName: "photos"))!
        
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
    
    
    func downloadBlobFromStorage(_ theBlob: AZSCloudBlockBlob, news: News) {
        
        theBlob.downloadToData { (error, data) in
            
            if let _ = error {
                print(error)
                return
            }
            
            if let _ = data {
                let img = UIImage(data: data!)
                news.photo = img
                self.photoView.image = img
            }
        }
    }
    

    
    func getLocation(){
        let status = CLLocationManager.authorizationStatus()
        self.locationManager.delegate = self
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        if(status == CLAuthorizationStatus.authorizedAlways || status == CLAuthorizationStatus.authorizedWhenInUse){
            self.locationManager.startUpdatingLocation()
    }
    
}

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.locationManager.stopUpdatingLocation()
        let loc = locations.last
        self.news.latitude = (loc?.coordinate.latitude)!
        self.news.longitude = (loc?.coordinate.longitude)!
        latLabel.text = "\(news.latitude)"
        longLabel.text = "\(news.longitude)"
        print("loc conseguida \(loc?.coordinate.latitude)")
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

//MARK: - Delegates
extension NewsDetailViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        news.photo = info[UIImagePickerControllerOriginalImage] as! UIImage?
        photoView.image = news.photo
        self.dismiss(animated: true) {
        }
    }
}

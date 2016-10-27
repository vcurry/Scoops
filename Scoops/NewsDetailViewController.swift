//
//  NewsDetailViewController.swift
//  Scoops
//
//  Created by Verónica Cordobés on 23/10/16.
//  Copyright © 2016 Verónica Cordobés. All rights reserved.
//

import UIKit

class NewsDetailViewController: UIViewController {
    var client: MSClient = MSClient(applicationURL: URL(string: "http://boot3labsv.azurewebsites.net")!)
    var model: [Dictionary<String, AnyObject>]? = []
    
    var photoClient: AZSCloudBlobClient?
    var container: AZSCloudBlobContainer
    var photoModel: [AZSCloudBlockBlob] = []
    
    let author : Author
    let news : News

    @IBOutlet weak var titulo: UITextView!
    @IBOutlet weak var text: UITextView!
    @IBOutlet weak var photoView: UIImageView!
    
    init(author: Author, news: News, container: AZSCloudBlobContainer){
        self.author = author
        self.news = news
        self.container = container
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(NewsDetailViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        titulo.text = news.title
        text.text = news.text
        photoView.image = news.photo

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
    
    func insertNews(){
        let tableMS = client.table(withName: "Authors")
        tableMS.insert(
            ["id": news.id,
             "author": author.name,
             "title" : news.title,
             "text" : news.text]) { (result, error) in
                if let _ = error{
                    print(error)
                    return
                }
                print(result)
        }
        
        if news.photo != nil {
            self.uploadBlob()
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
        let myBlob = container.blockBlobReference(fromName: UUID().uuidString)
        myBlob.upload(from: UIImageJPEGRepresentation(news.photo!, 0.5)!, completionHandler: { (error) in
            
            if error != nil {
                print(error)
                return
            }
        //    self.readAllBlobs()
            
        })
    }

    
    @IBAction func deleteNews(_ sender: AnyObject) {
        
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

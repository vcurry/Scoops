//
//  News.swift
//  Scoops
//
//  Created by Verónica Cordobés on 23/10/16.
//  Copyright © 2016 Verónica Cordobés. All rights reserved.
//

import Foundation

class News {
    let author : Author
    var title : String
    var text : String
    var photo : UIImage?
    var blobId : String
    var uploaded : Bool
    var id : String
    var latitude: Double
    var longitude: Double
    var views: Int
  
    init(author : Author, title : String, text : String, photo : UIImage?){
        self.author = author
        self.title = title
        self.text = text
        self.photo = photo
        self.uploaded = false
        self.id = ""
        self.blobId = ""
        self.latitude = 0
        self.longitude = 0
        self.views = 0
    }
}

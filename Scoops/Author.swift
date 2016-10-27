//
//  Author.swift
//  Scoops
//
//  Created by Verónica Cordobés on 23/10/16.
//  Copyright © 2016 Verónica Cordobés. All rights reserved.
//

import Foundation

class Author {
    let name : String
    var news : [News]
    
    init(name : String){
        self.name = name
        self.news = []
    }
}

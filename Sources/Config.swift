//
//  Config.swift
//  Coolie
//
//  Created by NIX on 16/11/14.
//  Copyright © 2016年 nixWork. All rights reserved.
//

import Foundation

class Config {
    class DateFormatterName {
        static var jsonLike = "jsonLikeDateFormatter"
        static var dateOnly = "dateOnlyDateFormatter"
    }
}

let jsonLikeDateFormatter: DateFormatter = {
    let formater = DateFormatter()
    formater.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"
    return formater
}()

let dateOnlyDateFormatter: DateFormatter = {
    let formater = DateFormatter()
    formater.dateFormat = "yyyy-MM-dd"
    return formater
}()

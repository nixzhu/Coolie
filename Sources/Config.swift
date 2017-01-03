//
//  Config.swift
//  Coolie
//
//  Created by NIX on 16/11/14.
//  Copyright © 2016年 nixWork. All rights reserved.
//

import Foundation

class Config {
    static var argumentLabel: String?

    class DateFormatterName {
        static var iso8601 = "iso8601DateFormatter"
        static var dateOnly = "dateOnlyDateFormatter"
    }
}

let iso8601DateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeZone = TimeZone(abbreviation: "UTC")
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"
    return formatter
}()

let dateOnlyDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
}()

func defaultDictionaryName() -> String {
    return "json"
}

func dictionaryName() -> String {
    if let argumentLabel = Config.argumentLabel {
        return argumentLabel
    } else {
        return defaultDictionaryName()
    }
}

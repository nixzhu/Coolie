//
//  Config.swift
//  Coolie
//
//  Created by NIX on 16/11/14.
//  Copyright © 2016年 nixWork. All rights reserved.
//

import Foundation

class Config {
    static var constructorName: String?
    static var jsonDictionaryName: String = "[String: Any]"
    static var argumentLabel: String?
    static var parameterName: String = "json"
    static var debug: Bool = false
    static var throwsEnabled: Bool = false

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

func parameterName() -> String {
    return Config.parameterName
}

func initArgumentLabel() -> String {
    let _argumentLabel = Config.argumentLabel ?? "_"
    let _parameterName = parameterName()
    if _argumentLabel == _parameterName {
        return _argumentLabel
    } else {
        return "\(_argumentLabel) \(_parameterName)"
    }
}

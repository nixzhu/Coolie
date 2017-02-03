//
//  Coolie+Config.swift
//  Coolie
//
//  Created by NIX on 16/11/14.
//  Copyright © 2016年 nixWork. All rights reserved.
//

import Foundation

extension Coolie {

    public class Config {
        public static var constructorName: String?
        public static var jsonDictionaryName: String = "[String: Any]"
        public static var argumentLabel: String?
        public static var parameterName: String = "json"
        public static var debug: Bool = false
        public static var throwsEnabled: Bool = false
        public static var publicEnabled: Bool = false

        public class DateFormatterName {
            public static var iso8601 = "iso8601DateFormatter"
            public static var dateOnly = "dateOnlyDateFormatter"
        }
    }
}

extension Coolie.Config {

    static let iso8601DateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"
        return formatter
    }()

    static let dateOnlyDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static func initArgumentLabel() -> String {
        let _argumentLabel = argumentLabel ?? "_"
        if _argumentLabel == parameterName {
            return _argumentLabel
        } else {
            return "\(_argumentLabel) \(parameterName)"
        }
    }

    static func publicString() -> String {
        if publicEnabled {
            return "public "
        } else {
            return ""
        }
    }
}

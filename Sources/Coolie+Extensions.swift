//
//  Coolie+Extensions.swift
//  Coolie
//
//  Created by NIX on 16/11/3.
//  Copyright © 2016年 nixWork. All rights reserved.
//

import Foundation

extension Coolie.Value {

    var type: String {
        switch self {
        case .bool:
            return "Bool"
        case .number(let number):
            switch number {
            case .int:
                return "Int"
            case .double:
                return "Double"
            }
        case .string:
            return "String"
        case .url:
            return "URL"
        case .date:
            return "Date"
        case .null(let value):
            if let value = value {
                return "\(value.type)?"
            } else {
                return "UnknownType?"
            }
        case .array(_, let values):
            if let unionValue = unionValues(values) {
                return "[\(unionValue.type)]"
            } else {
                return "UnknownType"
            }
        default:
            fatalError("No type for: \(self)")
        }
    }
}

extension Coolie.Value {

    func indent(with level: Int, into string: inout String) {
        for _ in 0..<level {
            string += "\t"
        }
    }

    enum OrdinaryPropertyType {
        case normal
        case optional
        case normalInArray
        case optionalInArray
    }

    func generateOrdinaryProperty(of _type: OrdinaryPropertyType, with key: String, level: Int, into string: inout String) {
        func normal(value: Coolie.Value) {
            if value.isHyperString {
                indent(with: level, into: &string)
                string += "let \(key.coolie_lowerCamelCase)String = \(parameterName())[\"\(key)\"] as? String\n"
                indent(with: level, into: &string)
                switch value {
                case .url:
                    string += "let \(key.coolie_lowerCamelCase) = \(key.coolie_lowerCamelCase)String.flatMap({ URL(string: $0) })\n"
                case .date(let type):
                    switch type {
                    case .iso8601:
                        string += "let \(key.coolie_lowerCamelCase) = \(key.coolie_lowerCamelCase)String.flatMap({ \(Config.DateFormatterName.iso8601).date(from: $0) })\n"
                    case .dateOnly:
                        string += "let \(key.coolie_lowerCamelCase) = \(key.coolie_lowerCamelCase)String.flatMap({ \(Config.DateFormatterName.dateOnly).date(from: $0) })\n"
                    }
                default:
                    fatalError("Unknown hyper string")
                }
            } else {
                indent(with: level, into: &string)
                let type = "\(value.type)"
                string += "let \(key.coolie_lowerCamelCase) = \(parameterName())[\"\(key)\"] as? \(type)\n"
            }
        }
        switch _type {
        case .normal:
            if case .null(let optionalValue) = self {
                if let value = optionalValue {
                    normal(value: value)
                } else {
                    indent(with: level, into: &string)
                    let type = "UnknownType"
                    string += "let \(key.coolie_lowerCamelCase) = \(parameterName())[\"\(key)\"] as? \(type)\n"
                }
            } else {
                if isHyperString {
                    indent(with: level, into: &string)
                    string += "guard let \(key.coolie_lowerCamelCase)String = \(parameterName())[\"\(key)\"] as? String else { "
                    if Config.throwsEnabled {
                        string += "throw ParseError.notFound(key: \"\(key)\") }\n"
                    } else {
                        string += Config.debug ? "print(\"Not found url key: \(key)\"); return nil }\n" : "return nil }\n"
                    }
                    indent(with: level, into: &string)
                    switch self {
                    case .url:
                        string += "guard let \(key.coolie_lowerCamelCase) = URL(string: \(key.coolie_lowerCamelCase)String) else { "
                        if Config.throwsEnabled {
                            string += "throw ParseError.failedToGenerate(property: \"\(key.coolie_lowerCamelCase)\") }\n"
                        } else {
                            string += Config.debug ? "print(\"Not generate url key: \(key)\"); return nil }\n" : "return nil }\n"
                        }
                    case .date(let type):
                        switch type {
                        case .iso8601:
                            string += "guard let \(key.coolie_lowerCamelCase) = \(Config.DateFormatterName.iso8601).date(from: \(key.coolie_lowerCamelCase)String) else { "
                            if Config.throwsEnabled {
                                string += "throw ParseError.failedToGenerate(property: \"\(key.coolie_lowerCamelCase)\") }\n"
                            } else {
                                string += Config.debug ? "print(\"Not generate date key: \(key)\"); return nil }\n" : "return nil }\n"
                            }
                        case .dateOnly:
                            string += "guard let \(key.coolie_lowerCamelCase) = \(Config.DateFormatterName.dateOnly).date(from: \(key.coolie_lowerCamelCase)String) else { "
                            if Config.throwsEnabled {
                                string += "throw ParseError.failedToGenerate(property: \"\(key.coolie_lowerCamelCase)\") }\n"
                            } else {
                                string += Config.debug ? "print(\"Not generate date key: \(key)\"); return nil }\n" : "return nil }\n"
                            }
                        }
                    default:
                        fatalError("Unknown hyper string")
                    }
                } else {
                    indent(with: level, into: &string)
                    string += "guard let \(key.coolie_lowerCamelCase) = \(parameterName())[\"\(key)\"] as? \(type) else { "
                    if Config.throwsEnabled {
                        string += "throw ParseError.notFound(key: \"\(key)\") }\n"
                    } else {
                        string += Config.debug ? "print(\"Not found key: \(key)\"); return nil }\n" : "return nil }\n"
                    }
                }
            }
        case .optional:
            normal(value: self)
        case .normalInArray:
            if isHyperString {
                indent(with: level, into: &string)
                string += "guard let \(key.coolie_lowerCamelCase)Strings = \(parameterName())[\"\(key)\"] as? [String] else { "
                if Config.throwsEnabled {
                    string += "throw ParseError.notFound(key: \"\(key)\") }\n"
                } else {
                    string += Config.debug ? "print(\"Not found url key: \(key)\"); return nil }\n" : "return nil }\n"
                }
                indent(with: level, into: &string)
                switch self {
                case .url:
                    string += "let \(key.coolie_lowerCamelCase) = \(key.coolie_lowerCamelCase)Strings.map({ URL(string: $0) }).flatMap({ $0 })\n"
                case .date(let type):
                    switch type {
                    case .iso8601:
                        string += "let \(key.coolie_lowerCamelCase) = \(key.coolie_lowerCamelCase)Strings.map({ \(Config.DateFormatterName.iso8601).date(from: $0) }).flatMap({ $0 })\n"
                    case .dateOnly:
                        string += "let \(key.coolie_lowerCamelCase) = \(key.coolie_lowerCamelCase)Strings.map({ \(Config.DateFormatterName.dateOnly).date(from: $0) }).flatMap({ $0 })\n"
                    }
                default:
                    fatalError("Unknown hyper string")
                }
            } else {
                indent(with: level, into: &string)
                string += "guard let \(key.coolie_lowerCamelCase) = \(parameterName())[\"\(key)\"] as? [\(type)] else { "
                if Config.throwsEnabled {
                    string += "throw ParseError.notFound(key: \"\(key)\") }\n"
                } else {
                    string += Config.debug ? "print(\"Not found key: \(key)\"); return nil }\n" : "return nil }\n"
                }
            }
        case .optionalInArray:
            if isHyperString {
                indent(with: level, into: &string)
                string += "guard let \(key.coolie_lowerCamelCase)Strings = \(parameterName())[\"\(key)\"] as? [String?] else { "
                if Config.throwsEnabled {
                    string += "throw ParseError.notFound(key: \"\(key)\") }\n"
                } else {
                    string += Config.debug ? "print(\"Not found url key: \(key)\"); return nil }\n" : "return nil }\n"
                }
                indent(with: level, into: &string)
                switch self {
                case .url:
                    string += "let \(key.coolie_lowerCamelCase) = \(key.coolie_lowerCamelCase)Strings.map({ $0.flatMap({ URL(string: $0) }) })\n"
                case .date(let type):
                    switch type {
                    case .iso8601:
                        string += "let \(key.coolie_lowerCamelCase) = \(key.coolie_lowerCamelCase)Strings.map({ $0.flatMap({ \(Config.DateFormatterName.iso8601).date(from: $0) }) })\n"
                    case .dateOnly:
                        string += "let \(key.coolie_lowerCamelCase) = \(key.coolie_lowerCamelCase)Strings.map({ $0.flatMap({ \(Config.DateFormatterName.dateOnly).date(from: $0) }) })\n"
                    }
                default:
                    fatalError("Unknown hyper string")
                }
            } else {
                indent(with: level, into: &string)
                string += "guard let \(key.coolie_lowerCamelCase) = \(parameterName())[\"\(key)\"] as? [\(type)?] else { "
                if Config.throwsEnabled {
                    string += "throw ParseError.failedToGenerate(property: \"\(key.coolie_lowerCamelCase)\") }\n"
                } else {
                    string += Config.debug ? "print(\"Not generate array key: \(key)\"); return nil }\n" : "return nil }\n"
                }
            }
        }
    }
}

extension Coolie.Value {

    var isDictionaryOrArray: Bool {
        switch self {
        case .dictionary:
            return true
        case .array:
            return true
        default:
            return false
        }
    }

    var isDictionary: Bool {
        switch self {
        case .dictionary:
            return true
        default:
            return false
        }
    }

    var isArray: Bool {
        switch self {
        case .array:
            return true
        default:
            return false
        }
    }

    var isHyperString: Bool {
        switch self {
        case .url:
            return true
        case .date:
            return true
        default:
            return false
        }
    }

    var isNull: Bool {
        switch self {
        case .null:
            return true
        default:
            return false
        }
    }
}

extension String {

    var dateType: Coolie.Value.DateType? {
        if iso8601DateFormatter.date(from: self) != nil {
            return .iso8601
        }
        if dateOnlyDateFormatter.date(from: self) != nil {
            return .dateOnly
        }
        return nil
    }
}

extension Coolie.Value {

    var upgraded: Coolie.Value {
        switch self {
        case .bool, .number, .url, .date, .null:
            return self
        case .string(let string):
            if let url = URL(string: string), url.host != nil {
                return .url(url)
            }
            if let dateType = string.dateType {
                return .date(dateType)
            }
            return self
        case .dictionary(let info):
            var newInfo: [String: Coolie.Value] = [:]
            for key in info.keys {
                let value = info[key]!
                newInfo[key] = value.upgraded
            }
            return .dictionary(newInfo)
        case .array(let name, let values):
            let newValues = values.map({ $0.upgraded })
            return .array(name: name, values: newValues)
        }
    }
}

extension Coolie.Value {

    private func union(_ otherValue: Coolie.Value) -> Coolie.Value {
        switch (self, otherValue) {
        case (.null(let aOptionalValue), .null(let bOptionalValue)):
            switch (aOptionalValue, bOptionalValue) {
            case (.some(let a), .some(let b)):
                return .null(a.union(b))
            case (.some(let a), .none):
                return .null(a)
            case (.none, .some(let b)):
                return .null(b)
            case (.none, .none):
                return .null(nil)
            }
        case (.null(let value), let bValue):
            if let aValue = value {
                return .null(.some(aValue.union(bValue)))
            } else {
                return .null(.some(bValue))
            }
        case (let aValue, .null(let value)):
            if let bValue = value {
                return .null(.some(bValue.union(aValue)))
            } else {
                return .null(.some(aValue))
            }
        case (.bool, .bool):
            return .bool(true)
        case (.number(let aNumber), .number(let bNumber)):
            switch (aNumber, bNumber) {
            case (.int, .int):
                return .number(.int(1))
            default:
                return .number(.double(1.0))
            }
        case (.string(let s1), .string(let s2)):
            let string = s1.isEmpty ? s2 : s1
            return .string(string)
        case (.url(let u1), .url(let u2)):
            let url = u1.host == nil ? u2 : u1
            return .url(url)
        case (.date(let d1), .date):
            return .date(d1)
        case (.dictionary(let aInfo), .dictionary(let bInfo)):
            var info = aInfo
            for key in aInfo.keys {
                let aValue = aInfo[key]!
                if let bValue = bInfo[key] {
                    info[key] = aValue.union(bValue)
                } else {
                    info[key] = .null(aValue)
                }
            }
            for key in bInfo.keys {
                let bValue = bInfo[key]!
                if let aValue = aInfo[key] {
                    info[key] = bValue.union(aValue)
                } else {
                    info[key] = .null(bValue)
                }
            }
            return .dictionary(info)
        case (let .array(aName, aValues), let .array(bName, bValues)):
            let values = (aValues + bValues)
            if let first = values.first {
                let value = values.dropFirst().reduce(first, { $0.union($1) })
                return .array(name: aName ?? bName, values: [value])
            } else {
                return .array(name: aName ?? bName, values: [])
            }
        default:
            fatalError("Unsupported union!")
        }
    }

    func unionValues(_ values: [Coolie.Value]) -> Coolie.Value? {
        if let first = values.first {
            return values.dropFirst().reduce(first, { $0.union($1) })
        } else {
            return .dictionary([:])
        }
    }
}

extension String {

    var coolie_dropLastCharacter: String {
        if characters.count > 0 {
            return String(characters.dropLast())
        }
        return self
    }

    var coolie_lowerCamelCase: String {
        var symbolSet = CharacterSet.alphanumerics
        symbolSet.formUnion(CharacterSet(charactersIn: "_"))
        symbolSet.invert()
        let validString = self.components(separatedBy: symbolSet).joined(separator: "_")
        let parts = validString.components(separatedBy: "_")
        return parts.enumerated().map({ index, part in
            return index == 0 ? part : part.capitalized
        }).joined(separator: "")
    }
}

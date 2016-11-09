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
        case .null(let value):
            if let value = value {
                return "\(value.type)?"
            } else {
                return "UnknownType?"
            }
        default:
            fatalError("no type for: \(self)")
        }
    }
}

extension Coolie.Value {

    private func indent(with level: Int, into string: inout String) {
        for _ in 0..<level {
            string += "\t"
        }
    }

    func generateOrdinaryProperty(with key: String, debug: Bool, level: Int, into string: inout String) {
        if case .null(let optionalValue) = self {
            indent(with: level, into: &string)
            let type: String
            if let value = optionalValue {
                type = "\(value.type)"
            } else {
                type = "UnknownType"
            }
            string += "let \(key.coolie_lowerCamelCase) = info[\"\(key)\"] as? \(type)\n"
        } else {
            if isHyperString {
                indent(with: level, into: &string)
                string += "guard let \(key.coolie_lowerCamelCase)String = info[\"\(key)\"] as? String else { "
                string += debug ? "print(\"Not found url key: \(key)\"); return nil }\n" : "return nil }\n"
                indent(with: level, into: &string)
                string += "guard let \(key.coolie_lowerCamelCase) = URL(string: \(key.coolie_lowerCamelCase)String) else { "
                string += debug ? "print(\"Not generate url key: \(key)\"); return nil }\n" : "return nil }\n"
            } else {
                indent(with: level, into: &string)
                string += "guard let \(key.coolie_lowerCamelCase) = info[\"\(key)\"] as? \(type) else { "
                string += debug ? "print(\"Not found key: \(key)\"); return nil }\n" : "return nil }\n"
            }
        }
    }

    func generateDictionaryProperty(with key: String, jsonDictionaryName: String, constructorName: String?, trueArgumentLabel: String, debug: Bool, level: Int, into string: inout String) {
        indent(with: level, into: &string)
        string += "guard let \(key.coolie_lowerCamelCase)JSONDictionary = info[\"\(key)\"] as? \(jsonDictionaryName) else { "
        string += debug ? "print(\"Not found dictionary key: \(key)\"); return nil }\n" : "return nil }\n"
        indent(with: level, into: &string)
        if let constructorName = constructorName {
            string += "guard let \(key.coolie_lowerCamelCase) = \(key.capitalized).\(constructorName)(\(trueArgumentLabel)\(key.coolie_lowerCamelCase)JSONDictionary) else { "
        } else {
            string += "guard let \(key.coolie_lowerCamelCase) = \(key.capitalized)(\(trueArgumentLabel)\(key.coolie_lowerCamelCase)JSONDictionary) else { "
        }
        string += debug ? "print(\"Failed to generate: \(key.coolie_lowerCamelCase)\"); return nil }\n" : "return nil }\n"
    }

    func generateArrayProperty(with key: String, jsonDictionaryName: String, constructorName: String?, trueArgumentLabel: String, debug: Bool, level: Int, into string: inout String) {
        guard case .array(_, let values) = self else { fatalError("value is not array") }
        if let unionValue = unionValues(values) {
            if case .null(let optionalValue) = unionValue {
                if let value = optionalValue {
                    if value.isDictionary {
                        indent(with: level, into: &string)
                        string += "guard let \(key.coolie_lowerCamelCase)JSONArray = info[\"\(key)\"] as? [\(jsonDictionaryName)?] else { "
                        string += debug ? "print(\"Not found array key: \(key)\"); return nil }\n" : "return nil }\n"
                        indent(with: level, into: &string)
                        if let constructorName = constructorName {
                            string += "let \(key.coolie_lowerCamelCase) = \(key.coolie_lowerCamelCase)JSONArray.map({ $0.flatMap({ \(key.capitalized.coolie_dropLastCharacter).\(constructorName)(\(trueArgumentLabel)$0) }) })\n"
                        } else {
                            string += "let \(key.coolie_lowerCamelCase) = \(key.coolie_lowerCamelCase)JSONArray.map({ $0.flatMap({ \(key.capitalized.coolie_dropLastCharacter)(\(trueArgumentLabel)$0) }) })\n"
                        }
                    } else {
                        value.generateOrdinaryProperty(with: key, debug: debug, level: level, into: &string)
                    }
                } else {
                    indent(with: level, into: &string)
                    let type = "UnknownType"
                    string += "let \(key.coolie_lowerCamelCase) = info[\"\(key)\"] as? \(type)\n"
                }
            } else {
                if unionValue.isDictionary {
                    indent(with: level, into: &string)
                    string += "guard let \(key.coolie_lowerCamelCase)JSONArray = info[\"\(key)\"] as? [\(jsonDictionaryName)] else { "
                    string += debug ? "print(\"Not found array key: \(key)\"); return nil }\n" : "return nil }\n"
                    indent(with: level, into: &string)
                    if let constructorName = constructorName {
                        string += "let \(key.coolie_lowerCamelCase) = \(key.coolie_lowerCamelCase)JSONArray.map({ \(key.capitalized.coolie_dropLastCharacter).\(constructorName)(\(trueArgumentLabel)$0) }).flatMap({ $0 })\n"
                    } else {
                        string += "let \(key.coolie_lowerCamelCase) = \(key.coolie_lowerCamelCase)JSONArray.map({ \(key.capitalized.coolie_dropLastCharacter)(\(trueArgumentLabel)$0) }).flatMap({ $0 })\n"
                    }
                } else {
                    unionValue.generateOrdinaryProperty(with: key, debug: debug, level: level, into: &string)
                }
            }
        } else { // no union value
            // do nothing
        }
    }

    func generateProperty(with key: String, jsonDictionaryName: String, constructorName: String?, trueArgumentLabel: String, debug: Bool, level: Int, into string: inout String) {
        if isDictionaryOrArray {
            if isDictionary {
                generateDictionaryProperty(with: key, jsonDictionaryName: jsonDictionaryName, constructorName: constructorName, trueArgumentLabel: trueArgumentLabel, debug: debug, level: level + 2, into: &string)
            } else if isArray {
                generateArrayProperty(with: key, jsonDictionaryName: jsonDictionaryName, constructorName: constructorName, trueArgumentLabel: trueArgumentLabel, debug: debug, level: level + 2, into: &string)
            }
        } else {
            generateOrdinaryProperty(with: key, debug: debug, level: level + 2, into: &string)
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
            if let url = URL(string: s1), url.host != nil {
                return .url(url)
            } else if let url = URL(string: s2), url.host != nil {
                return .url(url)
            } else {
                let string = s1.isEmpty ? s2 : s1
                return .string(string)
            }
        case (.dictionary(let aInfo), .dictionary(let bInfo)):
            var info = aInfo
            for key in aInfo.keys {
                guard let aValue = aInfo[key] else { fatalError() }
                if let bValue = bInfo[key] {
                    info[key] = aValue.union(bValue)
                } else {
                    info[key] = .null(aValue)
                }
            }
            for key in bInfo.keys {
                guard let bValue = bInfo[key] else { fatalError() }
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
            return nil
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

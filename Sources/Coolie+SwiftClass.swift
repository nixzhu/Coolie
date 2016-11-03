//
//  Coolie+SwiftClass.swift
//  Coolie
//
//  Created by NIX on 16/11/3.
//  Copyright © 2016年 nixWork. All rights reserved.
//

import Foundation

extension Coolie.Value {

    func generateClass(fromLevel level: Int, withModelName modelName: String? = nil, argumentLabel: String? = nil, jsonDictionaryName: String? = nil, debug: Bool, into string: inout String) {

        func indentLevel(_ level: Int) {
            for _ in 0..<level {
                string += "\t"
            }
        }

        let jsonDictionaryName = jsonDictionaryName ?? "[String: Any]"

        switch self {
        case .bool, .number, .string, .null:
            string += "\(type)\n"
        case .dictionary(let info):
            // struct name
            indentLevel(level)
            string += "class \(modelName ?? "Model") {\n"
            // properties
            for key in info.keys.sorted() {
                if let value = info[key] {
                    if value.isDictionaryOrArray {
                        value.generateClass(fromLevel: level + 1, withModelName: key.capitalized, argumentLabel: argumentLabel, jsonDictionaryName: jsonDictionaryName, debug: debug, into: &string)
                        indentLevel(level + 1)
                        if value.isArray {
                            if case .array(_, let values) = value, let unionValue = unionValues(values), !unionValue.isDictionaryOrArray {
                                string += "var \(key.coolie_lowerCamelCase): [\(unionValue.type)]\n"
                            } else {
                                string += "var \(key.coolie_lowerCamelCase): [\(key.capitalized.coolie_dropLastCharacter)]\n"
                            }
                        } else {
                            string += "var \(key.coolie_lowerCamelCase): \(key.capitalized)\n"
                        }
                    } else {
                        indentLevel(level + 1)
                        string += "var \(key.coolie_lowerCamelCase): "
                        value.generateClass(fromLevel: level, argumentLabel: argumentLabel, jsonDictionaryName: jsonDictionaryName, debug: debug, into: &string)
                    }
                }
            }
            // generate method
            indentLevel(level + 1)
            let initArgumentLabel = argumentLabel ?? "_"
            string += "init?(\(initArgumentLabel) info: \(jsonDictionaryName)) {\n"
            let trueArgumentLabel = argumentLabel.flatMap({ "\($0): " }) ?? ""
            for key in info.keys.sorted() {
                if let value = info[key] {
                    if value.isDictionaryOrArray {
                        if value.isDictionary {
                            indentLevel(level + 2)
                            string += "guard let \(key.coolie_lowerCamelCase)JSONDictionary = info[\"\(key)\"] as? \(jsonDictionaryName) else { "
                            string += debug ? "print(\"Not found dictionary: \(key)\"); return nil }\n" : "return nil }\n"
                            indentLevel(level + 2)
                            string += "guard let \(key.coolie_lowerCamelCase) = \(key.capitalized)(\(trueArgumentLabel)\(key.coolie_lowerCamelCase)JSONDictionary) else { "
                            string += debug ? "print(\"Failed to generate: \(key.coolie_lowerCamelCase)\"); return nil }\n" : "return nil }\n"
                        } else if value.isArray {
                            if case .array(_, let values) = value, let unionValue = unionValues(values), !unionValue.isDictionaryOrArray {
                                indentLevel(level + 2)
                                if case .null(let optionalValue) = value {
                                    let type: String
                                    if let value = optionalValue {
                                        type = "\(value.type)"
                                    } else {
                                        type = "UnknownType"
                                    }
                                    string += "let \(key.coolie_lowerCamelCase) = info[\"\(key)\"] as? \(type)\n"
                                } else {
                                    string += "guard let \(key.coolie_lowerCamelCase) = info[\"\(key)\"] as? [\(unionValue.type)] else { "
                                    string += debug ? "print(\"Not found array key: \(key)\"); return nil }\n" : "return nil }\n"
                                }
                            } else {
                                indentLevel(level + 2)
                                string += "guard let \(key.coolie_lowerCamelCase)JSONArray = info[\"\(key)\"] as? [\(jsonDictionaryName)] else { "
                                string += debug ? "print(\"Not found array key: \(key)\"); return nil }\n" : "return nil }\n"
                                indentLevel(level + 2)
                                string += "let \(key.coolie_lowerCamelCase) = \(key.coolie_lowerCamelCase)JSONArray.map({ \(key.capitalized.coolie_dropLastCharacter)(\(trueArgumentLabel)$0) }).flatMap({ $0 })\n"
                            }
                        }
                    } else {
                        indentLevel(level + 2)
                        if case .null(let optionalValue) = value {
                            let type: String
                            if let value = optionalValue {
                                type = "\(value.type)"
                            } else {
                                type = "UnknownType"
                            }
                            string += "let \(key.coolie_lowerCamelCase) = info[\"\(key)\"] as? \(type)\n"
                        } else {
                            string += "guard let \(key.coolie_lowerCamelCase) = info[\"\(key)\"] as? \(value.type) else { "
                            string += debug ? "print(\"Not found key: \(key)\"); return nil }\n" : "return nil }\n"
                        }
                    }
                }
            }
            for key in info.keys.sorted() {
                indentLevel(level + 2)
                let property = key.coolie_lowerCamelCase
                string += "self.\(property) = \(property)\n"
            }
            indentLevel(level + 1)
            string += "}\n"
            indentLevel(level)
            string += "}\n"
        case .array(let name, let values):
            if let unionValue = unionValues(values) {
                if unionValue.isDictionaryOrArray {
                    unionValue.generateClass(fromLevel: level, withModelName: name?.coolie_dropLastCharacter, argumentLabel: argumentLabel, jsonDictionaryName: jsonDictionaryName, debug: debug, into: &string)
                }
            }
        }
    }
}

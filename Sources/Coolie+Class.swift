//
//  Coolie+Class.swift
//  Coolie
//
//  Created by NIX on 16/11/3.
//  Copyright © 2016年 nixWork. All rights reserved.
//

import Foundation

extension Coolie.Value {

    func generateClass(fromLevel level: Int = 0, modelName: String? = nil, argumentLabel: String? = nil, jsonDictionaryName: String? = nil, debug: Bool, into string: inout String) {
        let jsonDictionaryName = jsonDictionaryName ?? "[String: Any]"
        switch self {
        case .bool, .number, .string, .url, .null:
            break
        case .dictionary(let info):
            // struct name
            indent(with: level, into: &string)
            string += "class \(modelName ?? "Model") {\n"
            // properties
            for key in info.keys.sorted() {
                if let value = info[key] {
                    if value.isDictionaryOrArray {
                        value.generateClass(fromLevel: level + 1, modelName: key.capitalized, argumentLabel: argumentLabel, jsonDictionaryName: jsonDictionaryName, debug: debug, into: &string)
                        indent(with: level + 1, into: &string)
                        if value.isArray {
                            if case .array(_, let values) = value, let unionValue = unionValues(values) {
                                if case .null(let optionalValue) = unionValue {
                                    if let _value = optionalValue {
                                        if _value.isDictionary {
                                            string += "var \(key.coolie_lowerCamelCase): [\(key.capitalized.coolie_dropLastCharacter)?]\n"
                                        } else {
                                            string += "var \(key.coolie_lowerCamelCase): [\(_value.type)?]\n"
                                        }
                                    } else {
                                        string += "var \(key.coolie_lowerCamelCase): [UnknowType?]\n"
                                    }
                                } else {
                                    if unionValue.isDictionary {
                                        string += "var \(key.coolie_lowerCamelCase): [\(key.capitalized.coolie_dropLastCharacter)]\n"
                                    } else {
                                        string += "var \(key.coolie_lowerCamelCase): [\(unionValue.type)]\n"
                                    }
                                }
                            } else {
                                string += "var \(key.coolie_lowerCamelCase): [\(key.capitalized.coolie_dropLastCharacter)]\n"
                            }
                        } else {
                            string += "var \(key.coolie_lowerCamelCase): \(key.capitalized)\n"
                        }
                    } else {
                        indent(with: level + 1, into: &string)
                        string += "var \(key.coolie_lowerCamelCase): \(value.type)\n"
                    }
                }
            }
            // generate method
            indent(with: level + 1, into: &string)
            let initArgumentLabel = argumentLabel ?? "_"
            string += "init?(\(initArgumentLabel) info: \(jsonDictionaryName)) {\n"
            let trueArgumentLabel = argumentLabel.flatMap({ "\($0): " }) ?? ""
            for key in info.keys.sorted() {
                if let value = info[key] {
                    if value.isDictionaryOrArray {
                        if value.isDictionary {
                            indent(with: level + 2, into: &string)
                            string += "guard let \(key.coolie_lowerCamelCase)JSONDictionary = info[\"\(key)\"] as? \(jsonDictionaryName) else { "
                            string += debug ? "print(\"Not found dictionary: \(key)\"); return nil }\n" : "return nil }\n"
                            indent(with: level + 2, into: &string)
                            string += "guard let \(key.coolie_lowerCamelCase) = \(key.capitalized)(\(trueArgumentLabel)\(key.coolie_lowerCamelCase)JSONDictionary) else { "
                            string += debug ? "print(\"Failed to generate: \(key.coolie_lowerCamelCase)\"); return nil }\n" : "return nil }\n"
                        } else if value.isArray {
                            if case .array(_, let values) = value, let unionValue = unionValues(values) {
                                if case .null(let optionalValue) = unionValue {
                                    if let value = optionalValue {
                                        if value.isDictionary {
                                            indent(with: level + 2, into: &string)
                                            string += "guard let \(key.coolie_lowerCamelCase)JSONArray = info[\"\(key)\"] as? [\(jsonDictionaryName)?] else { "
                                            string += debug ? "print(\"Not found array key: \(key)\"); return nil }\n" : "return nil }\n"
                                            indent(with: level + 2, into: &string)
                                            string += "let \(key.coolie_lowerCamelCase) = \(key.coolie_lowerCamelCase)JSONArray.map({ $0.flatMap({ \(key.capitalized.coolie_dropLastCharacter)(\(trueArgumentLabel)$0) }) })\n"
                                        } else {
                                            indent(with: level + 2, into: &string)
                                            string += "guard let \(key.coolie_lowerCamelCase) = info[\"\(key)\"] as? [\(value.type)?] else { "
                                            string += debug ? "print(\"Not found array key: \(key)\"); return nil }\n" : "return nil }\n"
                                        }
                                    } else {
                                        indent(with: level + 2, into: &string)
                                        let type = "UnknownType"
                                        string += "let \(key.coolie_lowerCamelCase) = info[\"\(key)\"] as? \(type)\n"
                                    }
                                } else {
                                    if unionValue.isDictionary {
                                        indent(with: level + 2, into: &string)
                                        string += "guard let \(key.coolie_lowerCamelCase)JSONArray = info[\"\(key)\"] as? [\(jsonDictionaryName)] else { "
                                        string += debug ? "print(\"Not found array key: \(key)\"); return nil }\n" : "return nil }\n"
                                        indent(with: level + 2, into: &string)
                                        string += "let \(key.coolie_lowerCamelCase) = \(key.coolie_lowerCamelCase)JSONArray.map({ \(key.capitalized.coolie_dropLastCharacter)(\(trueArgumentLabel)$0) }).flatMap({ $0 })\n"
                                    } else {
                                        indent(with: level + 2, into: &string)
                                        string += "guard let \(key.coolie_lowerCamelCase) = info[\"\(key)\"] as? [\(unionValue.type)] else { "
                                        string += debug ? "print(\"Not found array key: \(key)\"); return nil }\n" : "return nil }\n"
                                    }
                                }
                            } else {
                                indent(with: level + 2, into: &string)
                                string += "guard let \(key.coolie_lowerCamelCase)JSONArray = info[\"\(key)\"] as? [\(jsonDictionaryName)] else { "
                                string += debug ? "print(\"Not found array key: \(key)\"); return nil }\n" : "return nil }\n"
                                indent(with: level + 2, into: &string)
                                string += "let \(key.coolie_lowerCamelCase) = \(key.coolie_lowerCamelCase)JSONArray.map({ \(key.capitalized.coolie_dropLastCharacter)(\(trueArgumentLabel)$0) }).flatMap({ $0 })\n"
                            }
                        }
                    } else {
                        indent(with: level + 2, into: &string)
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
                indent(with: level + 2, into: &string)
                let property = key.coolie_lowerCamelCase
                string += "self.\(property) = \(property)\n"
            }
            indent(with: level + 1, into: &string)
            string += "}\n"
            indent(with: level, into: &string)
            string += "}\n"
        case .array(let name, let values):
            if let unionValue = unionValues(values) {
                if case .null(let optionalValue) = unionValue {
                    if var value = optionalValue {
                        if case .dictionary(let info) = value {
                            value = .dictionary(info)
                            value.generateClass(fromLevel: level, modelName: name?.coolie_dropLastCharacter, argumentLabel: argumentLabel, jsonDictionaryName: jsonDictionaryName, debug: debug, into: &string)
                        }
                    } else {
                        fatalError("empty array")
                    }
                } else {
                    if unionValue.isDictionaryOrArray {
                        unionValue.generateClass(fromLevel: level, modelName: name?.coolie_dropLastCharacter, argumentLabel: argumentLabel, jsonDictionaryName: jsonDictionaryName, debug: debug, into: &string)
                    }
                }
            }
        }
    }
}

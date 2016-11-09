//
//  Coolie+Struct.swift
//  Coolie
//
//  Created by NIX on 16/11/3.
//  Copyright © 2016年 nixWork. All rights reserved.
//

import Foundation

extension Coolie.Value {

    func generateStruct(fromLevel level: Int = 0, modelName: String? = nil, argumentLabel: String? = nil, constructorName: String? = nil, jsonDictionaryName: String? = nil, debug: Bool, into string: inout String) {
        func indentLevel(_ level: Int) {
            for _ in 0..<level {
                string += "\t"
            }
        }
        let jsonDictionaryName = jsonDictionaryName ?? "[String: Any]"
        switch self {
        case .bool, .number, .string, .url, .null:
            break
        case .dictionary(let info):
            // struct name
            indentLevel(level)
            string += "struct \(modelName ?? "Model") {\n"
            // properties
            for key in info.keys.sorted() {
                let value = info[key]!
                if value.isDictionaryOrArray {
                    value.generateStruct(fromLevel: level + 1, modelName: key.capitalized, argumentLabel: argumentLabel, constructorName: constructorName, jsonDictionaryName: jsonDictionaryName, debug: debug, into: &string)
                    indentLevel(level + 1)
                    if value.isArray {
                        if case .array(_, let values) = value, let unionValue = unionValues(values) {
                            if case .null(let optionalValue) = unionValue {
                                if let _value = optionalValue {
                                    if _value.isDictionary {
                                        string += "let \(key.coolie_lowerCamelCase): [\(key.capitalized.coolie_dropLastCharacter)?]\n"
                                    } else {
                                        string += "let \(key.coolie_lowerCamelCase): [\(_value.type)?]\n"
                                    }
                                } else {
                                    string += "let \(key.coolie_lowerCamelCase): [UnknowType?]\n"
                                }
                            } else {
                                if unionValue.isDictionary {
                                    string += "let \(key.coolie_lowerCamelCase): [\(key.capitalized.coolie_dropLastCharacter)]\n"
                                } else {
                                    string += "let \(key.coolie_lowerCamelCase): [\(unionValue.type)]\n"
                                }
                            }
                        } else {
                            string += "let \(key.coolie_lowerCamelCase): [\(key.capitalized.coolie_dropLastCharacter)]\n"
                        }
                    } else {
                        string += "let \(key.coolie_lowerCamelCase): \(key.capitalized)\n"
                    }
                } else {
                    indentLevel(level + 1)
                    string += "let \(key.coolie_lowerCamelCase): \(value.type)\n"
                }
            }
            // generate method
            indentLevel(level + 1)
            let initArgumentLabel = argumentLabel ?? "_"
            if let constructorName = constructorName {
                string += "static func \(constructorName)(\(initArgumentLabel) info: \(jsonDictionaryName)) -> \(modelName ?? "Model")? {\n"
            } else {
                string += "init?(\(initArgumentLabel) info: \(jsonDictionaryName)) {\n"
            }
            let trueArgumentLabel = argumentLabel.flatMap({ "\($0): " }) ?? ""
            for key in info.keys.sorted() {
                let value = info[key]
                value?.generateProperty(with: key, jsonDictionaryName: jsonDictionaryName, constructorName: constructorName, trueArgumentLabel: trueArgumentLabel, debug: debug, level: level, into: &string)
            }
            if let _ = constructorName {
                indentLevel(level + 2)
                string += "return \(modelName ?? "Model")("
                let lastIndex = info.keys.count - 1
                for (index, key) in info.keys.sorted().enumerated() {
                    let suffix = (index == lastIndex) ? ")" : ", "
                    string += "\(key.coolie_lowerCamelCase): \(key.coolie_lowerCamelCase)" + suffix
                }
                string += "\n"
            } else {
                for key in info.keys.sorted() {
                    indentLevel(level + 2)
                    let property = key.coolie_lowerCamelCase
                    string += "self.\(property) = \(property)\n"
                }
            }
            indentLevel(level + 1)
            string += "}\n"
            indentLevel(level)
            string += "}\n"
        case .array(let name, let values):
            if let unionValue = unionValues(values) {
                if case .null(let optionalValue) = unionValue {
                    if var value = optionalValue {
                        if case .dictionary(let info) = value {
                            value = .dictionary(info)
                            value.generateStruct(fromLevel: level, modelName: name?.coolie_dropLastCharacter, argumentLabel: argumentLabel, constructorName: constructorName, jsonDictionaryName: jsonDictionaryName, debug: debug, into: &string)
                        }
                    } else {
                        fatalError("empty array")
                    }
                } else {
                    if unionValue.isDictionaryOrArray {
                        unionValue.generateStruct(fromLevel: level, modelName: name?.coolie_dropLastCharacter, argumentLabel: argumentLabel, constructorName: constructorName, jsonDictionaryName: jsonDictionaryName, debug: debug, into: &string)
                    }
                }
            }
        }
    }
}

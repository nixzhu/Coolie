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
        let jsonDictionaryName = jsonDictionaryName ?? "[String: Any]"
        switch self {
        case .bool, .number, .string, .url, .date, .null:
            break
        case .dictionary(let info):
            // struct name
            indent(with: level, into: &string)
            string += "struct \(modelName ?? "Model") {\n"
            // properties
            for key in info.keys.sorted() {
                let value = info[key]
                value?.declareStructProperty(for: key, jsonDictionaryName: jsonDictionaryName, constructorName: constructorName, argumentLabel: argumentLabel, debug: debug, level: level + 1, into: &string)
            }
            // generate method
            indent(with: level + 1, into: &string)

            let initArgumentLabel: String
            if let argumentLabel = argumentLabel {
                initArgumentLabel = argumentLabel
            } else {
                initArgumentLabel = "_ \(defaultDictionaryName())"
            }
            if let constructorName = constructorName {
                string += "static func \(constructorName)(\(initArgumentLabel): \(jsonDictionaryName)) -> \(modelName ?? "Model")? {\n"
            } else {
                string += "init?(\(initArgumentLabel): \(jsonDictionaryName)) {\n"
            }
            let trueArgumentLabel = argumentLabel.flatMap({ "\($0): " }) ?? ""
            for key in info.keys.sorted() {
                let value = info[key]
                value?.generateStructProperty(with: key, jsonDictionaryName: jsonDictionaryName, constructorName: constructorName, trueArgumentLabel: trueArgumentLabel, debug: debug, level: level, into: &string)
            }
            if let _ = constructorName {
                indent(with: level + 2, into: &string)
                string += "return \(modelName ?? "Model")("
                let lastIndex = info.keys.count - 1
                if info.keys.isEmpty {
                    string += ")"
                } else {
                    for (index, key) in info.keys.sorted().enumerated() {
                        let suffix = (index == lastIndex) ? ")" : ", "
                        string += "\(key.coolie_lowerCamelCase): \(key.coolie_lowerCamelCase)" + suffix
                    }
                }
                string += "\n"
            } else {
                for key in info.keys.sorted() {
                    indent(with: level + 2, into: &string)
                    let property = key.coolie_lowerCamelCase
                    string += "self.\(property) = \(property)\n"
                }
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
                            value.generateStruct(fromLevel: level, modelName: name?.coolie_dropLastCharacter, argumentLabel: argumentLabel, constructorName: constructorName, jsonDictionaryName: jsonDictionaryName, debug: debug, into: &string)
                        }
                    } else {
                        fatalError("Empty array")
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

extension Coolie.Value {

    func declareStructProperty(for key: String, jsonDictionaryName: String, constructorName: String?, argumentLabel: String?, debug: Bool, level: Int, into string: inout String) {
        if isDictionaryOrArray {
            generateStruct(fromLevel: level, modelName: key.capitalized, argumentLabel: argumentLabel, constructorName: constructorName, jsonDictionaryName: jsonDictionaryName, debug: debug, into: &string)
            indent(with: level, into: &string)
            if isArray {
                if case .array(_, let values) = self, let unionValue = unionValues(values) {
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
            indent(with: level, into: &string)
            string += "let \(key.coolie_lowerCamelCase): \(type)\n"
        }
    }
}

extension Coolie.Value {

    func generateStructProperty(with key: String, jsonDictionaryName: String, constructorName: String?, trueArgumentLabel: String, debug: Bool, level: Int, into string: inout String) {
        if isDictionaryOrArray {
            if isDictionary {
                generateStructDictionaryProperty(with: key, jsonDictionaryName: jsonDictionaryName, constructorName: constructorName, trueArgumentLabel: trueArgumentLabel, debug: debug, level: level + 2, into: &string)
            } else if isArray {
                generateStructArrayProperty(with: key, jsonDictionaryName: jsonDictionaryName, constructorName: constructorName, trueArgumentLabel: trueArgumentLabel, debug: debug, level: level + 2, into: &string)
            }
        } else {
            generateOrdinaryProperty(of: .normal, with: key, debug: debug, level: level + 2, into: &string)
        }
    }

    private func generateStructDictionaryProperty(with key: String, jsonDictionaryName: String, constructorName: String?, trueArgumentLabel: String, debug: Bool, level: Int, into string: inout String) {
        indent(with: level, into: &string)
        string += "guard let \(key.coolie_lowerCamelCase)JSONDictionary = \(dictionaryName())[\"\(key)\"] as? \(jsonDictionaryName) else { "
        string += debug ? "print(\"Not found dictionary key: \(key)\"); return nil }\n" : "return nil }\n"
        indent(with: level, into: &string)
        if let constructorName = constructorName {
            string += "guard let \(key.coolie_lowerCamelCase) = \(key.capitalized).\(constructorName)(\(trueArgumentLabel)\(key.coolie_lowerCamelCase)JSONDictionary) else { "
        } else {
            string += "guard let \(key.coolie_lowerCamelCase) = \(key.capitalized)(\(trueArgumentLabel)\(key.coolie_lowerCamelCase)JSONDictionary) else { "
        }
        string += debug ? "print(\"Failed to generate: \(key.coolie_lowerCamelCase)\"); return nil }\n" : "return nil }\n"
    }

    private func generateStructArrayProperty(with key: String, jsonDictionaryName: String, constructorName: String?, trueArgumentLabel: String, debug: Bool, level: Int, into string: inout String) {
        guard case .array(_, let values) = self else { fatalError("Value is not array") }
        if let unionValue = unionValues(values) {
            if case .null(let optionalValue) = unionValue {
                if let value = optionalValue {
                    if value.isDictionary {
                        indent(with: level, into: &string)
                        string += "guard let \(key.coolie_lowerCamelCase)JSONArray = \(dictionaryName())[\"\(key)\"] as? [\(jsonDictionaryName)?] else { "
                        string += debug ? "print(\"Not found array key: \(key)\"); return nil }\n" : "return nil }\n"
                        indent(with: level, into: &string)
                        if let constructorName = constructorName {
                            string += "let \(key.coolie_lowerCamelCase) = \(key.coolie_lowerCamelCase)JSONArray.map({ $0.flatMap({ \(key.capitalized.coolie_dropLastCharacter).\(constructorName)(\(trueArgumentLabel)$0) }) })\n"
                        } else {
                            string += "let \(key.coolie_lowerCamelCase) = \(key.coolie_lowerCamelCase)JSONArray.map({ $0.flatMap({ \(key.capitalized.coolie_dropLastCharacter)(\(trueArgumentLabel)$0) }) })\n"
                        }
                    } else {
                        value.generateOrdinaryProperty(of: .optionalInArray, with: key, debug: debug, level: level, into: &string)
                    }
                } else {
                    indent(with: level, into: &string)
                    let type = "UnknownType"
                    string += "let \(key.coolie_lowerCamelCase) = \(dictionaryName())[\"\(key)\"] as? \(type)\n"
                }
            } else {
                if unionValue.isDictionary {
                    indent(with: level, into: &string)
                    string += "guard let \(key.coolie_lowerCamelCase)JSONArray = \(dictionaryName())[\"\(key)\"] as? [\(jsonDictionaryName)] else { "
                    string += debug ? "print(\"Not found array key: \(key)\"); return nil }\n" : "return nil }\n"
                    indent(with: level, into: &string)
                    if let constructorName = constructorName {
                        string += "let \(key.coolie_lowerCamelCase) = \(key.coolie_lowerCamelCase)JSONArray.map({ \(key.capitalized.coolie_dropLastCharacter).\(constructorName)(\(trueArgumentLabel)$0) }).flatMap({ $0 })\n"
                    } else {
                        string += "let \(key.coolie_lowerCamelCase) = \(key.coolie_lowerCamelCase)JSONArray.map({ \(key.capitalized.coolie_dropLastCharacter)(\(trueArgumentLabel)$0) }).flatMap({ $0 })\n"
                    }
                } else {
                    unionValue.generateOrdinaryProperty(of: .normalInArray, with: key, debug: debug, level: level, into: &string)
                }
            }
        } else { // no union value
            // do nothing
        }
    }
}

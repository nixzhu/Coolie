//
//  Coolie+Struct.swift
//  Coolie
//
//  Created by NIX on 16/11/3.
//  Copyright © 2016年 nixWork. All rights reserved.
//

import Foundation

extension Coolie.Value {

    fileprivate func indent(with level: Int, into string: inout String) {
        for _ in 0..<level {
            string += "\t"
        }
    }
}

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
                let value = info[key]
                value?.declareProperty(for: key, jsonDictionaryName: jsonDictionaryName, constructorName: constructorName, argumentLabel: argumentLabel, debug: debug, level: level + 1, into: &string)
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

extension Coolie.Value {

    func declareProperty(for key: String, jsonDictionaryName: String, constructorName: String?, argumentLabel: String?, debug: Bool, level: Int, into string: inout String) {
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

    private func generateDictionaryProperty(with key: String, jsonDictionaryName: String, constructorName: String?, trueArgumentLabel: String, debug: Bool, level: Int, into string: inout String) {
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

    private func generateArrayProperty(with key: String, jsonDictionaryName: String, constructorName: String?, trueArgumentLabel: String, debug: Bool, level: Int, into string: inout String) {
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

    private func generateOrdinaryProperty(with key: String, debug: Bool, level: Int, into string: inout String) {
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
}

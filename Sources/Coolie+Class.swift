//
//  Coolie+Class.swift
//  Coolie
//
//  Created by NIX on 16/11/3.
//  Copyright © 2016年 nixWork. All rights reserved.
//

import Foundation

extension Coolie.Value {

    func generateClass(fromLevel level: Int = 0, modelName: String? = nil, into string: inout String) {
        switch self {
        case .bool, .number, .string, .url, .date, .null:
            break
        case .dictionary(let info):
            // struct name
            indent(with: level, into: &string)
            string += "class \(modelName ?? "Model") {\n"
            // properties
            for key in info.keys.sorted() {
                let value = info[key]
                value?.declareClassProperty(for: key, level: level + 1, into: &string)
            }
            // generate method
            indent(with: level + 1, into: &string)
            if Config.throwsEnabled {
                string += "init(\(initArgumentLabel()): \(Config.jsonDictionaryName)) throws {\n"
            } else {
                string += "init?(\(initArgumentLabel()): \(Config.jsonDictionaryName)) {\n"
            }
            let trueArgumentLabel = Config.argumentLabel.flatMap({ "\($0): " }) ?? ""
            for key in info.keys.sorted() {
                let value = info[key]
                value?.generateClassProperty(with: key, trueArgumentLabel: trueArgumentLabel, level: level + 2, into: &string)
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
                            value.generateClass(fromLevel: level, modelName: name?.coolie_dropLastCharacter, into: &string)
                        }
                    } else {
                        fatalError("empty array")
                    }
                } else {
                    if unionValue.isDictionaryOrArray {
                        unionValue.generateClass(fromLevel: level, modelName: name?.coolie_dropLastCharacter, into: &string)
                    }
                }
            }
        }
    }
}

extension Coolie.Value {

    func declareClassProperty(for key: String, level: Int, into string: inout String) {
        if isDictionaryOrArray {
            generateClass(fromLevel: level, modelName: key.capitalized, into: &string)
            indent(with: level, into: &string)
            if isArray {
                if case .array(_, let values) = self, let unionValue = unionValues(values) {
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
            indent(with: level, into: &string)
            string += "var \(key.coolie_lowerCamelCase): \(type)\n"
        }
    }
}

extension Coolie.Value {

    func generateClassProperty(with key: String, trueArgumentLabel: String, level: Int, into string: inout String) {
        if isDictionaryOrArray {
            if isDictionary {
                generateClassDictionaryProperty(with: key, trueArgumentLabel: trueArgumentLabel, level: level, into: &string)
            } else if isArray {
                generateClassArrayProperty(with: key, trueArgumentLabel: trueArgumentLabel, level: level, into: &string)
            }
        } else {
            generateOrdinaryProperty(of: .normal, with: key, level: level, into: &string)
        }
    }

    private func generateClassDictionaryProperty(with key: String, trueArgumentLabel: String, level: Int, into string: inout String) {
        indent(with: level, into: &string)
        string += "guard let \(key.coolie_lowerCamelCase)JSONDictionary = \(parameterName())[\"\(key)\"] as? \(Config.jsonDictionaryName) else { "
        if Config.throwsEnabled {
            string += "throw ParseError.notFound(key: \"\(key)\") }\n"
        } else {
            string += Config.debug ? "print(\"Not found dictionary: \(key)\"); return nil }\n" : "return nil }\n"
        }
        indent(with: level, into: &string)
        if Config.throwsEnabled {
            string += "guard let \(key.coolie_lowerCamelCase) = try? \(key.capitalized)(\(trueArgumentLabel)\(key.coolie_lowerCamelCase)JSONDictionary) else { "
            string += "throw ParseError.failedToGenerate(property: \"\(key.coolie_lowerCamelCase)\") }\n"
        } else {
            string += "guard let \(key.coolie_lowerCamelCase) = \(key.capitalized)(\(trueArgumentLabel)\(key.coolie_lowerCamelCase)JSONDictionary) else { "
            string += Config.debug ? "print(\"Failed to generate: \(key.coolie_lowerCamelCase)\"); return nil }\n" : "return nil }\n"
        }
    }

    private func generateClassArrayProperty(with key: String, trueArgumentLabel: String, level: Int, into string: inout String) {
        guard case .array(_, let values) = self else { fatalError("Value is not array") }
        if let unionValue = unionValues(values) {
            if case .null(let optionalValue) = unionValue {
                if let value = optionalValue {
                    if value.isDictionary {
                        indent(with: level, into: &string)
                        string += "guard let \(key.coolie_lowerCamelCase)JSONArray = \(parameterName())[\"\(key)\"] as? [\(Config.jsonDictionaryName)?] else { "
                        if Config.throwsEnabled {
                            string += "throw ParseError.notFound(key: \"\(key)\") }\n"
                        } else {
                            string += Config.debug ? "print(\"Not found array key: \(key)\"); return nil }\n" : "return nil }\n"
                        }
                        indent(with: level, into: &string)
                        string += "let \(key.coolie_lowerCamelCase) = \(key.coolie_lowerCamelCase)JSONArray.map({ $0.flatMap({ \(key.capitalized.coolie_dropLastCharacter)(\(trueArgumentLabel)$0) }) })\n"
                    } else {
                        value.generateOrdinaryProperty(of: .optionalInArray, with: key, level: level, into: &string)
                    }
                } else {
                    indent(with: level, into: &string)
                    let type = "UnknownType"
                    string += "let \(key.coolie_lowerCamelCase) = \(parameterName())[\"\(key)\"] as? \(type)\n"
                }
            } else {
                if unionValue.isDictionary {
                    indent(with: level, into: &string)
                    string += "guard let \(key.coolie_lowerCamelCase)JSONArray = \(parameterName())[\"\(key)\"] as? [\(Config.jsonDictionaryName)] else { "
                    if Config.throwsEnabled {
                        string += "throw ParseError.notFound(key: \"\(key)\") }\n"
                    } else {
                        string += Config.debug ? "print(\"Not found array key: \(key)\"); return nil }\n" : "return nil }\n"
                    }
                    indent(with: level, into: &string)
                    string += "let \(key.coolie_lowerCamelCase) = \(key.coolie_lowerCamelCase)JSONArray.map({ \(key.capitalized.coolie_dropLastCharacter)(\(trueArgumentLabel)$0) }).flatMap({ $0 })\n"
                } else {
                    unionValue.generateOrdinaryProperty(of: .normalInArray, with: key, level: level, into: &string)
                }
            }
        } else { // no union value
            // do nothing
        }
    }
}

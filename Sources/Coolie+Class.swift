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
            string += "\(publicString())class \(modelName ?? "Model") {\n"
            // properties
            for key in info.keys.sorted() {
                let value = info[key]
                value?.declareClassProperty(for: key, level: level + 1, into: &string)
            }
            // generate method
            indent(with: level + 1, into: &string)
            if Config.throwsEnabled {
                string += "\(publicString())init(\(initArgumentLabel()): \(Config.jsonDictionaryName)) throws {\n"
            } else {
                string += "\(publicString())init?(\(initArgumentLabel()): \(Config.jsonDictionaryName)) {\n"
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

    func declareClassProperty(for key: String, optional: Bool = false, level: Int, into string: inout String) {
        if isDictionaryOrArray {
            generateClass(fromLevel: level, modelName: key.capitalized, into: &string)
            indent(with: level, into: &string)
            if isArray {
                if case .array(_, let values) = self, let unionValue = unionValues(values) {
                    if case .null(let optionalValue) = unionValue {
                        if let _value = optionalValue {
                            if _value.isDictionary {
                                string += "\(publicString())var \(key.coolie_lowerCamelCase): [\(key.capitalized.coolie_dropLastCharacter)?]"
                            } else {
                                string += "\(publicString())var \(key.coolie_lowerCamelCase): [\(_value.type)?]"
                            }
                        } else {
                            string += "\(publicString())var \(key.coolie_lowerCamelCase): [UnknowType?]"
                        }
                    } else {
                        if unionValue.isDictionary {
                            string += "\(publicString())var \(key.coolie_lowerCamelCase): [\(key.capitalized.coolie_dropLastCharacter)]"
                        } else {
                            string += "\(publicString())var \(key.coolie_lowerCamelCase): [\(unionValue.type)]"
                        }
                    }
                } else {
                    string += "\(publicString())var \(key.coolie_lowerCamelCase): [\(key.capitalized.coolie_dropLastCharacter)]"
                }
            } else {
                string += "\(publicString())var \(key.coolie_lowerCamelCase): \(key.capitalized)"
            }
            if optional {
                string += "?\n"
            } else {
                string += "\n"
            }
        } else {
            if case .null(let value) = self {
                if let value = value {
                    value.declareClassProperty(for: key, optional: true, level: level, into: &string)
                } else {
                    indent(with: level, into: &string)
                    string += "\(publicString())var \(key.coolie_lowerCamelCase): UnknownType?\n"
                }
            } else {
                indent(with: level, into: &string)
                string += "\(publicString())var \(key.coolie_lowerCamelCase): \(type)"
                if optional {
                    string += "?\n"
                } else {
                    string += "\n"
                }
            }
        }
    }
}

extension Coolie.Value {

    func generateClassProperty(with key: String, optional: Bool = false, trueArgumentLabel: String, level: Int, into string: inout String) {
        if isDictionaryOrArray {
            if isDictionary {
                generateClassDictionaryProperty(with: key, optional: optional, trueArgumentLabel: trueArgumentLabel, level: level, into: &string)
            } else if isArray {
                generateClassArrayProperty(with: key, optional: optional, trueArgumentLabel: trueArgumentLabel, level: level, into: &string)
            }
        } else {
            if case .null(let value) = self {
                if let value = value {
                    value.generateClassProperty(with: key, optional: true, trueArgumentLabel: trueArgumentLabel, level: level, into: &string)
                } else {
                    indent(with: level, into: &string)
                    let type = "UnknownType"
                    string += "let \(key.coolie_lowerCamelCase) = \(parameterName())[\"\(key)\"] as? \(type)\n"
                }
            } else {
                generateOrdinaryProperty(of: optional ? .optional : .normal, with: key, level: level, into: &string)
            }
        }
    }

    private func generateClassDictionaryProperty(with key: String, optional: Bool, trueArgumentLabel: String, level: Int, into string: inout String) {
        if optional {
            indent(with: level, into: &string)
            string += "let \(key.coolie_lowerCamelCase)JSONDictionary = \(parameterName())[\"\(key)\"] as? \(Config.jsonDictionaryName)\n"
            indent(with: level, into: &string)
            if let constructorName = Config.constructorName {
                string += "let \(key.coolie_lowerCamelCase) = \(key.coolie_lowerCamelCase)JSONDictionary.flatMap({ \(key.capitalized).\(constructorName)(\(trueArgumentLabel)$0) })\n"
            } else {
                string += "let \(key.coolie_lowerCamelCase) = \(key.coolie_lowerCamelCase)JSONDictionary.flatMap({ \(key.capitalized)(\(trueArgumentLabel)$0) })\n"
            }
        } else {
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
    }

    private func generateClassArrayProperty(with key: String, optional: Bool, trueArgumentLabel: String, level: Int, into string: inout String) {
        guard case .array(_, let values) = self else { fatalError("Value is not array") }
        if optional {
            string += "To be continue (for optional Array)"
            return
        }
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

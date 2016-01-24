//
//  Coolie.swift
//  Coolie
//
//  Created by NIX on 16/1/23.
//  Copyright © 2016年 nixWork. All rights reserved.
//

import Foundation

public class Coolie: NSObject {

    private let scanner: NSScanner

    public init(JSONString: String) {
        scanner = NSScanner(string: JSONString)
    }

    public func printModelWithName(modelName: String) {
        if let value = parse() {
            value.printAtLevel(0, modelName: modelName)
        } else {
            print("Parse failed!")
        }
    }

    private enum Token {

        case BeginObject(Swift.String)      // {
        case EndObject(Swift.String)        // }

        case BeginArray(Swift.String)       // [
        case EndArray(Swift.String)         // ]

        case Colon(Swift.String)            // ;
        case Comma(Swift.String)            // ,

        case Bool(Swift.Bool)               // true or false
        enum NumberType {
            case Int(Swift.Int)
            case Double(Swift.Double)
        }
        case Number(NumberType)             // 42, 99.99
        case String(Swift.String)           // "nix", ...

        case Null
    }

    private enum Value {

        case Null

        case Bool(Swift.Bool)
        enum NumberType {
            case Int(Swift.Int)
            case Double(Swift.Double)
        }
        case Number(NumberType)
        case String(Swift.String)

        indirect case Dictionary([Swift.String: Value])
        indirect case Array(name: Swift.String?, values: [Value])

        var type: Swift.String {
            switch self {
            case .Bool:
                return "Bool"
            case .Number(let number):
                switch number {
                case .Int:
                    return "Int"
                case .Double:
                    return "Double"
                }
            case .String:
                return "String"
            case .Null:
                return "UnknownType?"
            default:
                fatalError("Unknown type")
            }
        }

        var isDictionaryOrArray: Swift.Bool {
            switch self {
            case .Dictionary:
                return true
            case .Array:
                return true
            default:
                return false
            }
        }

        var isDictionary: Swift.Bool {
            switch self {
            case .Dictionary:
                return true
            default:
                return false
            }
        }

        var isArray: Swift.Bool {
            switch self {
            case .Array:
                return true
            default:
                return false
            }
        }

        var isNull: Swift.Bool {
            switch self {
            case .Null:
                return true
            default:
                return false
            }
        }

        func printAtLevel(level: Int, modelName: Swift.String? = nil) {

            func indentLevel(level: Int) {
                for _ in 0..<level {
                    print("\t", terminator: "")
                }
            }

            switch self {

            case .Bool, .Number, .String, .Null:
                print(type)

            case .Dictionary(let info):
                // struct name
                indentLevel(level)
                if let modelName = modelName {
                    print("struct \(modelName) {")
                } else {
                    print("struct Model {")
                }

                // properties
                for key in info.keys.sort() {
                    if let value = info[key] {
                        if value.isDictionaryOrArray {
                            value.printAtLevel(level + 1, modelName: key.capitalizedString)
                            indentLevel(level + 1)
                            if value.isArray {
                                if case .Array(_, let values) = value, let first = values.first where !first.isDictionaryOrArray {
                                    print("let \(key.coolie_lowerCamelCase): [\(first.type)]", terminator: "\n")
                                } else {
                                    print("let \(key.coolie_lowerCamelCase): [\(key.capitalizedString.coolie_dropLastCharacter)]", terminator: "\n")
                                }
                            } else {
                                print("let \(key.coolie_lowerCamelCase): \(key.capitalizedString)", terminator: "\n")
                            }
                        } else {
                            indentLevel(level + 1)
                            print("let \(key.coolie_lowerCamelCase): ", terminator: "")
                            value.printAtLevel(level)
                        }
                    }
                }

                // generate method
                indentLevel(level + 1)
                if let modelName = modelName {
                    print("static func fromJSONDictionary(info: [String: AnyObject]) -> \(modelName)? {")
                } else {
                    print("static func fromJSONDictionary(info: [String: AnyObject]) -> Model? {")
                }
                switch self {
                case .Dictionary(let info):
                    for key in info.keys.sort() {
                        if let value = info[key] {
                            if value.isDictionaryOrArray {
                                if value.isDictionary {
                                    indentLevel(level + 2)
                                    print("guard let \(key.coolie_lowerCamelCase)JSONDictionary = info[\"\(key)\"] as? [String: AnyObject] else { return nil }")
                                    indentLevel(level + 2)
                                    print("guard let \(key.coolie_lowerCamelCase) = \(key.capitalizedString).fromJSONDictionary(\(key.coolie_lowerCamelCase)JSONDictionary) else { return nil }")
                                } else if value.isArray {
                                    if case .Array(_, let values) = value, let first = values.first where !first.isDictionaryOrArray {
                                        indentLevel(level + 2)
                                        if first.isNull {
                                            print("let \(key.coolie_lowerCamelCase) = info[\"\(key)\"] as? UnknownType")
                                        } else {
                                            print("guard let \(key.coolie_lowerCamelCase) = info[\"\(key)\"] as? [\(first.type)] else { return nil }")
                                        }
                                    } else {
                                        indentLevel(level + 2)
                                        print("guard let \(key.coolie_lowerCamelCase)JSONArray = info[\"\(key)\"] as? [[String: AnyObject]] else { return nil }")
                                        indentLevel(level + 2)
                                        print("let \(key.coolie_lowerCamelCase) = \(key.coolie_lowerCamelCase)JSONArray.map({ \(key.capitalizedString.coolie_dropLastCharacter).fromJSONDictionary($0) }).flatMap({ $0 })")
                                    }
                                }
                            } else {
                                indentLevel(level + 2)
                                if value.isNull {
                                    print("let \(key.coolie_lowerCamelCase) = info[\"\(key)\"] as? UnknownType")
                                } else {
                                    print("guard let \(key.coolie_lowerCamelCase) = info[\"\(key)\"] as? \(value.type) else { return nil }")
                                }
                            }
                        }
                    }
                default:
                    break
                }

                // return model
                switch self {
                case .Dictionary(let info):
                    indentLevel(level + 2)
                    if let modelName = modelName {
                        print("return \(modelName)(", terminator: "")
                    } else {
                        print("return Model(", terminator: "")
                    }
                    let lastIndex = info.keys.count - 1
                    for (index, key) in info.keys.sort().enumerate() {
                        let suffix = (index == lastIndex) ? ")" : ", "
                        print("\(key.coolie_lowerCamelCase): \(key.coolie_lowerCamelCase)" + suffix, terminator: "")
                    }
                    print("")
                default:
                    break
                }

                indentLevel(level + 1)
                print("}")

                indentLevel(level)
                print("}")

            case .Array(let name, let values):
                if let first = values.first {
                    if first.isDictionaryOrArray {
                        first.printAtLevel(level, modelName: name?.coolie_dropLastCharacter)
                    }
                }
            }
        }
    }

    private func generateTokens() -> [Token] {

        func scanBeginObject() -> Token? {

            if scanner.scanString("{", intoString: nil) {
                return .BeginObject("{")
            }

            return nil
        }

        func scanEndObject() -> Token? {

            if scanner.scanString("}", intoString: nil) {
                return .EndObject("}")
            }

            return nil
        }

        func scanBeginArray() -> Token? {

            if scanner.scanString("[", intoString: nil) {
                return .BeginArray("[")
            }

            return nil
        }

        func scanEndArray() -> Token? {

            if scanner.scanString("]", intoString: nil) {
                return .EndArray("]")
            }

            return nil
        }

        func scanColon() -> Token? {

            if scanner.scanString(":", intoString: nil) {
                return .Colon(":")
            }

            return nil
        }

        func scanComma() -> Token? {

            if scanner.scanString(",", intoString: nil) {
                return .Comma(",")
            }

            return nil
        }

        func scanBool() -> Token? {

            if scanner.scanString("true", intoString: nil) {
                return .Bool(true)
            }

            if scanner.scanString("false", intoString: nil) {
                return .Bool(false)
            }

            return nil
        }

        func scanNumber() -> Token? {

            let symbolSet = NSMutableCharacterSet.decimalDigitCharacterSet()
            symbolSet.addCharactersInString(".")

            var string: NSString?

            if scanner.scanCharactersFromSet(symbolSet, intoString: &string) {

                if let string = string as? String {

                    if let number = Int(string) {
                        return .Number(.Int(number))

                    } else if let number = Double(string) {
                        return .Number(.Double(number))
                    }
                }
            }

            return nil
        }

        func scanString() -> Token? {

            let symbolSet = NSMutableCharacterSet.alphanumericCharacterSet()
            symbolSet.formUnionWithCharacterSet(NSCharacterSet.punctuationCharacterSet())
            symbolSet.formUnionWithCharacterSet(NSCharacterSet.symbolCharacterSet())
            symbolSet.formUnionWithCharacterSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            symbolSet.removeCharactersInString("\"")

            var string: NSString?

            if scanner.scanString("\"", intoString: nil) &&
                scanner.scanCharactersFromSet(symbolSet, intoString: &string) &&
                scanner.scanString("\"", intoString: nil) {

                    if let string = string as? String {
                        return .String(string)
                    }
            }

            return nil
        }

        func scanNull() -> Token? {
            if scanner.scanString("null", intoString: nil) {
                return .Null
            }

            return nil
        }

        var tokens = [Token]()

        while !scanner.atEnd {

            if let token = scanBeginObject() {
                tokens.append(token)
            }

            if let token = scanEndObject() {
                tokens.append(token)
            }

            if let token = scanBeginArray() {
                tokens.append(token)
            }

            if let token = scanEndArray() {
                tokens.append(token)
            }

            if let token = scanColon() {
                tokens.append(token)
            }

            if let token = scanComma() {
                tokens.append(token)
            }

            if let token = scanBool() {
                tokens.append(token)
            }

            if let token = scanNumber() {
                tokens.append(token)
            }

            if let token = scanString() {
                tokens.append(token)
            }

            if let token = scanNull() {
                tokens.append(token)
            }
        }

        return tokens
    }

    private func parse() -> Value? {

        let tokens = generateTokens()

        var next = 0

        func parseValue() -> Value? {

            let token = tokens[next]

            switch token {

            case .BeginArray:

                var arrayName: String?
                let nameIndex = next - 2
                if nameIndex >= 0 {
                    let nameToken = tokens[nameIndex]
                    if case .String(let name) = nameToken {
                        arrayName = name.capitalizedString
                    }
                }

                next++
                return parseArray(name: arrayName)

            case .BeginObject:
                next++
                return parseObject()

            case .Bool:
                return parseBool()

            case .Number:
                return parseNumber()

            case .String:
                return parseString()

            case .Null:
                return parseNull()

            default:
                return nil
            }
        }

        func parseArray(name name: String? = nil) -> Value? {

            let token = tokens[next]

            var array = [Value]()

            if case .EndArray = token {
                next++
                return .Array(name: name, values: array)

            } else {
                while true {
                    guard let value = parseValue() else {
                        break
                    }

                    array.append(value)

                    let token = tokens[next]

                    if case .EndArray = token {
                        next++
                        return .Array(name: name, values: array)
                    }

                    guard let _ = parseComma() else {
                        break
                    }
                }

                return nil
            }
        }

        func parseObject() -> Value? {

            let token = tokens[next]

            var dictionary = [String: Value]()

            if case .EndObject = token {
                next++
                return .Dictionary(dictionary)

            } else {
                while true {
                    guard let key = parseString(), _ = parseColon(), value = parseValue() else {
                        print("Expect key : value")
                        break
                    }

                    if case .String(let key) = key {
                        dictionary[key] = value
                    }

                    let token = tokens[next]
                    if case .EndObject = token {
                        next++
                        return .Dictionary(dictionary)
                    }

                    guard let _ = parseComma() else {
                        print("Expect comma")
                        break
                    }
                }
            }

            return nil
        }

        func parseColon() -> Value? {

            let token = tokens[next++]
            if case .Colon(let string) = token {
                return .String(string)
            }

            return nil
        }

        func parseComma() -> Value? {

            let token = tokens[next++]
            if case .Comma(let string) = token {
                return .String(string)
            }

            return nil
        }

        func parseBool() -> Value? {

            let token = tokens[next++]
            if case .Bool(let bool) = token {
                return .Bool(bool)
            }

            return nil
        }

        func parseNumber() -> Value? {

            let token = tokens[next++]
            if case .Number(let number) = token {
                switch number {
                case .Int(let int):
                    return .Number(.Int(int))
                case .Double(let double):
                    return .Number(.Double(double))
                }
            }

            return nil
        }

        func parseString() -> Value? {

            let token = tokens[next++]
            if case .String(let string) = token {
                return .String(string)
            }

            return nil
        }

        func parseNull() -> Value? {

            let token = tokens[next++]
            if case .Null = token {
                return .Null
            }

            return nil
        }

        return parseValue()
    }
}

private extension String {

    var coolie_dropLastCharacter: String {

        if characters.count > 0 {
            return String(characters.dropLast())
        }

        return self
    }

    var coolie_lowerCamelCase: String {
        let parts = self.componentsSeparatedByString("_")
        return parts.enumerate().map({ index, part in
            return index == 0 ? part : part.capitalizedString
        }).joinWithSeparator("")
    }
}

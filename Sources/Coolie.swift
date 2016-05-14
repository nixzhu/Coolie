//
//  Coolie.swift
//  Coolie
//
//  Created by NIX on 16/1/23.
//  Copyright © 2016年 nixWork. All rights reserved.
//

import Foundation

final public class Coolie {

    private let scanner: NSScanner

    public init(_ jsonString: String) {
        scanner = NSScanner(string: jsonString)
    }

    public func generateModelWithName(modelName: String) -> String? {

        if let value = parse() {
            var string = ""
            value.generateStruct(fromLevel: 0, withModelName: modelName, intoString: &string)
            return string

        } else {
            print("Coolie parse failed!")
        }

        return nil
    }

    public enum ModelType: String {

        case Struct = "struct"
        case Class = "class"
    }

    public func generateModel(name name: String, type: ModelType) -> String? {

        if let value = parse() {
            var string = ""

            switch type {
            case .Struct:
                value.generateStruct(fromLevel: 0, withModelName: name, intoString: &string)
            case .Class:
                break
            }

            return string

        } else {
            print("Coolie parse failed!")
        }

        return nil
    }

    private enum Token {

        case BeginObject(Swift.String)      // {
        case EndObject(Swift.String)        // }

        case BeginArray(Swift.String)       // [
        case EndArray(Swift.String)         // ]

        case Colon(Swift.String)            // :
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

        case Bool(Swift.Bool)
        enum NumberType {
            case Int(Swift.Int)
            case Double(Swift.Double)
        }
        case Number(NumberType)
        case String(Swift.String)

        case Null

        indirect case Dictionary([Swift.String: Value])
        indirect case Array(name: Swift.String?, values: [Value])


    }

    lazy var numberScanningSet: NSCharacterSet = {
        let symbolSet = NSMutableCharacterSet.decimalDigitCharacterSet()
        symbolSet.addCharactersInString(".-")
        return symbolSet
    }()

    lazy var stringScanningSet: NSCharacterSet = {
        let symbolSet = NSMutableCharacterSet.alphanumericCharacterSet()
        symbolSet.formUnionWithCharacterSet(NSCharacterSet.punctuationCharacterSet())
        symbolSet.formUnionWithCharacterSet(NSCharacterSet.symbolCharacterSet())
        symbolSet.formUnionWithCharacterSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        symbolSet.removeCharactersInString("\"")
        return symbolSet
    }()

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

            var string: NSString?

            if scanner.scanCharactersFromSet(numberScanningSet, intoString: &string) {

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

            var string: NSString?

            if scanner.scanString("\"\"", intoString: nil) {
                return .String("")
            }

            if scanner.scanString("\"", intoString: nil) &&
                scanner.scanCharactersFromSet(stringScanningSet, intoString: &string) &&
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

            let previousScanLocation = scanner.scanLocation

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

            let currentScanLocation = scanner.scanLocation
            guard currentScanLocation > previousScanLocation else {
                print("Not found valid token")
                break
            }
        }

        return tokens
    }

    private func parse() -> Value? {

        let tokens = generateTokens()

        guard !tokens.isEmpty else {
            print("No tokens")
            return nil
        }

        var next = 0

        func parseValue() -> Value? {

            guard let token = tokens[coolie_safe: next] else {
                print("No token for parseValue")
                return nil
            }

            switch token {

            case .BeginArray:

                var arrayName: String?
                let nameIndex = next - 2
                if nameIndex >= 0 {
                    if let nameToken = tokens[coolie_safe: nameIndex] {
                        if case .String(let name) = nameToken {
                            arrayName = name.capitalizedString
                        }
                    }
                }

                next += 1
                return parseArray(name: arrayName)

            case .BeginObject:
                next += 1
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

            guard let token = tokens[coolie_safe: next] else {
                print("No token for parseArray")
                return nil
            }

            var array = [Value]()

            if case .EndArray = token {
                next += 1
                return .Array(name: name, values: array)

            } else {
                while true {
                    guard let value = parseValue() else {
                        break
                    }

                    array.append(value)

                    if let token = tokens[coolie_safe: next] {

                        if case .EndArray = token {
                            next += 1
                            return .Array(name: name, values: array)

                        } else {
                            guard let _ = parseComma() else {
                                print("Expect comma")
                                break
                            }

                            guard let nextToken = tokens[coolie_safe: next] where nextToken.isNotEndArray else {
                                print("Invalid JSON, comma at end of array")
                                break
                            }
                        }
                    }
                }

                return nil
            }
        }

        func parseObject() -> Value? {

            guard let token = tokens[coolie_safe: next] else {
                print("No token for parseObject")
                return nil
            }

            var dictionary = [String: Value]()

            if case .EndObject = token {
                next += 1
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

                    if let token = tokens[coolie_safe: next] {

                        if case .EndObject = token {
                            next += 1
                            return .Dictionary(dictionary)

                        } else {
                            guard let _ = parseComma() else {
                                print("Expect comma")
                                break
                            }

                            guard let nextToken = tokens[coolie_safe: next] where nextToken.isNotEndObject else {
                                print("Invalid JSON, comma at end of object")
                                break
                            }
                        }
                    }
                }
            }

            return nil
        }

        func parseColon() -> Value? {

            defer {
                next += 1
            }

            guard let token = tokens[coolie_safe: next] else {
                print("No token for parseColon")
                return nil
            }

            if case .Colon(let string) = token {
                return .String(string)
            }

            return nil
        }

        func parseComma() -> Value? {

            defer {
                next += 1
            }

            guard let token = tokens[coolie_safe: next] else {
                print("No token for parseComma")
                return nil
            }

            if case .Comma(let string) = token {
                return .String(string)
            }

            return nil
        }

        func parseBool() -> Value? {

            defer {
                next += 1
            }

            guard let token = tokens[coolie_safe: next] else {
                print("No token for parseBool")
                return nil
            }

            if case .Bool(let bool) = token {
                return .Bool(bool)
            }

            return nil
        }

        func parseNumber() -> Value? {

            defer {
                next += 1
            }

            guard let token = tokens[coolie_safe: next] else {
                print("No token for parseNumber")
                return nil
            }

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

            defer {
                next += 1
            }

            guard let token = tokens[coolie_safe: next] else {
                print("No token for parseString")
                return nil
            }

            if case .String(let string) = token {
                return .String(string)
            }

            return nil
        }

        func parseNull() -> Value? {

            defer {
                next += 1
            }

            guard let token = tokens[coolie_safe: next] else {
                print("No token for parseNull")
                return nil
            }

            if case .Null = token {
                return .Null
            }

            return nil
        }

        return parseValue()
    }
}

private extension Coolie.Value {

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
}

private extension Coolie.Token {

    var isNotEndObject: Swift.Bool {
        switch self {
        case .EndObject:
            return false
        default:
            return true
        }
    }

    var isNotEndArray: Swift.Bool {
        switch self {
        case .EndArray:
            return false
        default:
            return true
        }
    }
}

private extension Coolie.Value {

    func unionValues(values: [Coolie.Value]) -> Coolie.Value? {

        guard values.count > 1 else {
            return values.first
        }

        if let first = values.first, case .Dictionary(let firstInfo) = first {

            var info: [Swift.String: Coolie.Value] = firstInfo

            let keys = firstInfo.keys

            for i in 1..<values.count {
                let next = values[i]
                if case .Dictionary(let nextInfo) = next {
                    for key in keys {
                        if let value = nextInfo[key] where !value.isNull {
                            info[key] = value
                        }
                    }
                }
            }

            return .Dictionary(info)
        }

        return values.first
    }
}

private extension Coolie.Value {

    func generateStruct(fromLevel level: Int, withModelName modelName: Swift.String? = nil, inout intoString string: Swift.String) {

        func indentLevel(level: Int) {
            for _ in 0..<level {
                string += "\t"
            }
        }

        switch self {

        case .Bool, .Number, .String, .Null:
            string += "\(type)\n"

        case .Dictionary(let info):
            // struct name
            indentLevel(level)
            string += "struct \(modelName ?? "Model") {\n"

            // properties
            for key in info.keys.sort() {
                if let value = info[key] {
                    if value.isDictionaryOrArray {
                        value.generateStruct(fromLevel: level + 1, withModelName: key.capitalizedString, intoString: &string)
                        indentLevel(level + 1)
                        if value.isArray {
                            if case .Array(_, let values) = value, let unionValue = unionValues(values) where !unionValue.isDictionaryOrArray {
                                string += "let \(key.coolie_lowerCamelCase): [\(unionValue.type)]\n"
                            } else {
                                string += "let \(key.coolie_lowerCamelCase): [\(key.capitalizedString.coolie_dropLastCharacter)]\n"
                            }
                        } else {
                            string += "let \(key.coolie_lowerCamelCase): \(key.capitalizedString)\n"
                        }
                    } else {
                        indentLevel(level + 1)
                        string += "let \(key.coolie_lowerCamelCase): "
                        value.generateStruct(fromLevel: level, intoString: &string)
                    }
                }
            }

            // generate method
            indentLevel(level + 1)
            string += "init?(_ info: [String: AnyObject]) {\n"
            for key in info.keys.sort() {
                if let value = info[key] {
                    if value.isDictionaryOrArray {
                        if value.isDictionary {
                            indentLevel(level + 2)
                            string += "guard let \(key.coolie_lowerCamelCase)JSONDictionary = info[\"\(key)\"] as? [String: AnyObject] else { return nil }\n"
                            indentLevel(level + 2)
                            string += "guard let \(key.coolie_lowerCamelCase) = \(key.capitalizedString)(\(key.coolie_lowerCamelCase)JSONDictionary) else { return nil }\n"
                        } else if value.isArray {
                            if case .Array(_, let values) = value, let unionValue = unionValues(values) where !unionValue.isDictionaryOrArray {
                                indentLevel(level + 2)
                                if unionValue.isNull {
                                    string += "let \(key.coolie_lowerCamelCase) = info[\"\(key)\"] as? UnknownType\n"
                                } else {
                                    string += "guard let \(key.coolie_lowerCamelCase) = info[\"\(key)\"] as? [\(unionValue.type)] else { return nil }\n"
                                }
                            } else {
                                indentLevel(level + 2)
                                string += "guard let \(key.coolie_lowerCamelCase)JSONArray = info[\"\(key)\"] as? [[String: AnyObject]] else { return nil }\n"
                                indentLevel(level + 2)
                                string += "let \(key.coolie_lowerCamelCase) = \(key.coolie_lowerCamelCase)JSONArray.map({ \(key.capitalizedString.coolie_dropLastCharacter)($0) }).flatMap({ $0 })\n"
                            }
                        }
                    } else {
                        indentLevel(level + 2)
                        if value.isNull {
                            string += "let \(key.coolie_lowerCamelCase) = info[\"\(key)\"] as? UnknownType\n"
                        } else {
                            string += "guard let \(key.coolie_lowerCamelCase) = info[\"\(key)\"] as? \(value.type) else { return nil }\n"
                        }
                    }
                }
            }

            for key in info.keys.sort() {
                indentLevel(level + 2)
                let property = key.coolie_lowerCamelCase
                string += "self.\(property) = \(property)\n"
            }

            indentLevel(level + 1)
            string += "}\n"

            indentLevel(level)
            string += "}\n"

        case .Array(let name, let values):
            if let unionValue = unionValues(values) {
                if unionValue.isDictionaryOrArray {
                    unionValue.generateStruct(fromLevel: level, withModelName: name?.coolie_dropLastCharacter, intoString: &string)
                }
            }
        }
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

        let symbolSet = NSMutableCharacterSet.alphanumericCharacterSet()
        symbolSet.addCharactersInString("_")
        symbolSet.invert()

        let validString = self.componentsSeparatedByCharactersInSet(symbolSet).joinWithSeparator("_")
        let parts = validString.componentsSeparatedByString("_")

        return parts.enumerate().map({ index, part in
            return index == 0 ? part : part.capitalizedString
        }).joinWithSeparator("")
    }
}

private extension Array {

    subscript (coolie_safe index: Int) -> Element? {
        return index >= 0 && index < count ? self[index] : nil
    }
}

//
//  Coolie.swift
//  Coolie
//
//  Created by NIX on 16/1/23.
//  Copyright © 2016年 nixWork. All rights reserved.
//

import Foundation

final public class Coolie {

    private let scanner: Scanner

    public init(_ jsonString: String) {
        scanner = Scanner(string: jsonString)
    }

    public enum ModelType: String {
        case `struct`
        case `class`
    }

    public func generateModel(name: String, type: ModelType, argumentLabel: String? = nil, constructorName: String? = nil, jsonDictionaryName: String? = nil, debug: Bool = false) -> String? {
        guard let value = parse() else {
            print("Coolie parse failed!")
            return nil
        }
        var string = ""
        switch type {
        case .`struct`:
            value.generateStruct(modelName: name, argumentLabel: argumentLabel, constructorName: constructorName, jsonDictionaryName: jsonDictionaryName, debug: debug, into: &string)
        case .`class`:
            value.generateClass(modelName: name, argumentLabel: argumentLabel, jsonDictionaryName: jsonDictionaryName, debug: debug, into: &string)
        }
        return string
    }

    fileprivate enum Token {
        case beginObject(String)    // {
        case endObject(String)      // }
        case beginArray(String)     // [
        case endArray(String)       // ]
        case colon(String)          // :
        case comma(String)          // ,
        case bool(Bool)             // true or false
        enum NumberType {
            case int(Int)
            case double(Double)
        }
        case number(NumberType)     // 42, 99.99
        case string(String)         // "nix", ...
        case null                   // null
    }

    public enum Value {
        case bool(Bool)
        public enum NumberType {
            case int(Int)
            case double(Double)
        }
        case number(NumberType)
        case string(String)
        indirect case null(Value?)
        indirect case dictionary([String: Value])
        indirect case array(name: String?, values: [Value])
    }

    lazy var numberScanningSet: CharacterSet = {
        var symbolSet = CharacterSet.decimalDigits
        symbolSet.formUnion(CharacterSet(charactersIn: ".-"))
        return symbolSet
    }()

    lazy var stringScanningSet: CharacterSet = {
        var symbolSet = CharacterSet.alphanumerics
        symbolSet.formUnion(CharacterSet.punctuationCharacters)
        symbolSet.formUnion(CharacterSet.symbols)
        symbolSet.formUnion(CharacterSet.whitespacesAndNewlines)
        symbolSet.remove(charactersIn: "\"")
        return symbolSet
    }()

    private func generateTokens() -> [Token] {

        func scanBeginObject() -> Token? {
            return scanner.scanString("{", into: nil) ? .beginObject("{") : nil
        }
        func scanEndObject() -> Token? {
            return scanner.scanString("}", into: nil) ? .endObject("}") : nil
        }
        func scanBeginArray() -> Token? {
            return scanner.scanString("[", into: nil) ? .beginArray("[") : nil
        }
        func scanEndArray() -> Token? {
            return scanner.scanString("]", into: nil) ? .endArray("]") : nil
        }
        func scanColon() -> Token? {
            return scanner.scanString(":", into: nil) ? .colon(":") : nil
        }
        func scanComma() -> Token? {
            return scanner.scanString(",", into: nil) ? .comma(",") : nil
        }
        func scanBool() -> Token? {
            if scanner.scanString("true", into: nil) { return .bool(true) }
            if scanner.scanString("false", into: nil) { return .bool(false) }
            return nil
        }
        func scanNumber() -> Token? {
            var string: NSString?
            if scanner.scanCharacters(from: numberScanningSet, into: &string) {
                if let string = string as? String {
                    if let number = Int(string) {
                        return .number(.int(number))
                    } else if let number = Double(string) {
                        return .number(.double(number))
                    }
                }
            }
            return nil
        }
        func scanString() -> Token? {
            if scanner.scanString("\"\"", into: nil) { return .string("") }
            var string: NSString?
            if scanner.scanString("\"", into: nil) &&
                scanner.scanCharacters(from: stringScanningSet, into: &string) &&
                scanner.scanString("\"", into: nil) {
                if let string = string as? String {
                    return .string(string)
                }
            }
            return nil
        }
        func scanNull() -> Token? {
            return scanner.scanString("null", into: nil) ? .null : nil
        }

        var tokens = [Token]()
        while !scanner.isAtEnd {
            let previousScanLocation = scanner.scanLocation
            scanBeginObject().flatMap({ tokens.append($0) })
            scanEndObject().flatMap({ tokens.append($0) })
            scanBeginArray().flatMap({ tokens.append($0) })
            scanEndArray().flatMap({ tokens.append($0) })
            scanColon().flatMap({ tokens.append($0) })
            scanComma().flatMap({ tokens.append($0) })
            scanBool().flatMap({ tokens.append($0) })
            scanNumber().flatMap({ tokens.append($0) })
            scanString().flatMap({ tokens.append($0) })
            scanNull().flatMap({ tokens.append($0) })
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
            case .beginArray:
                var arrayName: String?
                let nameIndex = next - 2
                if nameIndex >= 0 {
                    if let nameToken = tokens[coolie_safe: nameIndex] {
                        if case .string(let name) = nameToken {
                            arrayName = name.capitalized
                        }
                    }
                }
                next += 1
                return parseArray(name: arrayName)
            case .beginObject:
                next += 1
                return parseObject()
            case .bool:
                return parseBool()
            case .number:
                return parseNumber()
            case .string:
                return parseString()
            case .null:
                return parseNull()
            default:
                return nil
            }
        }

        func parseArray(name: String? = nil) -> Value? {
            guard let token = tokens[coolie_safe: next] else {
                print("No token for parseArray")
                return nil
            }
            var array = [Value]()
            if case .endArray = token {
                next += 1
                return .array(name: name, values: array)
            } else {
                while true {
                    guard let value = parseValue() else {
                        break
                    }
                    array.append(value)
                    if let token = tokens[coolie_safe: next] {
                        if case .endArray = token {
                            next += 1
                            return .array(name: name, values: array)
                        } else {
                            guard let _ = parseComma() else {
                                print("Expect comma")
                                break
                            }
                            guard let nextToken = tokens[coolie_safe: next], nextToken.isNotEndArray else {
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
            if case .endObject = token {
                next += 1
                return .dictionary(dictionary)
            } else {
                while true {
                    guard let key = parseString(), let _ = parseColon(), let value = parseValue() else {
                        print("Expect key : value")
                        break
                    }
                    if case .string(let key) = key {
                        dictionary[key] = value
                    }
                    if let token = tokens[coolie_safe: next] {
                        if case .endObject = token {
                            next += 1
                            return .dictionary(dictionary)
                        } else {
                            guard let _ = parseComma() else {
                                print("Expect comma")
                                break
                            }
                            guard let nextToken = tokens[coolie_safe: next], nextToken.isNotEndObject else {
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
            if case .colon(let string) = token {
                return .string(string)
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
            if case .comma(let string) = token {
                return .string(string)
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
            if case .bool(let bool) = token {
                return .bool(bool)
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
            if case .number(let number) = token {
                switch number {
                case .int(let int):
                    return .number(.int(int))
                case .double(let double):
                    return .number(.double(double))
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
            if case .string(let string) = token {
                return .string(string)
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
            if case .null = token {
                return .null(nil)
            }
            return nil
        }

        return parseValue()
    }
}

private extension Coolie.Token {

    var isNotEndObject: Bool {
        switch self {
        case .endObject:
            return false
        default:
            return true
        }
    }

    var isNotEndArray: Bool {
        switch self {
        case .endArray:
            return false
        default:
            return true
        }
    }
}

private extension Array {

    subscript (coolie_safe index: Int) -> Element? {
        return indices ~= index ? self[index] : nil
    }
}

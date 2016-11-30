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
        guard let value = parse()?.upgraded else {
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

    fileprivate struct TokenLocation {
        let location: Int

        func description(in scanner: Scanner) -> String {
            let string = scanner.string as NSString
            let subString = string.substring(to: location)
            let components = subString.components(separatedBy: "\n")
            guard !components.isEmpty else { return "[line \(1)]" }
            let fullComponents = string.components(separatedBy: "\n")
            let lastIndex = components.count - 1
            let lineNumber: Int
            if components[lastIndex] == fullComponents[lastIndex] {
                lineNumber = lastIndex + 1
            } else {
                lineNumber = lastIndex + 1
            }
            let line = fullComponents[lineNumber - 1]
            return "[line \(lineNumber): `\(line)`]"
        }

        init(_ location: Int) {
            self.location = location
        }
    }

    public enum Value {
        case bool(Bool)
        public enum NumberType {
            case int(Int)
            case double(Double)
        }
        case number(NumberType)
        case string(String)
        // hyper string
        case url(URL)
        public enum DateType {
            case iso8601
            case dateOnly
        }
        case date(DateType)
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

    private func generateTokens() -> ([Token], [TokenLocation]) {

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
        var tokenLocations = [TokenLocation]()
        func appendToken(_ token: Token) {
            tokens.append(token)
            tokenLocations.append(TokenLocation(scanner.scanLocation))
        }
        while !scanner.isAtEnd {
            let previousScanLocation = scanner.scanLocation
            scanBeginObject().flatMap({ appendToken($0) })
            scanEndObject().flatMap({ appendToken($0) })
            scanBeginArray().flatMap({ appendToken($0) })
            scanEndArray().flatMap({ appendToken($0) })
            scanColon().flatMap({ appendToken($0) })
            scanComma().flatMap({ appendToken($0) })
            scanBool().flatMap({ appendToken($0) })
            scanNumber().flatMap({ appendToken($0) })
            scanString().flatMap({ appendToken($0) })
            scanNull().flatMap({ appendToken($0) })
            let currentScanLocation = scanner.scanLocation
            guard currentScanLocation > previousScanLocation else {
                print("Not found valid token: \(TokenLocation(currentScanLocation).description(in: scanner))")
                return ([], [])
            }
        }
        return (tokens, tokenLocations)
    }

    private func parse() -> Value? {

        let (tokens, tokenLocations) = generateTokens()
        guard !tokens.isEmpty else {
            print("No tokens")
            return nil
        }

        var next = 0

        func parseValue() -> Value? {
            guard let token = tokens[coolie_safe: next] else {
                print("No token for parseValue: \(tokenLocations[next].description(in: scanner))")
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
                print("No token for parseArray: \(tokenLocations[next].description(in: scanner))")
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
                                print("Expect comma: \(tokenLocations[next >= 2 ? next - 2 : next].description(in: scanner))")
                                break
                            }
                            guard let nextToken = tokens[coolie_safe: next], nextToken.isNotEndArray else {
                                print("Invalid JSON, comma at end of array: \(tokenLocations[next].description(in: scanner))")
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
                print("No token for parseObject: \(tokenLocations[next].description(in: scanner))")
                return nil
            }
            var dictionary = [String: Value]()
            if case .endObject = token {
                next += 1
                return .dictionary(dictionary)
            } else {
                while true {
                    guard let key = parseString(), let _ = parseColon(), let value = parseValue() else {
                        print("Expect `key : value`: \(tokenLocations[next].description(in: scanner))")
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
                                print("Expect comma: \(tokenLocations[next >= 2 ? next - 2 : next].description(in: scanner))")
                                break
                            }
                            guard let nextToken = tokens[coolie_safe: next], nextToken.isNotEndObject else {
                                print("Invalid JSON, comma at end of object: \(tokenLocations[next >= 1 ? next - 1 : next].description(in: scanner))")
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
                print("No token for parseColon: \(tokenLocations[next].description(in: scanner))")
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
                print("No token for parseComma: \(tokenLocations[next].description(in: scanner))")
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
                print("No token for parseBool: \(tokenLocations[next].description(in: scanner))")
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
                print("No token for parseNumber: \(tokenLocations[next].description(in: scanner))")
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
                print("No token for parseString: \(tokenLocations[next].description(in: scanner))")
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
                print("No token for parseNull: \(tokenLocations[next].description(in: scanner))")
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

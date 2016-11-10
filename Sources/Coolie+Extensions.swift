//
//  Coolie+Extensions.swift
//  Coolie
//
//  Created by NIX on 16/11/3.
//  Copyright © 2016年 nixWork. All rights reserved.
//

import Foundation

extension Coolie.Value {

    var type: String {
        switch self {
        case .bool:
            return "Bool"
        case .number(let number):
            switch number {
            case .int:
                return "Int"
            case .double:
                return "Double"
            }
        case .string:
            return "String"
        case .url:
            return "URL"
        case .null(let value):
            if let value = value {
                return "\(value.type)?"
            } else {
                return "UnknownType?"
            }
        default:
            fatalError("no type for: \(self)")
        }
    }
}

extension Coolie.Value {

    func indent(with level: Int, into string: inout String) {
        for _ in 0..<level {
            string += "\t"
        }
    }

    enum OrdinaryPropertyType {
        case normal
        case normalInArray
        case optionalInArray
    }
}

extension Coolie.Value {

    var isDictionaryOrArray: Bool {
        switch self {
        case .dictionary:
            return true
        case .array:
            return true
        default:
            return false
        }
    }

    var isDictionary: Bool {
        switch self {
        case .dictionary:
            return true
        default:
            return false
        }
    }

    var isArray: Bool {
        switch self {
        case .array:
            return true
        default:
            return false
        }
    }

    var isHyperString: Bool {
        switch self {
        case .url:
            return true
        default:
            return false
        }
    }

    var isNull: Bool {
        switch self {
        case .null:
            return true
        default:
            return false
        }
    }
}

extension Coolie.Value {

    private func union(_ otherValue: Coolie.Value) -> Coolie.Value {
        switch (self, otherValue) {
        case (.null(let aOptionalValue), .null(let bOptionalValue)):
            switch (aOptionalValue, bOptionalValue) {
            case (.some(let a), .some(let b)):
                return .null(a.union(b))
            case (.some(let a), .none):
                return .null(a)
            case (.none, .some(let b)):
                return .null(b)
            case (.none, .none):
                return .null(nil)
            }
        case (.null(let value), let bValue):
            if let aValue = value {
                return .null(.some(aValue.union(bValue)))
            } else {
                return .null(.some(bValue))
            }
        case (let aValue, .null(let value)):
            if let bValue = value {
                return .null(.some(bValue.union(aValue)))
            } else {
                return .null(.some(aValue))
            }
        case (.bool, .bool):
            return .bool(true)
        case (.number(let aNumber), .number(let bNumber)):
            switch (aNumber, bNumber) {
            case (.int, .int):
                return .number(.int(1))
            default:
                return .number(.double(1.0))
            }
        case (.string(let s1), .string(let s2)):
            if let url = URL(string: s1), url.host != nil {
                return .url(url)
            } else if let url = URL(string: s2), url.host != nil {
                return .url(url)
            } else {
                let string = s1.isEmpty ? s2 : s1
                return .string(string)
            }
        case (.dictionary(let aInfo), .dictionary(let bInfo)):
            var info = aInfo
            for key in aInfo.keys {
                guard let aValue = aInfo[key] else { fatalError() }
                if let bValue = bInfo[key] {
                    info[key] = aValue.union(bValue)
                } else {
                    info[key] = .null(aValue)
                }
            }
            for key in bInfo.keys {
                guard let bValue = bInfo[key] else { fatalError() }
                if let aValue = aInfo[key] {
                    info[key] = bValue.union(aValue)
                } else {
                    info[key] = .null(bValue)
                }
            }
            return .dictionary(info)
        case (let .array(aName, aValues), let .array(bName, bValues)):
            let values = (aValues + bValues)
            if let first = values.first {
                let value = values.dropFirst().reduce(first, { $0.union($1) })
                return .array(name: aName ?? bName, values: [value])
            } else {
                return .array(name: aName ?? bName, values: [])
            }
        default:
            fatalError("Unsupported union!")
        }
    }

    func unionValues(_ values: [Coolie.Value]) -> Coolie.Value? {
        if let first = values.first {
            return values.dropFirst().reduce(first, { $0.union($1) })
        } else {
            return nil
        }
    }
}

extension String {

    var coolie_dropLastCharacter: String {
        if characters.count > 0 {
            return String(characters.dropLast())
        }
        return self
    }

    var coolie_lowerCamelCase: String {
        var symbolSet = CharacterSet.alphanumerics
        symbolSet.formUnion(CharacterSet(charactersIn: "_"))
        symbolSet.invert()
        let validString = self.components(separatedBy: symbolSet).joined(separator: "_")
        let parts = validString.components(separatedBy: "_")
        return parts.enumerated().map({ index, part in
            return index == 0 ? part : part.capitalized
        }).joined(separator: "")
    }
}

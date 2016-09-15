//
//  Coolie.swift
//  Coolie
//
//  Created by NIX on 16/5/14.
//  Copyright © 2016年 nixWork. All rights reserved.
//

final public class Arguments {

    public enum Option: CustomStringConvertible {
        case Short(key: String)
        case Long(key: String)
        case Mixed(shortKey: String, longKey: String)

        public var description: String {
            switch self {
            case .Short(let key):
                return "-" + key
            case .Long(let key):
                return "--" + key
            case .Mixed(let shortKey, let longKey):
                return "-" + shortKey + ", " + "--" + longKey
            }
        }
    }

    enum Value {
        case None
        case Exist(String)

        var value: String? {
            switch self {
            case .None:
                return nil
            case .Exist(let string):
                return string
            }
        }
    }

    let keyValues: [String: Value]

    public init(_ arguments: [String]) {

        guard arguments.count > 1 else {
            self.keyValues = [:]
            return
        }

        var keyValues = [String: Value]()

        var i = 1

        while true {
            let _a = arguments[arguments_safe: i]
            let _b = arguments[arguments_safe: i + 1]

            guard let a = _a else { break }

            if a.arguments_isKey {
                if let b = _b, !b.arguments_isKey {
                    keyValues[a] = Value.Exist(b)

                } else {
                    keyValues[a] = Value.None
                }
            } else {
                print("Invalid argument: \(a)")
                break
            }

            if let b = _b {
                if b.arguments_isKey {
                    i += 1
                } else {
                    i += 2
                }
            } else {
                break
            }
        }

        self.keyValues = keyValues
    }

    public func containsOption(_ option: Option) -> Bool {

        switch option {
        case .Short(let key):
            return keyValues["-" + key] != nil
        case .Long(let key):
            return keyValues["--" + key] != nil
        case .Mixed(let shortKey, let longKey):
            return (keyValues["-" + shortKey] != nil) || (keyValues["--" + longKey] != nil)
        }
    }

    public func containsOptions(_ options: [Option]) -> Bool {

        return options.reduce(true, { $0 && containsOption($1) })
    }

    public func valueOfOption(_ option: Option) -> String? {

        switch option {
        case .Short(let key):
            return keyValues["-" + key]?.value
        case .Long(let key):
            return keyValues["--" + key]?.value
        case .Mixed(let shortKey, let longKey):
            let shortKeyValue = keyValues["-" + shortKey]?.value
            let longKeyValue = keyValues["--" + longKey]?.value
            if let shortKeyValue = shortKeyValue, let longKeyValue = longKeyValue {
                guard shortKeyValue == longKeyValue else {
                    fatalError("Duplicate value for option: \(option)")
                }
            }
            return shortKeyValue ?? longKeyValue
        }
    }
}

private extension String {

    var arguments_isLongKey: Bool {
        return hasPrefix("--")
    }

    var arguments_isShortKey: Bool {
        return !arguments_isLongKey && hasPrefix("-")
    }

    var arguments_isKey: Bool {
        return arguments_isLongKey || arguments_isShortKey
    }
}

private extension Array {

    subscript (arguments_safe index: Int) -> Element? {
        return indices ~= index ? self[index] : nil
    }
}

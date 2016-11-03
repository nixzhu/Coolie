//
//  main.swift
//  Coolie
//
//  Created by NIX on 16/1/4.
//  Copyright © 2016年 nixWork. All rights reserved.
//

import Foundation

func main(_ arguments: [String]) {

    let arguments = Arguments(arguments)

    let inputFilePathOption = Arguments.Option.Mixed(shortKey: "i", longKey: "input-file-path")
    let modelNameOption = Arguments.Option.Long(key: "model-name")

    guard let inputFilePath = arguments.valueOfOption(inputFilePathOption), let modelName = arguments.valueOfOption(modelNameOption) else {
        print("Usage: $ coolie -i JSONFilePath --model-name ModelName")
        return
    }

    let fileManager = FileManager.default

    guard fileManager.fileExists(atPath: inputFilePath) else {
        print("File NOT found at \(inputFilePath)")
        return
    }

    guard fileManager.isReadableFile(atPath: inputFilePath) else {
        print("No permission to read file at \(inputFilePath)")
        return
    }

    guard let data = fileManager.contents(atPath: inputFilePath) else {
        print("File is empty!")
        return
    }

    guard let jsonString = String(data: data, encoding: .utf8) else {
        print("File is NOT encoding with UTF8!")
        return
    }

    let coolie = Coolie(jsonString)

    let argumentLabelOption = Arguments.Option.Long(key: "argument-label")
    let argumentLabel = arguments.valueOfOption(argumentLabelOption)

    let constructorNameOption = Arguments.Option.Long(key: "constructor-name")
    let constructorName = arguments.valueOfOption(constructorNameOption)

    let jsonDictionaryNameOption = Arguments.Option.Long(key: "json-dictionary-name")
    let jsonDictionaryName = arguments.valueOfOption(jsonDictionaryNameOption)

    let debugOption = Arguments.Option.Long(key: "debug")
    let debug = arguments.containsOption(debugOption)

    let modelTypeOption = Arguments.Option.Long(key: "model-type")
    let modelTypeRawValue = arguments.valueOfOption(modelTypeOption)?.lowercased()
    let modelType = modelTypeRawValue.flatMap({ Coolie.ModelType(rawValue: $0) }) ?? Coolie.ModelType.struct

    let model = coolie.generateModel(
        name: modelName,
        type: modelType,
        argumentLabel: argumentLabel,
        constructorName: constructorName,
        jsonDictionaryName: jsonDictionaryName,
        debug: debug
    )

    model.flatMap({ print($0) })
}

main(CommandLine.arguments)

struct User {
    struct Detail {
        let age: Int
        let dailyFantasyHours: [Double]
        let gender: Bool?
        let isDogLover: Bool
        let motto: String
        let skills: [String]
        init?(_ info: [String: Any]) {
            guard let age = info["age"] as? Int else { return nil }
            guard let dailyFantasyHours = info["daily_fantasy_hours"] as? [Double] else { return nil }
            let gender = info["gender"] as? Bool
            guard let isDogLover = info["is_dog_lover"] as? Bool else { return nil }
            guard let motto = info["motto"] as? String else { return nil }
            guard let skills = info["skills"] as? [String] else { return nil }
            self.age = age
            self.dailyFantasyHours = dailyFantasyHours
            self.gender = gender
            self.isDogLover = isDogLover
            self.motto = motto
            self.skills = skills
        }
    }
    let detail: Detail
    let name: String
    struct Project {
        struct More {
            let code: String
            let design: String?
            init?(_ info: [String: Any]) {
                guard let code = info["code"] as? String else { return nil }
                let design = info["design"] as? String
                self.code = code
                self.design = design
            }
        }
        let more: More
        let name: String?
        let url: String
        init?(_ info: [String: Any]) {
            guard let moreJSONDictionary = info["more"] as? [String: Any] else { return nil }
            guard let more = More(moreJSONDictionary) else { return nil }
            let name = info["name"] as? String
            guard let url = info["url"] as? String else { return nil }
            self.more = more
            self.name = name
            self.url = url
        }
    }
    let projects: [Project]
    init?(_ info: [String: Any]) {
        guard let detailJSONDictionary = info["detail"] as? [String: Any] else { return nil }
        guard let detail = Detail(detailJSONDictionary) else { return nil }
        guard let name = info["name"] as? String else { return nil }
        guard let projectsJSONArray = info["projects"] as? [[String: Any]] else { return nil }
        let projects = projectsJSONArray.map({ Project($0) }).flatMap({ $0 })
        self.detail = detail
        self.name = name
        self.projects = projects
    }
}

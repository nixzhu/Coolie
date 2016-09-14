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

    guard FileManager.default.fileExists(atPath: inputFilePath) else {
        print("File NOT found at \(inputFilePath)")
        return
    }

    guard FileManager.default.isReadableFile(atPath: inputFilePath) else {
        print("No permission to read file at \(inputFilePath)")
        return
    }

    guard let data = FileManager.default.contents(atPath: inputFilePath) else {
        print("File is empty!")
        return
    }

    guard let jsonString = String(data: data, encoding: .utf8) else {
        print("File is NOT encoding with UTF8!")
        return
    }

    let coolie = Coolie(jsonString)

    let modelTypeOption = Arguments.Option.Long(key: "model-type")

    let constructorNameOption = Arguments.Option.Long(key: "constructor-name")
    let constructorName = arguments.valueOfOption(constructorNameOption)

    let debugOption = Arguments.Option.Long(key: "debug")
    let debug = arguments.containsOption(debugOption)

    if let modelType = arguments.valueOfOption(modelTypeOption)?.lowercased() {
        if let type = Coolie.ModelType(rawValue: modelType.lowercased()) {
            if let model = coolie.generateModel(name: modelName, type: type, constructorName: constructorName, debug: debug) {
                print(model)
                return
            }
        }

    } else {
        if let model = coolie.generateModel(name: modelName, type: Coolie.ModelType.struct, constructorName: constructorName, debug: debug) {
            print(model)
            return
        }
    }
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
        init?(_ info: [String: AnyObject]) {
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
        let description: String
        let name: String
        let url: String
        init?(_ info: [String: AnyObject]) {
            guard let description = info["description"] as? String else { return nil }
            guard let name = info["name"] as? String else { return nil }
            guard let url = info["url"] as? String else { return nil }
            self.description = description
            self.name = name
            self.url = url
        }
    }
    let projects: [Project]
    init?(_ info: [String: AnyObject]) {
        guard let detailJSONDictionary = info["detail"] as? [String: AnyObject] else { return nil }
        guard let detail = Detail(detailJSONDictionary) else { return nil }
        guard let name = info["name"] as? String else { return nil }
        guard let projectsJSONArray = info["projects"] as? [[String: AnyObject]] else { return nil }
        let projects = projectsJSONArray.map({ Project($0) }).flatMap({ $0 })
        self.detail = detail
        self.name = name
        self.projects = projects
    }
}

struct User2 {
    struct Detail {
        let age: Int
        let dailyFantasyHours: [Double]
        let gender: Bool?
        let isDogLover: Bool
        let motto: String
        let skills: [String]
        static func fromJSONDictionary(_ info: [String: AnyObject]) -> Detail? {
            guard let age = info["age"] as? Int else { return nil }
            guard let dailyFantasyHours = info["daily_fantasy_hours"] as? [Double] else { return nil }
            let gender = info["gender"] as? Bool
            guard let isDogLover = info["is_dog_lover"] as? Bool else { return nil }
            guard let motto = info["motto"] as? String else { return nil }
            guard let skills = info["skills"] as? [String] else { return nil }
            return Detail(age: age, dailyFantasyHours: dailyFantasyHours, gender: gender, isDogLover: isDogLover, motto: motto, skills: skills)
        }
    }
    let detail: Detail
    let name: String
    struct Project {
        let description: String
        let name: String
        let url: String
        static func fromJSONDictionary(_ info: [String: AnyObject]) -> Project? {
            guard let description = info["description"] as? String else { return nil }
            guard let name = info["name"] as? String else { return nil }
            guard let url = info["url"] as? String else { return nil }
            return Project(description: description, name: name, url: url)
        }
    }
    let projects: [Project]
    static func fromJSONDictionary(_ info: [String: AnyObject]) -> User2? {
        guard let detailJSONDictionary = info["detail"] as? [String: AnyObject] else { return nil }
        guard let detail = Detail.fromJSONDictionary(detailJSONDictionary) else { return nil }
        guard let name = info["name"] as? String else { return nil }
        guard let projectsJSONArray = info["projects"] as? [[String: AnyObject]] else { return nil }
        let projects = projectsJSONArray.map({ Project.fromJSONDictionary($0) }).flatMap({ $0 })
        return User2(detail: detail, name: name, projects: projects)
    }
}

class User3 {
    class Detail {
        var age: Int
        var dailyFantasyHours: [Double]
        var gender: Bool?
        var isDogLover: Bool
        var motto: String
        var skills: [String]
        init?(_ info: [String: AnyObject]) {
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
    var detail: Detail
    var name: String
    class Project {
        var description: String
        var name: String
        var url: String
        init?(_ info: [String: AnyObject]) {
            guard let description = info["description"] as? String else { return nil }
            guard let name = info["name"] as? String else { return nil }
            guard let url = info["url"] as? String else { return nil }
            self.description = description
            self.name = name
            self.url = url
        }
    }
    var projects: [Project]
    init?(_ info: [String: AnyObject]) {
        guard let detailJSONDictionary = info["detail"] as? [String: AnyObject] else { return nil }
        guard let detail = Detail(detailJSONDictionary) else { return nil }
        guard let name = info["name"] as? String else { return nil }
        guard let projectsJSONArray = info["projects"] as? [[String: AnyObject]] else { return nil }
        let projects = projectsJSONArray.map({ Project($0) }).flatMap({ $0 })
        self.detail = detail
        self.name = name
        self.projects = projects
    }
}

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

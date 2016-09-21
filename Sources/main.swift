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

    let constructorNameOption = Arguments.Option.Long(key: "constructor-name")
    let constructorName = arguments.valueOfOption(constructorNameOption)

    let jsonDictionaryNameOption = Arguments.Option.Long(key: "json-dictionary-name")
    let jsonDictionaryName = arguments.valueOfOption(jsonDictionaryNameOption)

    let debugOption = Arguments.Option.Long(key: "debug")
    let debug = arguments.containsOption(debugOption)

    let modelTypeOption = Arguments.Option.Long(key: "model-type")
    let modelTypeRawValue = arguments.valueOfOption(modelTypeOption)?.lowercased()
    let modelType = modelTypeRawValue.flatMap({ Coolie.ModelType(rawValue: $0) }) ?? Coolie.ModelType.struct

    let model = coolie.generateModel(name: modelName, type: modelType, constructorName: constructorName, jsonDictionaryName: jsonDictionaryName, debug: debug)

    model.flatMap({ print($0) })
}

main(CommandLine.arguments)

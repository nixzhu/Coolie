//
//  main.swift
//  Coolie
//
//  Created by NIX on 16/1/4.
//  Copyright © 2016年 nixWork. All rights reserved.
//

import Foundation

func main(arguments: [String]) {

    let arguments = Arguments(arguments)

    let inputFilePathOption = Arguments.Option.Mixed(shortKey: "i", longKey: "input-file-path")
    let modelNameOption = Arguments.Option.Long(key: "model-name")

    guard let inputFilePath = arguments.valueOfOption(inputFilePathOption), modelName = arguments.valueOfOption(modelNameOption) else {
        print("Usage: $ coolie -i JSONFilePath --model-name ModelName")
        return
    }

    guard NSFileManager.defaultManager().fileExistsAtPath(inputFilePath) else {
        print("File NOT found at \(inputFilePath)")
        return
    }

    guard NSFileManager.defaultManager().isReadableFileAtPath(inputFilePath) else {
        print("No permission to read file at \(inputFilePath)")
        return
    }

    guard let data = NSFileManager.defaultManager().contentsAtPath(inputFilePath) else {
        print("File is empty!")
        return
    }

    guard let jsonString = String(data: data, encoding: NSUTF8StringEncoding) else {
        print("File is NOT encoding with UTF8!")
        return
    }

    let coolie = Coolie(jsonString)

    let modelTypeOption = Arguments.Option.Long(key: "model-type")

    if let modelType = arguments.valueOfOption(modelTypeOption) {
        if let type = Coolie.ModelType(rawValue: modelType.lowercaseString) {
            if let model = coolie.generateModel(name: modelName, type: type) {
                print(model)
                return
            }
        }

    } else {
        if let model = coolie.generateModelWithName(modelName) {
            print(model)
            return
        }
    }
}

main(Process.arguments)

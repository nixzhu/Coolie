//
//  main.swift
//  Coolie
//
//  Created by NIX on 16/1/4.
//  Copyright © 2016年 nixWork. All rights reserved.
//

import Foundation

func main(arguments: [String]) {

    guard arguments.count == 3 else {
        print("Usage: $ coolie JSONFileName ModelName")
        return
    }

    let path = arguments[1]
    guard NSFileManager.defaultManager().fileExistsAtPath(path) else {
        print("File NOT found at \(path)")
        return
    }

    guard NSFileManager.defaultManager().isReadableFileAtPath(path) else {
        print("No permission to read file at \(path)")
        return
    }

    guard let data = NSFileManager.defaultManager().contentsAtPath(path) else {
        print("File is empty!")
        return
    }

    guard let JSONString = String(data: data, encoding: NSUTF8StringEncoding) else {
        print("File is NOT encoding with UTF8!")
        return
    }

    let coolie = Coolie(JSONString: JSONString)
    let modelName = arguments[2]
    coolie.printModelWithName(modelName)
}

main(Process.arguments)

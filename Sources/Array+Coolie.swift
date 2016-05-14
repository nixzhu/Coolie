//
//  Coolie.swift
//  Coolie
//
//  Created by NIX on 16/5/14.
//  Copyright © 2016年 nixWork. All rights reserved.
//

extension Array {

    subscript (safe index: Int) -> Element? {
        return index >= 0 && index < count ? self[index] : nil
    }
}

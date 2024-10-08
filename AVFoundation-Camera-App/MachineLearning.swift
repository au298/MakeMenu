//
//  MachineLearning.swift
//  MakeMenu
//
//  Created by 古田聖直 on 2024/08/27.
//

import Foundation

class MachineLearningDummy: MachineLearningDelegate {
    func machineLearning(image: Data) -> [String] {
        let ingredientSets = [
            ["ジャガイモ", "にんじん", "玉ねぎ"],
            ["みそ", "豆腐", "わかめ"],
            ["ご飯", "玉ねぎ", "卵"]
        ]

        let randomIndex = Int.random(in: 0..<ingredientSets.count)
        return ingredientSets[randomIndex]
    }
}


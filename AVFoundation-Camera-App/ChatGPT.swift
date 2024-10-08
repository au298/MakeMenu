//
//  ChatGPT.swift
//  MakeMenu
//
//  Created by 古田聖直 on 2024/08/27.
//

import Foundation

// ChatGPTクラス
class ChatGPT: ChatGPTDelegate {
    func fetchIdea(from prompt: String) async -> String {
        if prompt.contains("ジャガイモ") && prompt.contains("にんじん") && prompt.contains("玉ねぎ") {
            return "カレーライス"
        } else if prompt.contains("みそ") && prompt.contains("豆腐") && prompt.contains("わかめ") {
            return "味噌汁"
        } else if prompt.contains("ご飯") && prompt.contains("玉ねぎ") && prompt.contains("卵") {
            return "チャーハン"
        } else {
            return "該当する料理が見つかりませんでした"
        }
    }
}

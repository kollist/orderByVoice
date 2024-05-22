//
//  File.swift
//  VoiceOrderingAssistant
//
//  Created by Zaytech Mac on 13/5/2024.
//

import UIKit

class Message {
    private let conversationID: Int
    private let messageSender: String
    private let messageText: String
    private let timeStamp: Date
    private let icon: UIImage
    
    
    init(_ messageSender: String, _ messageText: String, _ conversationID: Int, _ icon: UIImage) {
        self.conversationID = conversationID
        self.messageSender = messageSender
        self.messageText = messageText
        self.timeStamp = Date()
        self.icon = icon
    }
    
    public func getMessage() -> [String:Any] {
        return [
            "sender": messageSender,
            "message": messageText,
            "timeStamp": timeStamp,
            "icon": icon
        ]
    }
    
}

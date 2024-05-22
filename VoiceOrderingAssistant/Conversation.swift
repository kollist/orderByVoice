//
//  Conversation.swift
//  VoiceOrderingAssistant
//
//  Created by Zaytech Mac on 13/5/2024.
//

import Foundation


class Conversation {
    private let conversationID: Int
    private var messages: [Message]
    private var conversationName: String
    private let timestamp: Date
    
    init(messages: [Message], conversationName: String, conversationID: Int) {
        self.messages = messages
        self.conversationID = conversationID
        self.conversationName = conversationName
        self.timestamp = Date()
    }
    
    public func getMessages() -> [Message] {
        return messages
    }
    public func addAMessage(_ message: Message) {
        messages.append(message)
    }
    public func setConversationName(_ newName: String) {
        conversationName = newName
    }
    public func getConversationName() -> String {
        return conversationName
    }
    
}

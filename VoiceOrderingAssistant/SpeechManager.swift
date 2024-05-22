//
//  SpeechManager.swift
//  VoiceOrderingAssistant
//
//  Created by Zaytech Mac on 15/5/2024.
//

import Foundation
import UIKit
import Speech


class SpeechManager: NSObject {
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    
    func transcribeAudioFile(at url: URL, completion: @escaping (String?, Error?) -> Void) {
        let recognitionRequest = SFSpeechURLRecognitionRequest(url: url)
        
        speechRecognizer?.recognitionTask(with: recognitionRequest) { (result, error) in
            if let result = result {
                let recognizedText = result.bestTranscription.formattedString
                
                if result.isFinal {
                    completion(recognizedText, nil) // Handle the final recognized text
                }
            } else if let error = error {
                completion(nil, error)
            }
        }
    }
}

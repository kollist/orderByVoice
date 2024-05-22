//
//  MessageCell.swift
//  VoiceOrderingAssistant
//
//  Created by Zaytech Mac on 13/5/2024.
//

import Foundation
import UIKit
import AVFAudio


class MessageCell: UITableViewCell, AVSpeechSynthesizerDelegate {
    private var synthesizer: AVSpeechSynthesizer?
    private var audioRecorder: AVAudioRecorder?
    static var identifier = "messageCell"
    private var isReading = false
    override class func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        synthesizer = AVSpeechSynthesizer()
        setupUI()
    }

    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private lazy var messagerLogo: UIImageView = {
        let img = UIImageView()
        img.translatesAutoresizingMaskIntoConstraints = false
        
        return img
    }()
    
    private lazy var senderLabel: UILabel = {
        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.textAlignment = .left
        lbl.baselineAdjustment = .alignCenters
        lbl.font = UIFont.boldSystemFont(ofSize: 16)
        return lbl
    }()
    private lazy var messageContent: UILabel = {
        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.textAlignment = .left
        lbl.font = UIFont.systemFont(ofSize: 15)
        lbl.numberOfLines = 0
        return lbl
    }()
    
    private lazy var userContent: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = true
        return view
    }()
    
    private lazy var spacingView: UIView = {
       let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .red
        return view
    }()
    
    
    private lazy var readTextButton: UIButton = {
        let btn = UIButton()
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.isUserInteractionEnabled = true
        btn.layer.cornerRadius = 14
        btn.setImage(UIImage(systemName: "speaker.wave.2.fill"), for: .normal)
        btn.tintColor = .black
        btn.layer.zPosition = 1000
        btn.addTarget(self, action: #selector(readMessage), for: .touchUpInside)
        
        return btn
    }()
    
    @objc func readMessage(_ sender: UIButton) {
        if self.isReading {
            readTextButton.setImage(UIImage(systemName: "speaker.wave.2.fill"), for: .normal)
            return
        }
        if let text = messageContent.text {
            let result = convertTextToSpeech(text)
            if result {
                self.isReading = true
                sender.setImage(UIImage(systemName: "pause.fill"), for: .normal)
            }
        }
        
    }
    
    func setupUI() {
        contentView.backgroundColor = .clear
        contentView.addSubview(userContent)
        contentView.addSubview(spacingView)
        userContent.addSubview(messagerLogo)
        userContent.addSubview(senderLabel)
        userContent.addSubview(readTextButton)
        contentView.addSubview(messageContent)
        
        contentView.backgroundColor = .clear
        
        NSLayoutConstraint.activate([
            // Update the constraints to use `contentView` instead of `self`
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            spacingView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            spacingView.heightAnchor.constraint(equalToConstant: 20),
            spacingView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            
            userContent.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            userContent.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            userContent.topAnchor.constraint(equalTo: contentView.topAnchor),
            userContent.heightAnchor.constraint(equalToConstant: 28),
            
            messagerLogo.widthAnchor.constraint(equalToConstant: 28),
            messagerLogo.heightAnchor.constraint(equalToConstant: 28),
            messagerLogo.leadingAnchor.constraint(equalTo: userContent.leadingAnchor),
            messagerLogo.centerYAnchor.constraint(equalTo: userContent.centerYAnchor),
            
            readTextButton.trailingAnchor.constraint(equalTo: userContent.trailingAnchor),
            readTextButton.topAnchor.constraint(equalTo: readTextButton.topAnchor),
            readTextButton.widthAnchor.constraint(equalToConstant: 28),
            readTextButton.heightAnchor.constraint(equalToConstant: 28),
            
            senderLabel.leadingAnchor.constraint(equalTo: messagerLogo.trailingAnchor, constant: 10),
            senderLabel.topAnchor.constraint(equalTo: userContent.topAnchor),
            senderLabel.bottomAnchor.constraint(equalTo: userContent.bottomAnchor),
            senderLabel.heightAnchor.constraint(equalTo: userContent.heightAnchor),
            
            messageContent.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 38),
            messageContent.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            messageContent.topAnchor.constraint(equalTo: userContent.bottomAnchor),
            messageContent.bottomAnchor.constraint(equalTo: spacingView.topAnchor),
        ])
    }
    
    // MARK: - Text To Speech
    func convertTextToSpeech(_ text: String) -> Bool {
        
        do {
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .voicePrompt, options: [])
            try AVAudioSession().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error.localizedDescription)")
        }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.volume = 100.0
        let voices = AVSpeechSynthesisVoice.speechVoices()
        
        let desiredVoiceIdentifier = "com.apple.ttsbundle.siri_Nicky_en-US_compact"
        if let desiredVoice = voices.first(where: { $0.identifier == desiredVoiceIdentifier }) {
            utterance.voice = desiredVoice
            utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        } else {
            print("Desired voice not found")
            return false
        }
        
        synthesizer?.delegate = self
        synthesizer?.speak(utterance)
        return true
        
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        let mutableAttributedString = NSMutableAttributedString(string: utterance.speechString)
        mutableAttributedString.addAttribute(.backgroundColor, value: UIColor.systemBlue, range: characterRange)
        mutableAttributedString.addAttribute(.foregroundColor, value: UIColor.white, range: characterRange)
        messageContent.attributedText = mutableAttributedString
    }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        messageContent.attributedText = NSAttributedString(string: utterance.speechString)
        if let readTextButton = userContent.subviews.first(where: { $0 is UIButton }) as? UIButton {
            readTextButton.setImage(UIImage(systemName: "speaker.wave.2.fill"), for: .normal)
        }
        self.isReading = false
    }
    
    func config(_ message: Message) {
        if let msg = message.getMessage()["message"] as? String {
            messageContent.text = msg
        }
        if let img = message.getMessage()["icon"] as? UIImage {
            messagerLogo.image = img
        }
        if let sender = message.getMessage()["sender"] as? String {
            senderLabel.text = sender
            if sender == "You" {
                readTextButton.isHidden = true
            }
            
        }
        
    }
    
}

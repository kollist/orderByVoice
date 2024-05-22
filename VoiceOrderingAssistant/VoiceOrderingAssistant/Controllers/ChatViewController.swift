//
//  ChatViewController.swift
//  VoiceOrderingAssistant
//
//  Created by Zaytech Mac on 8/5/2024.
//

import UIKit
import PDFKit
import AVFoundation
import GoogleGenerativeAI

class ChatViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, AVSpeechSynthesizerDelegate, AVAudioRecorderDelegate, UITextViewDelegate {
    private var synthesizer: AVSpeechSynthesizer?
    private var audioRecorder: AVAudioRecorder?
    var audioLengthMax: CGFloat = 1.0
    let conversation = Conversation(messages: [], conversationName: "Conver One", conversationID: 1)
    override func viewDidLoad() {
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            if granted {
                // Permission granted, set up audio session
                DispatchQueue.main.async {
                    self.setupAudioSession()
                }
            } else {
                // Permission denied, handle accordingly
                DispatchQueue.main.async {
                    // Show an alert or update UI to indicate microphone access is denied
                }
            }
        }
        super.viewDidLoad()
        messagesTable.delegate = self
        messagesTable.dataSource = self
        messagesTable.register(MessageCell.self, forCellReuseIdentifier: MessageCell.identifier)
        messagesTable.reloadData()
        setupUI()
//        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error.localizedDescription)")
        }
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        return keyboardWillShowGlobal(notification, messagesTable, textingInput)
    }

    @objc func keyboardWillHide(_ notification: Notification) {
        return keyboardWillHideGlobal(notification, messagesTable, textingInput)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversation.getMessages().count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 20
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 20
    }
    
    
    
    private func getDocumentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: MessageCell.identifier, for: indexPath) as? MessageCell {
            cell.selectionStyle = .none
            cell.isUserInteractionEnabled = true
            let messages = conversation.getMessages()
            let rowMessage = messages[indexPath.row]
            cell.config(rowMessage)
            
            
            return cell
        }
        return UITableViewCell()
    }
    
    lazy var navBar: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(named: "MainColor")?.withAlphaComponent(0.26)
        return view
    }()
    
    lazy var logoNameView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var logo: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(named: "BotLogo")
        return imageView
    }()
    lazy var name: UILabel = {
       let lbl = UILabel()
        lbl.text = conversation.getConversationName()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.textColor = UIColor(named: "MainColor")
        lbl.font = UIFont.boldSystemFont(ofSize: 20)
        return lbl
    }()
    
    lazy var botsMenu: UIButton = {
        let btn = UIButton()
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.isUserInteractionEnabled = true
        btn.setBackgroundImage(UIImage(named: "burgerMenu"), for: .normal)
        return btn
    }()
    
    lazy var newConversation: UIButton = {
        let btn = UIButton()
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.isUserInteractionEnabled = true
        btn.setBackgroundImage(UIImage(named: "NewConversationLogo"), for: .normal)
        return btn
    }()
    
    lazy var actionsMenu: UIButton = {
        let btn = UIButton()
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.isUserInteractionEnabled = true
        btn.setBackgroundImage(UIImage(named: "actionsMenu"), for: .normal)
        btn.titleLabel?.textColor = .black
        return btn
    }()
    
    lazy var messagesTable: UITableView = {
        let table = UITableView()
        table.translatesAutoresizingMaskIntoConstraints = false
        table.separatorStyle = .none
        
        return table
    }()
    
    lazy var backgroundImage: UIImageView = {
        let bg = UIImageView(frame: view.bounds)
        bg.image = UIImage(named: "conversationBackground")
        bg.contentMode = .scaleAspectFill
        return bg
    }()
    
    lazy var textingInputView: UIView = {
        let uiview = UIView()
        uiview.translatesAutoresizingMaskIntoConstraints = false
        uiview.layer.cornerRadius = 30
        
        uiview.backgroundColor = #colorLiteral(red: 0.8901960784, green: 0.8901960784, blue: 0.8901960784, alpha: 1)
        
        return uiview
    }()
    
    lazy var textingInput: UITextView = {
        let field = UITextView()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.textColor = UIColor(hexString: "#666666")
        field.font = UIFont.systemFont(ofSize: 13)
        field.text = "Hi"
        field.backgroundColor = .clear
        field.delegate = self
        field.isScrollEnabled = true
        field.showsVerticalScrollIndicator = true
        return field
    }()
    
    
    func textViewShouldReturn(_ textView: UITextView) -> Bool {
        textView.resignFirstResponder()
        return true
    }
    
    lazy var sendButton: UIButton = {
        let btn = UIButton()
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.layer.cornerRadius = 18
        btn.backgroundColor = #colorLiteral(red: 0.9098039216, green: 0.9098039216, blue: 0.9098039216, alpha: 1)
        btn.isUserInteractionEnabled = true
        btn.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
        return btn
    }()
    
    
    
    @objc func sendMessage(_ sender: UIButton) {
        guard let msg = textingInput.text, !msg.isEmpty else { return }
        // UI feedback and disabling button
        sender.backgroundColor = UIColor(named: "MainColor")?.withAlphaComponent(0.26)
        sender.isEnabled = false
        recordButton.isEnabled = false
        
        // Create and add message
        let userImg = UIImage(named: "UserLogo")
        let newMessage = Message("You", msg, 1, userImg!)
        conversation.addAMessage(newMessage)
        sendRequestToGenerativeLanguageAPI(text: msg)
        
        // Resetting UI
        textingInput.text = "Hello"
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            sender.backgroundColor = #colorLiteral(red: 0.9098039216, green: 0.9098039216, blue: 0.9098039216, alpha: 1)
            // other UI reset operations
        }
        messagesTable.reloadData()
        view.endEditing(true)
    }

    
    func sendRequestToGenerativeLanguageAPI(text: String) {
        let config = GenerationConfig(
            temperature: 1,
            topP: 0.95,
            topK: 0,
            maxOutputTokens: 8192
        )
        guard let apiKey = ProcessInfo.processInfo.environment["API_KEY"] else {
            fatalError("Add `API_KEY` as an Environment Variable in your app's scheme.")
        }
        let model = GenerativeModel(
            name: "gemini-1.0-pro",
            apiKey: apiKey,
            generationConfig: config,
            safetySettings: [
                SafetySetting(harmCategory: .harassment, threshold: .blockMediumAndAbove),
                SafetySetting(harmCategory: .hateSpeech, threshold: .blockMediumAndAbove),
                SafetySetting(harmCategory: .sexuallyExplicit, threshold: .blockNone),
                SafetySetting(harmCategory: .dangerousContent, threshold: .blockMediumAndAbove)
            ]
        )
        let chat = model.startChat(history: getModelContents())
        Task {
            do {
                let response = try await chat.sendMessage(text)
                let messageModel = Message("ChatBot", response.text ?? "NO RESPONSE", 1, UIImage(named: "BotLogo")!)
                conversation.addAMessage(messageModel)
                messagesTable.reloadData()
                sendButton.isEnabled = true
                recordButton.isEnabled = true
            } catch {
                print(error)
            }
        }
    }

    
    func getModelContents() -> [ModelContent] {
        var context = [
            ModelContent(role: "user", parts: "Your role as a virtual ordering kiosk agent is to efficiently handle customer orders. Using the provided restaurant menu, your objective is to recognize details of the customer's order like quantity, item UUID, and price in dollars (bearing in mind that the menu prices are listed in cents). When the user finishes their order, you should organize these details into JSON format. You're welcome to ask for clarification on any aspect of the order, except for payment-related matters. If the user requests additional add-ons that aren't listed on the menu or if the item doesn't have any add-ons available, prompt them accordingly. If the user tries to order something not found on the menu, inform them accordingly. Let's ensure a seamless and accurate ordering process for our customers."),
            ModelContent(role: "model", parts: "can you provide me with the menu ?"),
            ModelContent(role: "user", parts: extractPDFPages() ?? "Nothing"),
            ModelContent(role: "model", parts: "## Welcome to Bahia Bowls! \n\nI'm Gemini, your virtual kiosk agent. I'm here to help you build your perfect order.  \n\n**What would you like to start with?** You can choose from our Superfruit Bowls, Smoothies, Toast, Salads, Wraps, Bahia Bites, or Bottled Beverages.")
          ]
        do {
            let messages = conversation.getMessages()
            for message in messages {
                let msg = message.getMessage()
                if let sdr = msg["sender"] as? String, let pts = msg["message"] as? ModelContent.Part {
                    let modelContent = try ModelContent(role: sdr, parts: pts)
                    context.append(modelContent)
                }
            }
        } catch {
            print("Error: \(error)")
        }
        return context
    }
    
    func getButtonImage(_ superview: UIButton) -> UIImageView? {
        for subview in superview.subviews {
            if let buttonSubview = subview as? UIImageView {
                return buttonSubview
            }
        }
        return nil
    }
    
    lazy var recordButton: UIButton = {
        let btn = UIButton()
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.isUserInteractionEnabled = true
        btn.backgroundColor = #colorLiteral(red: 0.9098039216, green: 0.9098039216, blue: 0.9098039216, alpha: 1)
        btn.layer.cornerRadius = 18
        btn.addTarget(self, action: #selector(recordAudioClicked), for: .touchUpInside)
        return btn
    }()
    
    @objc func recordAudioClicked(_ sender: UIButton) {
        self.view.layoutIfNeeded()
        recordAudio()
        updateView(sender)
        self.view.layoutIfNeeded()
    }
    
    private func updateView(_ sender: UIButton) {
        sender.backgroundColor = UIColor(named: "MainColor")?.withAlphaComponent(0.26)
        let superView = getButtonImage(sender)
        let img = superView?.image?.withRenderingMode(.alwaysTemplate)
        superView?.image = img
        superView?.tintColor = UIColor(named: "MainColor")
        self.view.addSubview(recordingView)
        print(conversation.getMessages())
        self.textingInputView.removeFromSuperview()
        self.messagesTable.removeFromSuperview()
        self.view.addSubview(textingInputView)
        self.view.addSubview(messagesTable)
        
        NSLayoutConstraint.activate([
             
            recordingView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            recordingView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            recordingView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            recordingView.heightAnchor.constraint(equalTo: self.view.heightAnchor, multiplier: 0.3),

            textingInputView.bottomAnchor.constraint(equalTo: self.recordingView.topAnchor, constant: -20),
            textingInputView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            textingInputView.heightAnchor.constraint(equalToConstant: 56),
            textingInputView.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.95),
            
            messagesTable.topAnchor.constraint(equalTo: self.navBar.bottomAnchor),
            messagesTable.bottomAnchor.constraint(equalTo: self.textingInputView.topAnchor),
            messagesTable.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.9),
            messagesTable.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            
            
        ])
    }
    
    lazy var recordingView: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = true
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(hexString: "#D9D9D9")
        let circle = UIView()
        circle.layer.cornerRadius = 36
        circle.translatesAutoresizingMaskIntoConstraints = false
        circle.backgroundColor = UIColor(named: "MainColor")?.withAlphaComponent(0.26)
        circle.tag = 21
        let  btn = UIButton()
        btn.isUserInteractionEnabled = true
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.titleLabel?.text = "hello"
        btn.tintColor = .blue
        btn.addTarget(self, action: #selector(stopRecording), for: .touchUpInside)
        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.text = "      Tap to stop recording"
        lbl.textColor = UIColor(hexString: "#333333")
        
        let img = UIImage(systemName: "playpause")
        let viewImage = UIImageView(image: img)
         
        let removeViewBtn = UIButton()
        removeViewBtn.isUserInteractionEnabled = true
        removeViewBtn.translatesAutoresizingMaskIntoConstraints = false
        removeViewBtn.tintColor = .gray
        removeViewBtn.setBackgroundImage(UIImage(systemName: "xmark"), for: .normal)
        removeViewBtn.addTarget(self, action: #selector(removeRecordingViewClicked), for: .touchUpInside)
        
        viewImage.translatesAutoresizingMaskIntoConstraints = false
        viewImage.tintColor = .black
        viewImage.layer.cornerRadius = 14.5
        lbl.addSubview(viewImage)
//        btn.addSubview(lbl)
//        btn.addSubview(viewImage)
//        btn.addSubview(circle)
        view.addSubview(btn)
        
        view.addSubview(audioLength)
        view.addSubview(removeViewBtn)
        
        NSLayoutConstraint.activate([
            
            removeViewBtn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            removeViewBtn.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
            
//            viewImage.topAnchor.constraint(equalTo: lbl.topAnchor),
//            viewImage.leadingAnchor.constraint(equalTo: lbl.leadingAnchor),
//            viewImage.heightAnchor.constraint(equalToConstant: 20),
//            viewImage.widthAnchor.constraint(equalToConstant: 20),
            
//            lbl.centerYAnchor.constraint(equalTo: btn.centerYAnchor, constant: -3),
//            lbl.centerXAnchor.constraint(equalTo: btn.centerXAnchor),
            
//            circle.heightAnchor.constraint(equalToConstant: 72),
//            circle.widthAnchor.constraint(equalToConstant: 72),
//            circle.centerXAnchor.constraint(equalTo: btn.centerXAnchor),
//            circle.centerYAnchor.constraint(equalTo: btn.centerYAnchor),
            
            btn.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            btn.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            btn.heightAnchor.constraint(equalToConstant: 72),
            btn.widthAnchor.constraint(equalToConstant: 72),

            
            audioLength.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            audioLength.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
            
        ])
        return view
    }()
    
    @objc func removeRecordingViewClicked(_ sender: UIButton) {
        self.view.layoutIfNeeded()
        sender.superview?.removeFromSuperview()
        addAgainComponents()
        let imageViewChange = getButtonImage(recordButton)
        imageViewChange?.image = UIImage(named: "MicIcon")
        recordButton.backgroundColor = UIColor(hexString: "#E8E8E8")
        audioRecorder?.stop()
        self.view.layoutIfNeeded()
    }
    
    func addAgainComponents() {
        self.textingInputView.removeFromSuperview()
        self.messagesTable.removeFromSuperview()
        self.view.addSubview(textingInputView)
        self.view.addSubview(messagesTable)
        NSLayoutConstraint.activate([
            textingInputView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -50),
            textingInputView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            textingInputView.heightAnchor.constraint(equalToConstant: 56),
            textingInputView.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.95),
            
            messagesTable.topAnchor.constraint(equalTo: self.navBar.bottomAnchor),
            messagesTable.bottomAnchor.constraint(equalTo: self.textingInputView.topAnchor),
            messagesTable.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.9),
            messagesTable.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
        ])
    }
    
    
    // MARK: - Record Audio function
    private func recordAudio() {
        let audioURL = getDocumentsDirectory().appendingPathComponent("audio.wav")
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        do {
            audioRecorder = try AVAudioRecorder(url: audioURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
        } catch {
            print("Error recording audio: \(error.localizedDescription)")
        }
    }

    @objc func stopRecording(_ sender: UIButton) {
        print("stop")
        audioRecorder?.stop()
        
    }
    
    func removeRecordingView(_ btn: UIButton) {
        
    }

    
    lazy var convertingView: UIView = {
        let numberOfCircles = 8
        let circleSize: CGFloat = 50
        let circleSpacing: CGFloat = 20
        let containerView = UIView(frame: view.bounds)
        containerView.backgroundColor = .white
        view.addSubview(containerView)
        for index in 0..<numberOfCircles {
            let circle = UIView(frame: CGRect(x: 0, y: 0, width: circleSize, height: circleSize))
            circle.layer.cornerRadius = circleSize / 2
            circle.backgroundColor = UIColor(hue: CGFloat(index) / CGFloat(numberOfCircles), saturation: 1, brightness: 1, alpha: 1)
            let x = containerView.bounds.midX + (containerView.bounds.width / 2 - circleSize / 2 - circleSpacing) * cos(2 * Double.pi * Double(index) / Double(numberOfCircles))
            let y = containerView.bounds.midY + (containerView.bounds.height / 2 - circleSize / 2 - circleSpacing) * sin(2 * Double.pi * Double(index) / Double(numberOfCircles))
            circle.center = CGPoint(x: x, y: y)
            containerView.addSubview(circle)
        }
        return containerView
    }()
    
    lazy var audioLength: UILabel = {
        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.text = "00:00"
        return lbl
    }()
    
    lazy var recordButtonIcon: UIImageView = {
        let img = UIImageView()
        img.translatesAutoresizingMaskIntoConstraints = false
        img.image = UIImage(named: "MicIcon")
        return img
    }()
    
    lazy var sendButtonIcon: UIImageView = {
        let img = UIImageView()
        img.translatesAutoresizingMaskIntoConstraints = false
        img.image = UIImage(named: "sendIcon")
        return img
    }()
    
    func setupUI() {
        self.view.backgroundColor = .systemBackground
        self.view.addSubview(backgroundImage)
        self.view.addSubview(navBar)
        self.navBar.addSubview(botsMenu)
        self.navBar.addSubview(logoNameView)
        self.logoNameView.addSubview(logo)
        self.logoNameView.addSubview(name)
        self.navBar.addSubview(newConversation)
        self.navBar.addSubview(actionsMenu)
        self.view.addSubview(textingInputView)
        self.textingInputView.addSubview(textingInput)
        self.textingInputView.addSubview(sendButton)
        self.textingInputView.addSubview(recordButton)
        self.sendButton.addSubview(sendButtonIcon)
        self.recordButton.addSubview(recordButtonIcon)
        self.view.addSubview(messagesTable)
        
        messagesTable.backgroundColor = .clear
        NSLayoutConstraint.activate([
            
            messagesTable.topAnchor.constraint(equalTo: self.navBar.bottomAnchor),
            messagesTable.bottomAnchor.constraint(equalTo: self.textingInputView.topAnchor),
            messagesTable.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.9),
            messagesTable.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),

            textingInputView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -50),
            textingInputView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            textingInputView.heightAnchor.constraint(equalToConstant: 56),
            textingInputView.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.95),

            textingInput.heightAnchor.constraint(greaterThanOrEqualTo: self.textingInputView.heightAnchor, constant: -20),
            textingInput.widthAnchor.constraint(equalTo: self.textingInputView.widthAnchor, multiplier: 0.67),
            textingInput.leadingAnchor.constraint(equalTo: self.textingInputView.leadingAnchor, constant: 30),
            textingInput.centerYAnchor.constraint(equalTo: self.textingInputView.centerYAnchor),

            sendButton.heightAnchor.constraint(equalToConstant: 36),
            sendButton.widthAnchor.constraint(equalToConstant: 36),
            sendButton.centerYAnchor.constraint(equalTo: self.textingInputView.centerYAnchor),
            sendButton.trailingAnchor.constraint(equalTo: self.recordButton.leadingAnchor, constant: -10),
            
            recordButton.heightAnchor.constraint(equalToConstant: 36),
            recordButton.widthAnchor.constraint(equalToConstant: 36),
            recordButton.centerYAnchor.constraint(equalTo: self.textingInputView.centerYAnchor),
            recordButton.trailingAnchor.constraint(equalTo: self.textingInputView.trailingAnchor, constant: -20),
            
            
            recordButtonIcon.centerXAnchor.constraint(equalTo: self.recordButton.centerXAnchor),
            recordButtonIcon.centerYAnchor.constraint(equalTo: self.recordButton.centerYAnchor),
            
            sendButtonIcon.centerXAnchor.constraint(equalTo: self.sendButton.centerXAnchor),
            sendButtonIcon.centerYAnchor.constraint(equalTo: self.sendButton.centerYAnchor),
            
            navBar.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 50),
            navBar.widthAnchor.constraint(equalTo: self.view.widthAnchor),
            navBar.heightAnchor.constraint(equalToConstant: 66),
            
            botsMenu.leadingAnchor.constraint(equalTo: self.navBar.leadingAnchor, constant: 16),
            botsMenu.topAnchor.constraint(equalTo: self.navBar.topAnchor, constant: 20),
            botsMenu.heightAnchor.constraint(equalToConstant: 24),
            botsMenu.widthAnchor.constraint(equalToConstant: 24),
            
            logoNameView.leadingAnchor.constraint(equalTo: self.botsMenu.trailingAnchor),
            logoNameView.topAnchor.constraint(equalTo: self.navBar.topAnchor),
            logoNameView.heightAnchor.constraint(equalTo: self.navBar.heightAnchor),
            
            logo.leadingAnchor.constraint(equalTo: self.logoNameView.leadingAnchor, constant: 20),
            logo.topAnchor.constraint(equalTo: self.logoNameView.topAnchor, constant: 10),
            logo.heightAnchor.constraint(equalToConstant: 40),
            logo.widthAnchor.constraint(equalToConstant: 40),
            
            name.leadingAnchor.constraint(equalTo: self.logo.trailingAnchor, constant: 20),
            name.heightAnchor.constraint(equalToConstant: 20),
            name.topAnchor.constraint(equalTo: self.logoNameView.topAnchor, constant: 20),
    
            newConversation.topAnchor.constraint(equalTo: self.navBar.topAnchor, constant: 20),
            newConversation.trailingAnchor.constraint(equalTo: self.navBar.trailingAnchor, constant: -40),
            
            actionsMenu.topAnchor.constraint(equalTo: self.navBar.topAnchor, constant: 20),
            actionsMenu.trailingAnchor.constraint(equalTo: self.navBar.trailingAnchor, constant: -20)
        ])
    }

}


// MARK: - Extract PDF pages
func extractPDFPages() -> String? {
    
    guard let url = Bundle.main.url(forResource: "menu", withExtension: "pdf") else {
        print("PDF file not found.")
        return ""
    }
    guard let pdf = PDFDocument(url: URL(fileURLWithPath: url.path)) else {
        return nil
    }
    var extractedPages = "--- START OF PDF \(url) ---\n"
    for index in 0..<pdf.pageCount {
        if let page = pdf.page(at: index), let pageContent = page.string {
            extractedPages += "--- PAGE \(index) ---\n"
            extractedPages += pageContent
            extractedPages += "\n"
        }
    }
    return extractedPages
}

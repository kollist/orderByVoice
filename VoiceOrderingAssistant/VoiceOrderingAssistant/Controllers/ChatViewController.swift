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

class ChatViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, AVSpeechSynthesizerDelegate, AVAudioRecorderDelegate, UITextViewDelegate, UIGestureRecognizerDelegate, UITextFieldDelegate {
    private var synthesizer: AVSpeechSynthesizer?
    private var audioRecorder: AVAudioRecorder?
    private var audioLengthMax: CGFloat = 1.0
    private var speechManager = SpeechManager()
    private var timer: Timer?
    private var isShowen = false
    var recordingDuration: TimeInterval = 0.0
    let maxRecordingDuration: TimeInterval = 120.0 // 2 minutes

    var conversation = Conversation(messages: [], conversationName: "Default name", conversationID: 1)
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
                    self.showMicrophoneAccessAlert()
                }
            }
        }
        super.viewDidLoad()
        messagesTable.delegate = self
        messagesTable.dataSource = self
        messagesTable.register(MessageCell.self, forCellReuseIdentifier: MessageCell.identifier)
        messagesTable.reloadData()
        setupUI()
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.view.layoutIfNeeded()
    }
    
    func showMicrophoneAccessAlert() {
        let alert = UIAlertController(title: "Microphone Access Denied", message: "Please enable microphone access in settings.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
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
        view.tag = 21
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
        btn.addTarget(self, action: #selector(conversationAction), for: .touchUpInside)
        return btn
    }()
    
    lazy var renameConversationButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.isUserInteractionEnabled = true
        btn.addTarget(self, action: #selector(renameConversationButtonTapped), for:.touchUpInside)

        return btn
    }()
    lazy var deleteConversationButton: UIButton = {
        let btn = UIButton()
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.isUserInteractionEnabled = true
        btn.addTarget(self, action: #selector(deleteConversationButtonTapped), for: .touchUpInside)
        return btn
    }()
    
    lazy var renamingTextFieldLabel: UILabel = {
        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.backgroundColor = .white
        lbl.layer.zPosition = 99999
        lbl.text = "New Name"
        lbl.font = .systemFont(ofSize: 10)
        lbl.textAlignment = .center
        return lbl
    }()
    
    lazy var renamingSquare: UIView = {
        
        let view = UIView()
        view.isUserInteractionEnabled = true
        view.addSubview(renamingInputView)
        view.addSubview(cancelRenamingButton)
        view.addSubview(confirmRenamingButton)
        view.addSubview(renamingTextFieldLabel)
        NSLayoutConstraint.activate([
            
            renamingInputView.topAnchor.constraint(equalTo: view.topAnchor, constant: 37),
            renamingInputView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            renamingInputView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7),
            renamingInputView.heightAnchor.constraint(equalToConstant: 40),
            
            cancelRenamingButton.widthAnchor.constraint(equalToConstant: 90),
            cancelRenamingButton.heightAnchor.constraint(equalToConstant: 30),
            cancelRenamingButton.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: -50),
            cancelRenamingButton.topAnchor.constraint(equalTo: renamingInputView.bottomAnchor, constant: 17),
            
            confirmRenamingButton.widthAnchor.constraint(equalToConstant: 90),
            confirmRenamingButton.heightAnchor.constraint(equalToConstant: 30),
            confirmRenamingButton.leadingAnchor.constraint(equalTo: cancelRenamingButton.trailingAnchor, constant: 15),
            confirmRenamingButton.topAnchor.constraint(equalTo: renamingInputView.bottomAnchor, constant: 17),
            
            renamingTextFieldLabel.topAnchor.constraint(equalTo: renamingInputView.topAnchor, constant: -7),
            renamingTextFieldLabel.leadingAnchor.constraint(equalTo: renamingInputView.leadingAnchor, constant: 10),
            renamingTextFieldLabel.widthAnchor.constraint(equalToConstant: 60)
            
            
        ])
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        view.layer.cornerRadius = 20
        return view
    }()
    
    lazy var cancelRenamingButton: UIButton = {
        let cancelBtn = UIButton()
        cancelBtn.setTitle("Cancel", for: .normal)
        cancelBtn.setTitleColor(UIColor(named: "MainColor"), for: .normal)
        cancelBtn.translatesAutoresizingMaskIntoConstraints = false
        cancelBtn.isUserInteractionEnabled = true
        cancelBtn.layer.borderWidth = 1
        cancelBtn.layer.borderColor = UIColor(named: "MainColor")?.cgColor
        cancelBtn.layer.cornerRadius = 15
        cancelBtn.addTarget(self, action: #selector(cancelRenaming), for: .touchUpInside)
        return cancelBtn
    }()
    
    lazy var cancelDeletingButton: UIButton = {
        let cancelBtn = UIButton()
        cancelBtn.setTitle("Cancel", for: .normal)
        cancelBtn.setTitleColor(UIColor(named: "MainColor"), for: .normal)
        cancelBtn.translatesAutoresizingMaskIntoConstraints = false
        cancelBtn.isUserInteractionEnabled = true
        cancelBtn.layer.borderWidth = 1
        cancelBtn.layer.borderColor = UIColor(named: "MainColor")?.cgColor
        cancelBtn.layer.cornerRadius = 15
        cancelBtn.addTarget(self, action: #selector(cancelDeleting), for: .touchUpInside)
        return cancelBtn
    }()
    
    @objc func cancelRenaming(_ sender: UIButton) {
        renamingView.removeFromSuperview()
        
    }
    @objc func cancelDeleting(_ sender: UIButton) {
        deletingCoversationView.removeFromSuperview()
    }
    @objc func confirmRenaming( _ sender: UIButton) {
        if (renamingInputTextField.text != "") {
            if let newName = renamingInputTextField.text {
                self.conversation.setConversationName(newName)
                self.name.text = newName
                renamingView.removeFromSuperview()
                return
            }
            
        }
        renamingInputView.layer.borderColor = UIColor.red.cgColor
        renamingTextFieldLabel.textColor = .red
        
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if (textField == renamingInputTextField) {
            if (textField.text != "") {
                renamingInputView.layer.borderColor = UIColor(named: "MainColor")?.cgColor
                renamingTextFieldLabel.textColor = .black
            }
        }
        
        return true
    }
    
    lazy var confirmRenamingButton: UIButton = {
        let renameBtn = UIButton()
        renameBtn.setTitle("Rename", for: .normal)
        renameBtn.setTitleColor(.white, for: .normal)
        renameBtn.backgroundColor = UIColor(named: "MainColor")
        renameBtn.translatesAutoresizingMaskIntoConstraints = false
        renameBtn.isUserInteractionEnabled = true
        renameBtn.layer.borderColor = UIColor(named: "MainColor")?.cgColor
        renameBtn.layer.cornerRadius = 15
        renameBtn.addTarget(self, action: #selector(confirmRenaming), for: .touchUpInside)
        return renameBtn
    }()
    
    lazy var renamingInputView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor(named: "MainColor")?.cgColor
        view.addSubview(renamingInputTextField)
        NSLayoutConstraint.activate([
            renamingInputTextField.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
            renamingInputTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            renamingInputTextField.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10),
            renamingInputTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
        ])
        return view
    }()
    
    lazy var renamingInputTextField: UITextField = {
        let input = UITextField()
        input.delegate = self
        input.translatesAutoresizingMaskIntoConstraints = false
        input.placeholder = "Write the new name..."
        input.font = .systemFont(ofSize: 16)
        input.text = conversation.getConversationName()
        return input
    }()
    
    lazy var renamingView: UIView = {
        let view = UIView()
        let renamingViewTap = UITapGestureRecognizer(target: self, action: #selector(handleRenamingViewTap(_:)))
        renamingViewTap.delegate = self
        view.addGestureRecognizer(renamingViewTap)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(hexString: "#0000000", alpha: 0.5)
        view.addSubview(renamingSquare)
        NSLayoutConstraint.activate([
            renamingSquare.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            renamingSquare.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            renamingSquare.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            renamingSquare.heightAnchor.constraint(equalToConstant: 135),
        ])
        return view
    }()
    
    lazy var deletingCoversationView: UIView = {
        let view = UIView()
        let deletingViewTap = UITapGestureRecognizer(target: self, action: #selector(handleRenamingViewTap(_:)))
        deletingViewTap.delegate = self
        view.addGestureRecognizer(deletingViewTap)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(hexString: "#0000000", alpha: 0.5)
        view.addSubview(deletingSquare)
        NSLayoutConstraint.activate([
            deletingSquare.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            deletingSquare.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            deletingSquare.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            deletingSquare.heightAnchor.constraint(equalToConstant: 135),
        ])
        return view
    }()
    
    lazy var confirmDeletingButton: UIButton = {
        let renameBtn = UIButton()
        renameBtn.setTitle("Delete", for: .normal)
        renameBtn.setTitleColor(.white, for: .normal)
        renameBtn.backgroundColor = UIColor(named: "MainColor")
        renameBtn.translatesAutoresizingMaskIntoConstraints = false
        renameBtn.isUserInteractionEnabled = true
        renameBtn.layer.borderColor = UIColor(named: "MainColor")?.cgColor
        renameBtn.layer.cornerRadius = 15
        renameBtn.addTarget(self, action: #selector(confirmDeletingConversation), for: .touchUpInside)
        return renameBtn
    }()
    
    @objc func confirmDeletingConversation( _ sender: UIButton ) {
        self.conversation = Conversation(messages: [], conversationName: "Default name", conversationID: 1)
        name.text = conversation.getConversationName()
        messagesTable.reloadData()
        deletingCoversationView.removeFromSuperview()
        
    }
    
    lazy var deletingSquare: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        view.layer.cornerRadius = 20
        view.addSubview(deletingMessageLabel)
        view.addSubview(cancelDeletingButton)
        view.addSubview(confirmDeletingButton)
        
        NSLayoutConstraint.activate([
            deletingMessageLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 30),
            deletingMessageLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            deletingMessageLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9),
            
            cancelDeletingButton.topAnchor.constraint(equalTo: deletingMessageLabel.bottomAnchor, constant: 15),
            cancelDeletingButton.widthAnchor.constraint(equalToConstant: 90),
            cancelDeletingButton.heightAnchor.constraint(equalToConstant: 30),
            cancelDeletingButton.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: -50),
            
            confirmDeletingButton.widthAnchor.constraint(equalToConstant: 90),
            confirmDeletingButton.heightAnchor.constraint(equalToConstant: 30),
            confirmDeletingButton.leadingAnchor.constraint(equalTo: cancelDeletingButton.trailingAnchor, constant: 15),
            confirmDeletingButton.topAnchor.constraint(equalTo: deletingMessageLabel.bottomAnchor, constant: 17),
        ])
        return view
    }()
    
    lazy var deletingMessageLabel: UILabel = {
        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.text = "Are you sure you want to delete this chat? Once it's deleted, the conversation cannot be recovered."
        lbl.font = .systemFont(ofSize: 13)
        lbl.textAlignment = .center
        lbl.numberOfLines = 0
        return lbl
    }()
    
    
    @objc func handleRenamingViewTap(_ sender: UITapGestureRecognizer) {
        renamingView.removeFromSuperview()
        deletingCoversationView.removeFromSuperview()
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.view == renamingSquare || touch.view == renamingInputView || touch.view == deletingSquare {
            return false
        }
        return true
    }

    
    @objc func renameConversationButtonTapped(_ sender: UIButton) {
        
        if let parent = conversationActionsMenu.superview {
            isShowen = false
            conversationActionsMenu.removeFromSuperview()
            parent.addSubview(renamingView)
            NSLayoutConstraint.activate([
                renamingView.leadingAnchor.constraint(equalTo: parent.leadingAnchor),
                renamingView.trailingAnchor.constraint(equalTo: parent.trailingAnchor),
                renamingView.topAnchor.constraint(equalTo: parent.topAnchor),
                renamingView.bottomAnchor.constraint(equalTo: parent.bottomAnchor)
            ])
        }
    }
    
    
    
    @objc func deleteConversationButtonTapped(_ sender: UIButton) {
        if let parent = conversationActionsMenu.superview {
            isShowen = false
            conversationActionsMenu.removeFromSuperview()
            parent.addSubview(deletingCoversationView)
            NSLayoutConstraint.activate([
                deletingCoversationView.leadingAnchor.constraint(equalTo: parent.leadingAnchor),
                deletingCoversationView.trailingAnchor.constraint(equalTo: parent.trailingAnchor),
                deletingCoversationView.topAnchor.constraint(equalTo: parent.topAnchor),
                deletingCoversationView.bottomAnchor.constraint(equalTo: parent.bottomAnchor)
            ])
            
        }
    }
    
    lazy var conversationActionsMenu: UIView = {
        let menu = UIView()
        menu.translatesAutoresizingMaskIntoConstraints = false
        menu.isUserInteractionEnabled = true
        menu.backgroundColor = .systemBackground
        menu.layer.shadowColor = UIColor(hexString: "5A5A5A").cgColor
        menu.layer.shadowOpacity = 1
        menu.layer.shadowOffset = .zero
        menu.layer.shadowRadius = 10
        menu.layer.cornerRadius = 20
     
        let itemOneLbl = UILabel()
        itemOneLbl.text = "Rename"
        itemOneLbl.tintColor = UIColor(hexString: "5A5A5A")
        itemOneLbl.font = .boldSystemFont(ofSize: 16)
        itemOneLbl.textAlignment = .center
        itemOneLbl.translatesAutoresizingMaskIntoConstraints = false
        
        let itemTwoLbl = UILabel()
        itemTwoLbl.text = "Delete"
        itemTwoLbl.tintColor = UIColor(hexString: "5A5A5A")
        itemTwoLbl.font = .boldSystemFont(ofSize: 16)
        itemTwoLbl.textAlignment = .center
        itemTwoLbl.translatesAutoresizingMaskIntoConstraints = false
        
       let itemOneLogo = UIImageView()
        itemOneLogo.tintColor = UIColor(hexString: "5A5A5A")
        itemOneLogo.translatesAutoresizingMaskIntoConstraints = false
        itemOneLogo.image = UIImage(systemName: "pencil")
        
        let itemTwoLogo = UIImageView()
        itemTwoLogo.tintColor = UIColor(hexString: "5A5A5A")
        itemTwoLogo.translatesAutoresizingMaskIntoConstraints = false
         itemTwoLogo.image = UIImage(systemName: "trash")
        
        let devider = UIView()
        devider.backgroundColor = UIColor(hexString: "C0C0C0")
        devider.translatesAutoresizingMaskIntoConstraints = false
        
        renameConversationButton.addSubview(itemOneLbl)
        renameConversationButton.addSubview(itemOneLogo)
        deleteConversationButton.addSubview(itemTwoLbl)
        deleteConversationButton.addSubview(itemTwoLogo)
        
        menu.addSubview(renameConversationButton)
        menu.addSubview(devider)
        menu.addSubview(deleteConversationButton)
        
        NSLayoutConstraint.activate([
            
            renameConversationButton.heightAnchor.constraint(equalToConstant: 24),
            renameConversationButton.widthAnchor.constraint(equalToConstant: 100),
            renameConversationButton.centerXAnchor.constraint(equalTo: menu.centerXAnchor),
            renameConversationButton.topAnchor.constraint(equalTo: menu.topAnchor, constant: 13),
            
            devider.heightAnchor.constraint(equalToConstant: 2),
            devider.widthAnchor.constraint(equalToConstant: 100),
            devider.centerYAnchor.constraint(equalTo: menu.centerYAnchor),
            devider.centerXAnchor.constraint(equalTo: menu.centerXAnchor),
            
            deleteConversationButton.heightAnchor.constraint(equalToConstant: 24),
            deleteConversationButton.widthAnchor.constraint(equalToConstant: 100),
            deleteConversationButton.centerXAnchor.constraint(equalTo: menu.centerXAnchor),
            deleteConversationButton.bottomAnchor.constraint(equalTo: menu.bottomAnchor, constant: -13),
            
            itemOneLbl.centerYAnchor.constraint(equalTo: renameConversationButton.centerYAnchor),
            itemOneLbl.leadingAnchor.constraint(equalTo: itemOneLogo.trailingAnchor),
            itemOneLbl.widthAnchor.constraint(equalToConstant: 76),
            itemOneLbl.heightAnchor.constraint(equalToConstant: 24),

            itemOneLogo.leadingAnchor.constraint(equalTo: renameConversationButton.leadingAnchor),
            itemOneLogo.heightAnchor.constraint(equalToConstant: 24),
            itemOneLogo.widthAnchor.constraint(equalToConstant: 24),

            itemTwoLbl.centerYAnchor.constraint(equalTo: deleteConversationButton.centerYAnchor),
            itemTwoLbl.leadingAnchor.constraint(equalTo: itemTwoLogo.trailingAnchor),
            itemTwoLbl.widthAnchor.constraint(equalToConstant: 76),
            itemTwoLbl.heightAnchor.constraint(equalToConstant: 24),

            itemTwoLogo.leadingAnchor.constraint(equalTo: deleteConversationButton.leadingAnchor),
            itemTwoLogo.heightAnchor.constraint(equalToConstant: 24),
            itemTwoLogo.widthAnchor.constraint(equalToConstant: 24)
        
        ])
        return menu
    }()

    @objc func conversationAction( _ sender: UIButton) {
        
        if isShowen {
            conversationActionsMenu.removeFromSuperview()
            isShowen = false
            return
        }
        if let parentView = sender.superview?.superview {
            parentView.addSubview(conversationActionsMenu)
            NSLayoutConstraint.activate([
                conversationActionsMenu.topAnchor.constraint(equalTo: sender.bottomAnchor, constant: 20),
                conversationActionsMenu.trailingAnchor.constraint(equalTo: parentView.trailingAnchor, constant: -10),
                conversationActionsMenu.heightAnchor.constraint(equalToConstant: 106),
                conversationActionsMenu.widthAnchor.constraint(equalToConstant: 165)
            ])
            self.viewDidLayoutSubviews()
            isShowen = true
        }
    }
    
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
        btn.isEnabled = false
        btn.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
        return btn
    }()
    
    lazy var sendButtonIcon: UIImageView = {
        let img = UIImageView()
        img.translatesAutoresizingMaskIntoConstraints = false
        img.image = UIImage(named: "sendIcon")
        return img
    }()

    @objc func sendMessage(_ sender: UIButton) {
        guard let msg = textingInput.text, !msg.isEmpty else { return }
        // UI feedback and disabling button
        
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
            let imgView = self.getButtonImage(sender)
            imgView?.image = UIImage(named: "sendIcon")
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
                print("Something went wrong")
                print(error.localizedDescription)
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
        print("Record button clicked")

        if let recorder = audioRecorder {
            if recorder.isRecording {
                print("Stopping the recording")
                addAgainComponents()
                let imageViewChange = getButtonImage(recordButton)
                imageViewChange?.image = UIImage(named: "MicIcon")
                recordButton.backgroundColor = UIColor(hexString: "#E8E8E8")
                recorder.stop()
                audioRecorder = nil
                recordingView.removeFromSuperview()
                return
            } else {
                print("Recorder exists but is not recording")
            }
        } else {
            print("Recorder does not exist, starting new recording")
        }

        // Start new recording
        print("Starting new recording")
        recordAudio()
        updateView(sender)
        stopRecordingButton.isHidden = false
        viewContainer.isHidden = false
        loadingIndicator.isHidden = true
        transcriptionMessageLabel.isHidden = true
        noSpeechDetectedView.isHidden = true
        
    }

    private func recordAudio() {
        let audioURL = getDocumentsDirectory().appendingPathComponent("audio.wav")
        print("Audio file URL: \(audioURL)")

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
            recordingDuration = 0.0
            timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateRecordingDuration), userInfo: nil, repeats: true)
        } catch {
            print("Error recording audio: \(error.localizedDescription)")
        }
    }
    
    @objc func updateRecordingDuration() {
        if let recorder = audioRecorder {
            recordingDuration = recorder.currentTime
            let minutes = Int(recordingDuration) / 60
            let seconds = Int(recordingDuration) % 60
            audioLength.text = String(format: "%02d:%02d", minutes, seconds)

//            if recordingDuration >= maxRecordingDuration {
//                finishRecording(success: true)
//            }
        }
    }

    @objc func stopRecording(_ sender: UIButton) {
        print("Stop recording button pressed")

        // Stop the audio recorder if it exists
        if let recorder = audioRecorder {
            recorder.stop()
            print("Recording stopped")
        } else {
            print("Audio recorder is nil")
        }

        // Remove the button from its superview
        audioRecorder = nil
        loadingIndicator.startAnimating()
        sender.isHidden = true
        viewContainer.isHidden = true
        loadingIndicator.isHidden = false
        transcriptionMessageLabel.isHidden = false
        
        // Audio to text
        let audioFileURL = getDocumentsDirectory().appendingPathComponent("audio.wav")
        recognizeText(from: audioFileURL) { (recognizedText, error) in
            if let recognizedText = recognizedText {
//                self.sendRequestToGenerativeLanguageAPI(text: recognizedText)
                self.textingInput.text = recognizedText
            } else if let error = error {
                self.addNoTextDetected(error.localizedDescription)
                self.loadingIndicator.isHidden = true
                self.transcriptionMessageLabel.isHidden = true
                self.noSpeechDetectedView.isHidden = false

            }
        }
        
    }
    
    lazy var noSpeechDetectedLabel: UILabel = {
        let lbl = UILabel()
        lbl.numberOfLines = 0
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.textAlignment = .center
        return lbl
    }()
    
    lazy var reRecordAudioButton: UIButton = {
        let rerecordBtn = UIButton()
        rerecordBtn.translatesAutoresizingMaskIntoConstraints = false
        rerecordBtn.setTitle("Start new recording", for: .normal)
        rerecordBtn.setTitleColor(.white, for: .normal)
        rerecordBtn.backgroundColor = UIColor(hexString: "#882E86")
        rerecordBtn.layer.cornerRadius = 25
        rerecordBtn.addTarget(self, action: #selector(recordAudioClicked), for: .touchUpInside)
        return rerecordBtn
    }()
    
    lazy var noSpeechDetectedView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    func addNoTextDetected(_ errorMsg: String) {
        
        
        
        noSpeechDetectedLabel.text = errorMsg
        
        noSpeechDetectedView.addSubview(noSpeechDetectedLabel)
        noSpeechDetectedView.addSubview(reRecordAudioButton)
        recordingView.addSubview(noSpeechDetectedView)
        
        NSLayoutConstraint.activate([
            
            noSpeechDetectedView.centerXAnchor.constraint(equalTo: recordingView.centerXAnchor),
            noSpeechDetectedView.centerYAnchor.constraint(equalTo: recordingView.centerYAnchor),
            noSpeechDetectedView.widthAnchor.constraint(equalToConstant: 220),
            noSpeechDetectedView.heightAnchor.constraint(equalToConstant: 70),
            
            noSpeechDetectedLabel.trailingAnchor.constraint(equalTo: noSpeechDetectedView.trailingAnchor),
            noSpeechDetectedLabel.leadingAnchor.constraint(equalTo: noSpeechDetectedView.leadingAnchor),
            noSpeechDetectedLabel.topAnchor.constraint(equalTo: noSpeechDetectedView.topAnchor),
            
            
            reRecordAudioButton.trailingAnchor.constraint(equalTo: noSpeechDetectedView.trailingAnchor),
            reRecordAudioButton.leadingAnchor.constraint(equalTo: noSpeechDetectedView.leadingAnchor),
            reRecordAudioButton.topAnchor.constraint(equalTo: noSpeechDetectedLabel.bottomAnchor, constant: 16),
            reRecordAudioButton.heightAnchor.constraint(equalToConstant: 50),
        ])
        
    }
    
    // MARK: - Recognize Text
    private func recognizeText(from audioFileURL: URL, completion: @escaping (String?, Error?) -> Void) {
        speechManager.transcribeAudioFile(at: audioFileURL) { (recognizedText, error) in
            completion(recognizedText, error)
        }
    }
    
    private func updateView(_ sender: UIButton) {
        sender.backgroundColor = UIColor(named: "MainColor")?.withAlphaComponent(0.26)
        let superView = getButtonImage(sender)
        let img = superView?.image?.withRenderingMode(.alwaysTemplate)
        superView?.image = img
        superView?.tintColor = UIColor(named: "MainColor")
        self.textingInputView.removeFromSuperview()
        self.messagesTable.removeFromSuperview()
        self.view.addSubview(textingInputView)
        self.view.addSubview(messagesTable)
        self.view.addSubview(recordingView)
        
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
    
    lazy var stopRecordingButton: UIButton = {
        let  btn = UIButton()
        btn.isUserInteractionEnabled = true
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(stopRecording), for: .touchUpInside)
        return btn
    }()
    

    
    func textViewDidChange(_ textView: UITextView) {
            // Handle text changes
            if textView.text.isEmpty {
                let imageViewChange = getButtonImage(sendButton)
                imageViewChange?.image = UIImage(named: "sendIcon")
                sendButton.isEnabled = false
                sendButton.backgroundColor = #colorLiteral(red: 0.9098039216, green: 0.9098039216, blue: 0.9098039216, alpha: 1)
                
            } else {
                sendButton.backgroundColor = UIColor(named: "MainColor")?.withAlphaComponent(0.26)
                let superView = getButtonImage(sendButton)
                let img = superView?.image?.withRenderingMode(.alwaysTemplate)
                superView?.image = img
                sendButton.isEnabled = true 
                superView?.tintColor = UIColor(named: "MainColor")
            }
        }
    
    lazy var loadingIndicator: CircularLoadingIndicatorView = {
        let loader = CircularLoadingIndicatorView()
        loader.translatesAutoresizingMaskIntoConstraints = false
        loader.isHidden = true
        return loader
    }()
    
    lazy var transcriptionMessageLabel: UILabel = {
        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.text = "Convert to text..."
        lbl.isHidden = true
        return lbl
    }()
    
    
    lazy var recordingView: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = true
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(hexString: "#D9D9D9")
        
        
         
        // X Button to remove the recording view
        let removeViewBtn = UIButton()
        removeViewBtn.isUserInteractionEnabled = true
        removeViewBtn.translatesAutoresizingMaskIntoConstraints = false
        removeViewBtn.tintColor = .gray
        removeViewBtn.setBackgroundImage(UIImage(systemName: "xmark"), for: .normal)
        removeViewBtn.addTarget(self, action: #selector(removeRecordingViewClicked), for: .touchUpInside)

        view.addSubview(stopRecordingButton)
        view.addSubview(viewContainer)
        view.addSubview(audioLength)
        view.addSubview(removeViewBtn)
        view.addSubview(loadingIndicator)
        view.addSubview(transcriptionMessageLabel)
        
        NSLayoutConstraint.activate([
            
            transcriptionMessageLabel.leadingAnchor.constraint(equalTo: loadingIndicator.trailingAnchor, constant: 20),
            transcriptionMessageLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: -50),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            loadingIndicator.heightAnchor.constraint(equalToConstant: 37),
            loadingIndicator.widthAnchor.constraint(equalToConstant: 37),
            
            viewContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            viewContainer.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            removeViewBtn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            removeViewBtn.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
            
            stopRecordingButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stopRecordingButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stopRecordingButton.heightAnchor.constraint(equalToConstant: 72),
            stopRecordingButton.widthAnchor.constraint(equalToConstant: 72),

            
            audioLength.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            audioLength.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
            
        ])
        return view
    }()
    
    lazy var viewContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        
        // Circle Behind The Button
        let circle = UIView()
        circle.layer.cornerRadius = 36
        circle.translatesAutoresizingMaskIntoConstraints = false
        circle.backgroundColor = UIColor(named: "MainColor")?.withAlphaComponent(0.26)
        circle.tag = 21
        
        // Label While Recording
        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.text = "      Tap to stop recording"
        lbl.textColor = UIColor(hexString: "#333333")
        
        // Image In The label while recording
        let img = UIImage(systemName: "playpause")
        let viewImage = UIImageView(image: img)
        viewImage.translatesAutoresizingMaskIntoConstraints = false
        viewImage.tintColor = .black
        viewImage.layer.cornerRadius = 14.5
        
        lbl.addSubview(viewImage)
        
        view.addSubview(lbl)
        view.addSubview(circle)
        
        NSLayoutConstraint.activate([
            viewImage.topAnchor.constraint(equalTo: lbl.topAnchor),
            viewImage.leadingAnchor.constraint(equalTo: lbl.leadingAnchor),
            viewImage.heightAnchor.constraint(equalToConstant: 20),
            viewImage.widthAnchor.constraint(equalToConstant: 20),
            
            lbl.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -3),
            lbl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            circle.heightAnchor.constraint(equalToConstant: 72),
            circle.widthAnchor.constraint(equalToConstant: 72),
            circle.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            circle.centerYAnchor.constraint(equalTo: view.centerYAnchor),
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

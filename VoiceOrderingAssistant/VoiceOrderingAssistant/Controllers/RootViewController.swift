//
//  ViewController.swift
//  VoiceOrderingAssistant
//
//  Created by Zaytech Mac on 8/5/2024.
//

import UIKit

class RootViewController: UIViewController, UIViewControllerTransitioningDelegate {

    private var animator = CircularTransition()
    override func viewDidLoad() {
        super.viewDidLoad()
        setUI()
    }
    
    lazy var goToChatButton: UIButton = {
        let btn = UIButton()
        btn.setImage(UIImage(named: "BotLogo"), for: .normal)
        btn.isUserInteractionEnabled = true
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(goChat), for: .touchUpInside)
        return btn
    }()
    
    
    @objc func goChat() {
        goToChat()
    }
    
    func goToChat() {
        let chatViewController = ChatViewController()
        chatViewController.modalPresentationStyle = .custom
        chatViewController.transitioningDelegate = self
        self.present(chatViewController, animated: true)
        
    }
    
    func setUI() {
        self.view.addSubview(goToChatButton)
        self.view.backgroundColor = .systemBackground
        NSLayoutConstraint.activate([
            goToChatButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -30),
            goToChatButton.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -30),
            goToChatButton.heightAnchor.constraint(equalToConstant: 60),
            goToChatButton.widthAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    
    
    func animationController(forDismissed dismissed: UIViewController) -> (any UIViewControllerAnimatedTransitioning)? {
        animator.transitionMode = .dismiss
        animator.startingPoint = goToChatButton.center
        animator.circleColor = goToChatButton.backgroundColor ?? .systemBackground
        return animator
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> (any UIViewControllerAnimatedTransitioning)? {
        animator.transitionMode = .present
        animator.startingPoint = goToChatButton.center
        animator.circleColor = goToChatButton.backgroundColor ?? .systemBackground
        return animator
    }
    
}

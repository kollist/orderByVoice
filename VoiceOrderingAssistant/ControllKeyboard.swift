//
//  ControllKeyboard.swift
//  VoiceOrderingAssistant
//
//  Created by Zaytech Mac on 17/5/2024.
//

import UIKit


var textViewBottomConstraint: NSLayoutConstraint?

func keyboardWillShowGlobal(_ notification: Notification, _ tableView: UITableView, _ textView: UITextView) {
    guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
        return
    }
    
    let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height, right: 0)
    
    guard let superview = tableView.superview else {
        return
    }
    
    tableView.contentInset = contentInsets
    tableView.scrollIndicatorInsets = contentInsets
    
    if let inputAccessoryView = textView.inputAccessoryView {
        if let existingConstraint = textViewBottomConstraint {
            inputAccessoryView.removeConstraint(existingConstraint)
        }
        
        textViewBottomConstraint = inputAccessoryView.bottomAnchor.constraint(equalTo: superview.bottomAnchor, constant: -keyboardSize.height)
        textViewBottomConstraint?.isActive = true
    }
    
    if let indexPath = tableView.indexPathForSelectedRow {
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
    }
}

func keyboardWillHideGlobal(_ notification: Notification, _ tableView: UITableView, _ textView: UITextView) {
    guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
        return
    }
    
    guard let superview = tableView.superview else {
        return
    }
    
    tableView.contentInset = .zero
    tableView.scrollIndicatorInsets = .zero
    
    if let inputAccessoryView = textView.inputAccessoryView {
        if let existingConstraint = textViewBottomConstraint {
            inputAccessoryView.removeConstraint(existingConstraint)
        }
        
        textViewBottomConstraint = inputAccessoryView.bottomAnchor.constraint(equalTo: superview.bottomAnchor, constant: -50)
        textViewBottomConstraint?.isActive = true
    }
}

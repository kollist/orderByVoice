//
//  ControllKeyboard.swift
//  VoiceOrderingAssistant
//
//  Created by Zaytech Mac on 17/5/2024.
//

import UIKit


var originalTableViewContentInset: UIEdgeInsets = .zero
var originalTextViewContentInset: UIEdgeInsets = .zero

func keyboardWillShowGlobal(_ notification: Notification, _ tableView: UITableView, _ textView: UITextView) {
    guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
        return
    }
    
    // Store the original content insets
    originalTableViewContentInset = tableView.contentInset
    originalTextViewContentInset = textView.contentInset
    
    // Calculate the new content insets
    let tableViewContentInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: keyboardSize.height, right: 0.0)
    let textViewContentInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: keyboardSize.height, right: 0.0)
    
    // Animate the content inset changes
    UIView.animate(withDuration: 0.3) {
        tableView.contentInset = tableViewContentInsets
        tableView.scrollIndicatorInsets = tableViewContentInsets
        textView.contentInset = textViewContentInsets
        textView.scrollIndicatorInsets = textViewContentInsets
    }
}

func keyboardWillHideGlobal(_ notification: Notification, _ tableView: UITableView, _ textView: UITextView) {
    // Restore the original content insets
    UIView.animate(withDuration: 0.3) {
        tableView.contentInset = originalTableViewContentInset
        tableView.scrollIndicatorInsets = originalTableViewContentInset
        textView.contentInset = originalTextViewContentInset
        textView.scrollIndicatorInsets = originalTextViewContentInset
    }
}

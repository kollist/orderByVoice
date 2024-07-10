//
//  DotLoaderView.swift
//  VoiceOrderingAssistant
//
//  Created by Zaytech Mac on 22/5/2024.
//

import Foundation
import UIKit


class CircularLoadingIndicatorView: UIView {
    
    private let dotCount = 8
    private let dotRadius: CGFloat = 3
    private let circleRadius: CGFloat = 18.5
    private var dots = [CAShapeLayer]()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupDots()
        startAnimating()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupDots()
        startAnimating()
    }
    
    deinit {
        removeObserver(self, forKeyPath: "hidden")
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "hidden" {
            if let newValue = change?[.newKey] as? Bool, !newValue {
                startAnimating()
            }
        }
    }
    
    private func setupDots() {
        for _ in 0..<dotCount {
            let dot = CAShapeLayer()
            dot.path = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: dotRadius * 2, height: dotRadius * 2)).cgPath
            dot.fillColor = UIColor.purple.cgColor
            layer.addSublayer(dot)
            dots.append(dot)
        }
        layoutDots()
    }
    
    private func layoutDots() {
        for (i, dot) in dots.enumerated() {
            let angle = (CGFloat(i) / CGFloat(dotCount)) * 2 * .pi
            dot.position = CGPoint(x: bounds.midX + circleRadius * cos(angle) - dotRadius, y: bounds.midY + circleRadius * sin(angle) - dotRadius)
        }
    }
    
    func startAnimating() {
        for (index, dot) in dots.enumerated() {
            let animation = CABasicAnimation(keyPath: "opacity")
            animation.fromValue = 1.0
            animation.toValue = 0.0
            animation.duration = 1.0
            animation.repeatCount = .infinity
            animation.beginTime = CACurrentMediaTime() + (Double(index) / Double(dotCount))
            dot.add(animation, forKey: "opacity")
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layoutDots()
    }
}


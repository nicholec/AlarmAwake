//
//  NumberLabel.swift
//  AlarmAwake
//
//  Created by Nichole on 4/18/18.
//  Copyright © 2018 mac. All rights reserved.
//

import Foundation
import UIKit

class NumberLabel: UILabel {
    func wrongSolution() {
        let origShadowColor = self.shadowColor
        self.textColor = UIColor(red: 0.7098, green: 0, blue: 0, alpha: 1.0)
        self.shadowColor = UIColor.black
        let shakeTime = 0.5
        self.shake(count: 7, for: shakeTime, withTranslation: 18)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2*shakeTime) {
            self.shadowColor = origShadowColor
            self.textColor = UIColor.black
        }
    }
}

public extension UIView {
    
    func shake(count: Float = 4,for duration: TimeInterval = 0.5, withTranslation translation: Float = 5) {
        
        let animation : CABasicAnimation = CABasicAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        animation.repeatCount = count
        animation.duration = duration/TimeInterval(animation.repeatCount)
        animation.autoreverses = true
        animation.fromValue = NSValue(cgPoint: CGPoint(x: CGFloat(-translation), y: self.center.y))
        animation.toValue = NSValue(cgPoint: CGPoint(x: CGFloat(translation), y: self.center.y))
        layer.add(animation, forKey: "shake")
    }
}

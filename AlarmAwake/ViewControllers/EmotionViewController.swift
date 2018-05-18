//
//  EmotionViewController.swift
//  AlarmAwake
//
//  Created by Nichole on 4/19/18.
//  Copyright © 2018 mac. All rights reserved.
//

import Foundation
import UIKit
import Affdex
import RZViewActions
import PopupDialog

class EmotionViewController: UIViewController, AffdexDisplayDelegate {
    var dominantBtn: UIButton? = nil
    var viewModel: EmotionViewModel!
    
    @IBOutlet weak var cameraView: UIImageView!
    @IBOutlet weak var certainty: UILabel!
    @IBOutlet weak var faceDetectedLabel: UILabel!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var progessLabel: UILabel!
    
    @IBOutlet weak var browRaise: UIButton!
    @IBOutlet weak var lipSuck: UIButton!
    @IBOutlet weak var smile: UIButton!
    @IBOutlet weak var kiss: UIButton!
    @IBOutlet weak var browFurrow: UIButton!
    @IBOutlet weak var jawDrop: UIButton!
    
    @IBOutlet weak var firstExprCircle: UIView!
    @IBOutlet weak var secondExprCircle: UIView!
    @IBOutlet weak var thirdExprCircle: UIView!
    @IBOutlet weak var fourthExprCircle: UIView!
    @IBOutlet weak var fifthExprCircle: UIView!
    @IBOutlet weak var circleStackView: UIStackView!
    
    let activeExprColor = UIColor(hue: 0.1222, saturation: 1, brightness: 0.76, alpha: 1.0)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.fifthExprCircle.isHidden = viewModel.difficulty == .Easy
        self.progessLabel.text = "\(self.viewModel.numTimesCorrect.value)/\(self.viewModel.numberToSolveFor)"
        
        viewModel.numTimesCorrect.signal.observeValues { num in
            self.progressView.progress = Float(num)/Float(self.viewModel.numberToSolveFor)
            self.progessLabel.text = "\(num)/\(self.viewModel.numberToSolveFor)"
        }
        
        print("SOLVE: \(self.viewModel.exprPattern)")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    private func getButton(at index: Int) -> UIButton {
        let expr = self.viewModel.exprPattern[index]
        var btnToAnimate = browFurrow
        switch expr {
        case .BrowFurrow:
            btnToAnimate = browFurrow
        case .BrowRaise:
            btnToAnimate = browRaise
        case .LipSuck:
            btnToAnimate = lipSuck
        case .Kiss:
            btnToAnimate = kiss
        case .Smile:
            btnToAnimate = smile
        case .JawDrop:
            btnToAnimate = jawDrop
        }
        
        return btnToAnimate!
    }
    
    func resetCircles() {
        firstExprCircle.backgroundColor = UIColor.white
        secondExprCircle.backgroundColor = UIColor.white
        thirdExprCircle.backgroundColor = UIColor.white
        fourthExprCircle.backgroundColor = UIColor.white
        fifthExprCircle.backgroundColor = UIColor.white
    }
    
    func patternCompletedCircles(correct: Bool) {
        let color = correct ? #colorLiteral(red: 0.3412, green: 0.5882, blue: 0, alpha: 1) : #colorLiteral(red: 0.8784, green: 0, blue: 0, alpha: 1)
        firstExprCircle.backgroundColor = color
        secondExprCircle.backgroundColor = color
        thirdExprCircle.backgroundColor = color
        fourthExprCircle.backgroundColor = color
        fifthExprCircle.backgroundColor = color
    }
    
    func dominantEmotionColoring(dominantEmoExpr: EmoExprScore) {
        if let dominantBttn = dominantBtn, dominantEmoExpr.type.rawValue == dominantBttn.tag, dominantEmoExpr.score >= 85.0  {
            certainty.text = "\(dominantEmoExpr.score)%"
            return
        }
        
        dominantBtn?.layer.borderColor = UIColor.clear.cgColor
        dominantBtn?.isEnabled = false
        dominantBtn = nil
        
        certainty.text = "\(dominantEmoExpr.score)%"
        
        if dominantEmoExpr.score < 85.0 { return }
        
        switch dominantEmoExpr.type {
        case .BrowFurrow:
            browFurrow.layer.borderColor = activeExprColor.cgColor
            dominantBtn = browFurrow
        case .BrowRaise:
            browRaise.layer.borderColor = activeExprColor.cgColor
            dominantBtn = browRaise
        case .LipSuck:
            lipSuck.layer.borderColor = activeExprColor.cgColor
            dominantBtn = lipSuck
        case .Kiss:
            kiss.layer.borderColor = activeExprColor.cgColor
            dominantBtn = kiss
        case .Smile:
            smile.layer.borderColor = activeExprColor.cgColor
            dominantBtn = smile
        case .JawDrop:
            jawDrop.layer.borderColor = activeExprColor.cgColor
            dominantBtn = jawDrop
        }
        
        dominantBtn?.isEnabled = true
    }
    
    @IBAction func startTapped() {
        UIView.animate(withDuration: 0.5, delay: 0, options: [], animations: {
            self.startButton
                .alpha = 0
        }, completion: { _ in
            self.startButton.isHidden = true
            self.startButton.alpha = 1.0
        })
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
            self.displayAnimation()
        }
    }
    
    @IBAction func emoExprTapped(sender: UIButton) {
        let selectedExprEmo = EmoExpr(rawValue: sender.tag)!
        
        // Note: I really like the gradient effect
        switch self.viewModel.currAttempt {
        case 0:
            firstExprCircle.backgroundColor = firstExprCircle.tintColor
        case 1:
            secondExprCircle.backgroundColor = secondExprCircle.tintColor
        case 2:
            thirdExprCircle.backgroundColor = thirdExprCircle.tintColor
        case 3:
            fourthExprCircle.backgroundColor = fourthExprCircle.tintColor
        case 4:
            fifthExprCircle.backgroundColor = fifthExprCircle.tintColor
        default:
            break
        }
        
        self.viewModel.emoExprAdded(selectedExprEmo: selectedExprEmo) { (fullPattern, correct, done) in
            if !fullPattern {
                return
            }
            
            self.patternCompletedCircles(correct: correct)
            self.circleStackView.shake()
            
            correct ? self.noticeSuccess("That's right!") : self.noticeError("Incorrect.")
            self.viewModel.CPUResponse(correct)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.clearAllNotice()
                self.resetCircles()
            }
            
            if correct {
                self.viewModel.stopDetectingFaces()
                self.viewModel.generateNextPattern()
            } else if viewModel.fullPatternAttempts == viewModel.replayAfter {
                self.replayDialog()
            }
            
            if done {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.00) {
                    self.dismiss(animated: true)
                }
            } else if correct {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    UIView.animate(withDuration: 1.0, delay: 0, options: [], animations: {
                        self.startButton.isHidden = false
                        self.startButton.alpha = 1.0
                    }, completion: { _ in
                        self.cameraView.image = nil
                        self.onFaceDetected(found: false)
                    })
                }
                print("SOLVE: \(self.viewModel.exprPattern)")
            }
        }
    }
    
    func onImageReady(image: UIImage) {
        cameraView.image = image
    }
    
    func onFaceDetected(found: Bool) {
        self.faceDetectedLabel.isHidden = !found
        self.certainty.isHidden = !found
        
        if !found {
            dominantBtn?.layer.borderColor = UIColor.clear.cgColor
            dominantBtn?.isEnabled = false
            dominantBtn = nil
        }
    }
    
    @IBAction func showHelpDialog() {
        let helpVC = ViewController(nibName: "EmotionHelpDialog", bundle: nil)
        let popup = PopupDialog(viewController: helpVC, buttonAlignment: .horizontal, transitionStyle: .zoomIn, gestureDismissal: true)
        let helpButton = DefaultButton(title: "EXPRESSION EXAMPLES", height: 60, dismissOnTap: true, action: {
                let expressionVC = ViewController(nibName: "ExpressionHelpDialog", bundle: nil)
                let popup2 = PopupDialog(viewController: expressionVC, buttonAlignment: .horizontal, transitionStyle: .zoomIn, gestureDismissal: true)
                self.present(popup2, animated: true, completion: nil)
        })
        popup.addButton(helpButton)
        
        present(popup, animated: true, completion: nil)
    }
    
    func replayDialog() {
        let title = "Would you like to replay the pattern?"
        let message = "You seem to be having a tough time remembering the pattern.  We can replay the pattern to give you a refresher."
        
        let popup = PopupDialog(title: title, message: message, buttonAlignment: .horizontal)
        
        // Create buttons
        let cancelBtn = CancelButton(title: "No") {
            /**
             * Even if the user didn't replay the pattern, we still reset
             * such that they have the option to replay later on
             **/
            self.viewModel.replayedPattern()
        }
        
        // This button will not the dismiss the dialog
        let replayBtn = DefaultButton(title: "Yes") {
            self.viewModel.stopDetectingFaces()
            self.cameraView.image = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                UIView.animate(withDuration: 1.0, delay: 0, options: [], animations: {
                    self.startButton.isHidden = false
                    self.startButton.alpha = 1.0
                }, completion: { _ in
                    self.cameraView.image = nil
                    self.onFaceDetected(found: false)
                    self.viewModel.replayedPattern()
                })
            }
        }

        popup.addButtons([replayBtn, cancelBtn])
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
            self.present(popup, animated: true, completion: nil)
        }
    }
}

// Animations
extension EmotionViewController {
    func displayAnimation() {
        let firstButton = self.getButton(at: 0)
        let secondButton = self.getButton(at: 1)
        let thirdButton = self.getButton(at: 2)
        let fourthButton = self.getButton(at: 3)
        var fifthButton: UIButton? = nil
        
        // address the difficulty setting
        switch viewModel.difficulty {
        case .Easy:
            break
        case .Medium, .Hard:
            fifthButton = self.getButton(at: 4)
        }
        
        let duration = 1.5 - 0.5*Double(viewModel.difficulty.rawValue)
        
        let wait = RZViewAction.wait(forDuration: duration + 0.5)
        
        let firstBtnAction = RZViewAction.init({
            firstButton.animateBorderColor(color: UIColor.purple, duration: duration)
        }, withDuration: duration)
        let secondBtnAction = RZViewAction.init({
            secondButton.animateBorderColor(color: UIColor.purple, duration: duration)
        }, withDuration: duration)
        let thirdBtnAction = RZViewAction.init({
            thirdButton.animateBorderColor(color: UIColor.purple, duration: duration)
        }, withDuration: duration)
        let fourthBtnAction = RZViewAction.init({
            fourthButton.animateBorderColor(color: UIColor.purple, duration: duration)
        }, withDuration: duration)
        
        var actionList = [firstBtnAction, wait, secondBtnAction, wait, thirdBtnAction, wait, fourthBtnAction, wait]
        
        guard let fifthBtn = fifthButton else {
            let seq = RZViewAction.sequence(actionList)
            animateSeq(seq: seq)
            return
        }
        
        let fifthBtnAction = RZViewAction.init({
            fifthBtn.animateBorderColor(color: UIColor.purple, duration: duration)
        }, withDuration: duration)
        actionList.append(contentsOf: [fifthBtnAction, wait])
        
        let seq = RZViewAction.sequence(actionList)
        animateSeq(seq: seq)
        
    }
    
    private func animateSeq(seq: RZViewActionSequence) {
        UIView.rz_run(seq, withCompletion: { (finished) in
            self.viewModel.startDetectingForFaces()
        })
    }
}

extension UIView {
    func animateBorderColor(color: UIColor, duration: Double) {
        let prevBorderColor = self.layer.borderColor
        UIView.animate(withDuration: duration, delay: 0.0, options:[.repeat, .autoreverse], animations: {
            self.layer.borderColor = color.cgColor
        }, completion: { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                self.layer.borderColor = prevBorderColor
            }
        })
    }
}


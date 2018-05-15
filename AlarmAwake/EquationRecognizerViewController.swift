//
//  EquationRecognizerViewController.swift
//  AlarmAwake
//
//  Created by Nichole Clarke on 4/5/18.
//  Copyright © 2018 mac. All rights reserved.
//

import UIKit
import AVFoundation
import Pulsator
import PopupDialog

class EquationRecognizerViewController: UIViewController {
    
    var viewModel: EquationRecognizerViewModel!
    let pulsator = Pulsator()
    
    @IBOutlet weak var recordingButton: UIButton!
    @IBOutlet weak var numberLabel: NumberLabel!
    @IBOutlet weak var equationTextView: UITextView!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var progessLabel: UILabel!
    
    //IBOutlet Information
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.requestAuthorization()
        self.numberLabel.text = String(describing: viewModel.answer.value)
        self.equationTextView.text = ""
        self.progessLabel.text = "\(self.viewModel.numTimesCorrect.value)/\(self.viewModel.correctNeeded)"
        
        pulsator.position = self.recordingButton.center
        pulsator.numPulse = 5
        pulsator.radius = 100
        pulsator.backgroundColor = self.numberLabel.shadowColor?.cgColor
        view.layer.insertSublayer(pulsator, below: self.recordingButton.layer)
        
        viewModel.equation.signal.observeValues { equation in
            self.equationTextView.text = equation
        }
        viewModel.answer.signal.observeValues { answer in
            self.numberLabel.text = String(answer)
        }
        viewModel.numTimesCorrect.signal.observeValues { num in
            self.progressView.progress = Float(num)/Float(self.viewModel.correctNeeded)
            self.progessLabel.text = "\(num)/\(self.viewModel.correctNeeded)"
        }
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(longPress(_:)))
        longPressGesture.cancelsTouchesInView = false
        recordingButton.addGestureRecognizer(longPressGesture)
        
        viewModel.askForEquation()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        pulsator.position = self.recordingButton.center
    }
    
    @IBAction func longPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        switch  gestureRecognizer.state {
        case .began:
            print("BEGAN")
            viewModel?.startRecording(completion: {
                DispatchQueue.main.async {
                    self.equationTextView.text = ""
                    self.pulsator.start()
                }
            })
        case .ended:
            print("exited")
            viewModel.stopRecording(completion: {
                self.pulsator.stop()
            })
            viewModel.processEquation(completion: { correct, dismiss in
                if correct && dismiss {
                    self.viewModel.player?.stop()
                    self.dismiss(animated: true, completion: {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
                            let session = AVAudioSession.sharedInstance()
                            do {
                                // Configure the audio session for speech + tone
                                try session.setCategory(AVAudioSessionCategoryPlayback, with: AVAudioSessionCategoryOptions.defaultToSpeaker)
                            } catch let error as NSError {
                                print("Failed to set the audio session category and mode: \(error.localizedDescription)")
                            }
                        }
                    })
                } else if !correct {
                    self.numberLabel.wrongSolution()
                }
            })
        default:
            break
        }
    }
    
    @IBAction func showHelpDialog() {
        let helpVC = ViewController(nibName: "EquationHelpDialog", bundle: nil)
        let popup = PopupDialog(viewController: helpVC, buttonAlignment: .horizontal, transitionStyle: .zoomIn, gestureDismissal: true)
        //let helpButton = DefaultButton(title: "CLOSE", height: 60, dismissOnTap: true, action: nil)
        //popup.addButton(helpButton)
        present(popup, animated: true, completion: nil)
    }
}

extension String {
    func matches(_ regex: String) -> Bool {
        return self.range(of: regex, options: .regularExpression, range: nil, locale: nil) != nil
    }
    
    func replace(target: String, withString: String) -> String {
        return self.replacingOccurrences(of: target, with: withString, options: NSString.CompareOptions.literal, range: nil)
    }
}



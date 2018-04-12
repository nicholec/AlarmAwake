//
//  EquationRecognizerViewController.swift
//  AlarmAwake
//
//  Created by Nichole Clarke on 4/5/18.
//  Copyright © 2018 mac. All rights reserved.
//

import UIKit
import AVFoundation

class EquationRecognizerViewController: UIViewController {
    
    var viewModel: EquationRecognizerViewModel!
    
    @IBOutlet weak var recordingButton: UIButton!
    @IBOutlet weak var numberLabel: UILabel!
    @IBOutlet weak var equationTextView: UITextView!
    
    //IBOutlet Information
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.requestAuthorization()
        self.numberLabel.text = String(describing: viewModel.answer.value)
        self.equationTextView.text = ""
        
        viewModel.equation.signal.observeValues { equation in
            self.equationTextView.text = equation
        }
        viewModel.answer.signal.observeValues { answer in
            self.numberLabel.text = String(answer)
        }
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(longPress(_:)))
        longPressGesture.cancelsTouchesInView = false
        recordingButton.addGestureRecognizer(longPressGesture)
        
        viewModel.askForEquation()
    }
    
    @IBAction func longPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        switch  gestureRecognizer.state {
        case .began:
            print("BEGAN")
            viewModel?.startRecording(completion: {
                DispatchQueue.main.async {
                    self.equationTextView.text = ""
                }
            })
        case .ended:
            print("exited")
            viewModel.stopRecording()
            viewModel.processEquation(completion: { correct in
                if correct {
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
                }
            })
        default:
            break
        }
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



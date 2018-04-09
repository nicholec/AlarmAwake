//
//  EquationRecognizerViewController.swift
//  AlarmAwake
//
//  Created by Nichole Clarke on 4/5/18.
//  Copyright © 2018 mac. All rights reserved.
//

import UIKit

class EquationRecognizerViewController: UIViewController {
    
    var viewModel: EquationRecognizerViewModel?
    
    @IBOutlet weak var recordingButton: UIButton!
    @IBOutlet weak var numberLabel: UILabel!
    @IBOutlet weak var equationTextView: UITextView!
    
    //IBOutlet Information
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel?.requestAuthorization()
        self.numberLabel.text = String(describing: viewModel?.answer)
        self.equationTextView.text = ""
        
        viewModel?.equation.signal.observeValues { equation in
            self.equationTextView.text = equation
        }
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(longPress(_:)))
        longPressGesture.cancelsTouchesInView = false
        recordingButton.addGestureRecognizer(longPressGesture)
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
            viewModel?.stopRecording()
            viewModel?.processEquation(completion: { correct in
                if correct {
                    self.dismiss(animated: true)
                }
            })
        default:
            break
        }
    }
    
    
    
//    private func startRecording() {
//        DispatchQueue.main.async {
//            self.equation = ""
//            self.equationTextView.text = ""
//        }
//
//        if let recognitionTask = recognitionTask {
//            recognitionTask.cancel()
//            self.recognitionTask = nil
//        }
//
//        let node = audioEngine.inputNode
//        let recordingFormat = node.outputFormat(forBus: 0)
//
//        node.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [unowned self] buffer, _ in
//            self.request.append(buffer)
//        }
//
//        audioEngine.prepare()
//        do {
//            try audioEngine.start()
//            recognitionTask = speechRecognizer?.recognitionTask(with: request, delegate: self)
//        } catch (let error) {
//            print("There was a problem starting the recording: \(error.localizedDescription)")
//        }
//    }
    
//    internal func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didHypothesizeTranscription transcription: SFTranscription) {
//        equation = transcription.formattedString.replace(target: " one", withString: "1")
//        self.equationTextView.text = equation
//    }
    
//    private func stopRecording() {
//        audioEngine.stop()
//        audioEngine.inputNode.removeTap(onBus: 0)
//        request.endAudio()
//        recognitionTask?.cancel()
//        request = SFSpeechAudioBufferRecognitionRequest()
//    }
    
//    private func processEquation() {
//        var utterance = AVSpeechUtterance(string: "")
//        utterance.rate = 0.5
//        if equation.isEmpty {
//            utterance = AVSpeechUtterance(string: "Make sure you say an equation")
//            self.synth.speak(utterance)
//        } else {
//            SwiftTryCatch.try({
//                let expr = NSExpression(format: self.equation)
//                if let result = expr.expressionValue(with: [], context: nil) as? Double {
//                    if (self.answer <= 18 && self.equation.count - String(self.answer).count < 1) ||  self.equation.count - String(self.answer).count < 2 {
//                        utterance = AVSpeechUtterance(string: "Try a longer equation")
//                        self.synth.speak(utterance)
//                    } else {
//                        print(result)
//                        let response = "\(self.equation) equals \(Int(result)). \(Double(self.answer) == result ? "That's right!" : "Try again.")"
//                        utterance = AVSpeechUtterance(string: response)
//                        self.synth.speak(utterance)
//                        if Double(self.answer) == result {
//                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
//                                self.dismiss(animated: true)
//                            }
//                        }
//                    }
//                } else {
//                    utterance = AVSpeechUtterance(string: "Unable to process your equation: \(self.equation)")
//                    self.synth.speak(utterance)
//                }
//            }, catch: { (error) in
//                utterance = AVSpeechUtterance(string: "Unable to process your equation: \(self.equation)")
//                self.synth.speak(utterance)
//            }, finallyBlock: {
//                // close resources
//            })
//        }
//    }
}

extension String {
    func matches(_ regex: String) -> Bool {
        return self.range(of: regex, options: .regularExpression, range: nil, locale: nil) != nil
    }
    
    func replace(target: String, withString: String) -> String {
        return self.replacingOccurrences(of: target, with: withString, options: NSString.CompareOptions.literal, range: nil)
    }
}



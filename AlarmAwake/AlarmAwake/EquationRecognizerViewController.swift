//
//  EquationRecognizerViewController.swift
//  AlarmAwake
//
//  Created by mac on 4/5/18.
//  Copyright © 2018 mac. All rights reserved.
//

import UIKit
import AVFoundation
import Speech

class EquationRecognizerViewController: UIViewController {
    
    fileprivate var player: AVPlayer?
    let audioEngine = AVAudioEngine()
    let speechRecognizer = SFSpeechRecognizer()
    let request = SFSpeechAudioBufferRecognitionRequest()
    var recognitionTask: SFSpeechRecognitionTask?
    
    @IBOutlet weak var recordingButton: UIButton!
    @IBOutlet weak var numberLabel: UILabel!
    @IBOutlet weak var equationLabel: UILabel!
    
    //IBOutlet Information
    
    override func viewDidLoad() {
        super.viewDidLoad()
        requestAuthorization()
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(longPress(_:)))
        recordingButton.addGestureRecognizer(longPressGesture)
    }
    
    @IBAction func longPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        print("We made it here.")
        switch  gestureRecognizer.state {
        case .began:
            startRecording()
        case .ended:
            stopRecording()
        default:
            break
        }
    }
    
    func longPress() {
        
    }
    
    private func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [unowned self] authStatus in
            switch authStatus {
            case .authorized:
                self.startRecording()
            case .denied:
                print("Denied")
            // show an alert instead
            case .restricted:
                print("Not available")
            // show an alert instead
            case .notDetermined:
                print("lol hm")
            }
        }
    }
    
    private func startRecording() {
        self.equationLabel.text = ""
        
        let node = audioEngine.inputNode
        let recordingForm = node.outputFormat(forBus: 0)
        
        node.installTap(onBus: 0, bufferSize: 1024, format: recordingForm) { [unowned self] buffer, _ in
            self.request.append(buffer)
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
            recognitionTask = speechRecognizer?.recognitionTask(with: request) { [unowned self] (result, _) in
                if let transcription = result?.bestTranscription {
                    self.equationLabel.text = "Your equation: \(transcription.formattedString)"
                }
            }
        } catch (let error) {
            print("There was a problem starting the recording: \(error.localizedDescription)")
        }
    }
    
    private func stopRecording() {
        audioEngine.stop()
        request.endAudio()
        recognitionTask?.cancel()
    }
}

//
//  MainAlarmViewController.swift
//  AlarmAwake
//
//  Created by Nichole on 4/7/18.
//  Copyright © 2018 mac. All rights reserved.
//

import Foundation
import UIKit
import AudioToolbox
import AVFoundation

class MainAlarmViewController: UIViewController {
    
    var timer = Timer()
    var time = 5
    var timerIsRunning = false
    var player: AVAudioPlayer?
    @IBOutlet weak var difficultySegControl: UISegmentedControl!
    @IBOutlet weak var numberTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.addDoneButtonOnKeyboard()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "startEquationRecognizer" {
            if let viewController = segue.destination as? EquationRecognizerViewController {
                let viewModel = EquationRecognizerViewModel(player: player, difficultySetting: difficultySegControl.selectedSegmentIndex, numCorrectNeeded: Int(self.numberTextField.text ?? "1")!)
                viewController.viewModel = viewModel
            }
        }
    }
    
    @IBAction func startTimer() {
        if !timerIsRunning {
            timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: (#selector(ringTimer)), userInfo: nil, repeats: true)
            timerIsRunning = true
        }
    }
    
    @objc func ringTimer() {
        time -= 1
        if time == 0 {
            timer.invalidate()
            time = 5
            // start ringer
            timerIsRunning = false
            playTone()
        }
    }
    
    func playTone() {
        guard let url = Bundle.main.url(forResource: "Citrine", withExtension: "mp3") else {
            print("Error, unable to loud alarm tone")
            return
        }
        
        do {
            let session = AVAudioSession.sharedInstance()
            do {
                // Configure the audio session for speech +
                try session.setCategory(AVAudioSessionCategoryPlayAndRecord, with: AVAudioSessionCategoryOptions.defaultToSpeaker)
            } catch let error as NSError {
                print("Failed to set the audio session category and mode: \(error.localizedDescription)")
            }
            player = try AVAudioPlayer(contentsOf: url)
            guard let player = player else { return }
            player.numberOfLoops = -1
            player.volume = 1.0
            player.prepareToPlay()
            player.play()
            self.performSegue(withIdentifier: "startEquationRecognizer", sender: nil)
        } catch (let error) {
            print(error.localizedDescription)
        }
    }
}

extension MainAlarmViewController {
    func addDoneButtonOnKeyboard() {
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 320, height: 50))
        doneToolbar.barStyle       = UIBarStyle.default
        let flexSpace              = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem  = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.done, target: self, action: #selector(self.doneButtonAction))
        
        var items = [UIBarButtonItem]()
        items.append(flexSpace)
        items.append(done)
        
        doneToolbar.items = items
        doneToolbar.sizeToFit()
        
        self.numberTextField.inputAccessoryView = doneToolbar
    }
    
    @objc func doneButtonAction() {
        self.numberTextField.resignFirstResponder()
    }
}

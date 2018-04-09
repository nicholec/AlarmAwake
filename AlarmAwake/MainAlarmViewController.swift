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
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "startEquationRecognizer" {
            if let viewController = segue.destination as? EquationRecognizerViewController {
                let viewModel = EquationRecognizerViewModel(player: player)
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
            playTone()
        }
    }
    
    func playTone() {
        guard let url = Bundle.main.url(forResource: "Citrine", withExtension: "mp3") else {
            print("Error, unable to loud alarm tone")
            return
        }
        
        do {
            player = try AVAudioPlayer(contentsOf: url)
            guard let player = player else { return }
            player.numberOfLoops = -1
            player.prepareToPlay()
            player.play()
            self.performSegue(withIdentifier: "startEquationRecognizer", sender: nil)
        } catch (let error) {
            print(error.localizedDescription)
        }
    }
}
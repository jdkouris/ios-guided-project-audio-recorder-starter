//
//  ViewController.swift
//  AudioRecorder
//
//  Created by Paul Solt on 10/1/19.
//  Copyright © 2019 Lambda, Inc. All rights reserved.
//

import UIKit
import AVFoundation

class AudioRecorderController: UIViewController {
    
    
    
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var timeElapsedLabel: UILabel!
    @IBOutlet weak var timeRemainingLabel: UILabel!
    @IBOutlet weak var timeSlider: UISlider!
    @IBOutlet weak var audioVisualizer: AudioVisualizer!
	
	private lazy var timeIntervalFormatter: DateComponentsFormatter = {
        // NOTE: DateComponentFormatter is good for minutes/hours/seconds
        // DateComponentsFormatter is not good for milliseconds, use DateFormatter instead)
        
		let formatting = DateComponentsFormatter()
		formatting.unitsStyle = .positional // 00:00  mm:ss
		formatting.zeroFormattingBehavior = .pad
		formatting.allowedUnits = [.minute, .second]
		return formatting
	}()
	
	override func viewDidLoad() {
		super.viewDidLoad()
        
        // Use a font that won't jump around as values change
        timeElapsedLabel.font = UIFont.monospacedDigitSystemFont(ofSize: timeElapsedLabel.font.pointSize,
                                                          weight: .regular)
        timeRemainingLabel.font = UIFont.monospacedDigitSystemFont(ofSize: timeRemainingLabel.font.pointSize,
                                                                   weight: .regular)
        
        loadAudio()
        updateViews()
	}

    // MARK: - Playback
    
    var audioPlayer: AVAudioPlayer?
    var timer: Timer?
    
    private func loadAudio() {
        let songURL = Bundle.main.url(forResource: "piano", withExtension: "mp3")!
        audioPlayer = try! AVAudioPlayer(contentsOf: songURL)
        audioPlayer?.delegate = self
    }
    
    var isPlaying: Bool {
        audioPlayer?.isPlaying ?? false
    }
    
    func play() {
        audioPlayer?.play()
        updateViews()
        startTimer()
    }
    
    func pause() {
        audioPlayer?.pause()
        updateViews()
        cancelTimer()
    }
    
    func playPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    private func startTimer() {
        cancelTimer()
        timer = Timer.scheduledTimer(timeInterval: 0.03, target: self, selector: #selector(updateTimer(timer:)), userInfo: nil, repeats: true)
    }
    
    @objc private func updateTimer(timer: Timer) {
        updateViews()
    }
    
    private func cancelTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    
    // MARK: - Recording

    var audioRecorder: AVAudioRecorder?
    var recordURL: URL?
    
    var isRecording: Bool {
        return audioRecorder?.isRecording ?? false
    }
    
    func record() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        let name = ISO8601DateFormatter.string(from: Date(), timeZone: .current, formatOptions: [.withInternetDateTime])
        let file = documents.appendingPathComponent(name).appendingPathExtension("caf")
        recordURL = file
        
        print("reord: \(file)")
        
        let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
        audioRecorder = try! AVAudioRecorder(url: file, format: format)
        audioRecorder?.delegate = self
        audioRecorder?.record()
        updateViews()
    }
    
    func stop() {
        audioRecorder?.stop()
        audioRecorder = nil
        updateViews()
    }
    
    func recordToggle() {
        if isRecording {
            stop()
        } else {
            record()
        }
    }
    
    // MARK: - Actions

    @IBAction func togglePlayback(_ sender: Any) {
        playPause()
	}
    
    @IBAction func toggleRecording(_ sender: Any) {
        recordToggle()
    }
    
    // MARK: - Private
    
    private func updateViews() {
        let playButtonTitle = isPlaying ? "Pause" : "Play"
        playButton.setTitle(playButtonTitle, for: .normal)
        
        let elapsedTime = audioPlayer?.currentTime ?? 0
        timeElapsedLabel.text = timeIntervalFormatter.string(from: elapsedTime)
        
        timeSlider.minimumValue = 0
        timeSlider.maximumValue = Float(audioPlayer?.duration ?? 0)
        timeSlider.value = Float(elapsedTime)
        
        let recordButtonTitle = isRecording ? "Stop" : "Record"
        recordButton.setTitle(recordButtonTitle, for: .normal)
        
        timeRemainingLabel.text = timeIntervalFormatter.string(from: (audioPlayer?.duration ?? 0) - elapsedTime)
    }
}

extension AudioRecorderController: AVAudioPlayerDelegate {
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        updateViews()
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        if let error = error {
            print("Audio PLayer error: \(error)")
        }
    }
    
}

extension AudioRecorderController: AVAudioRecorderDelegate {
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        if let error = error {
            print("Audio recorder error: \(error)")
        }
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        print("Finished recording")
        if let recordURL = recordURL {
            audioPlayer = try! AVAudioPlayer(contentsOf: recordURL)
            updateViews()
        }
    }
    
}

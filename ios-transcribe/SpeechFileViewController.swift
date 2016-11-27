//
//	SpeechFileViewController.swift
//	ios-transcribe
//
//	The MIT License (MIT)
//
//	Copyright (c) 2016 Electricwoods LLC, Kaz Yoshikawa.
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy 
//	of this software and associated documentation files (the "Software"), to deal 
//	in the Software without restriction, including without limitation the rights 
//	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
//	copies of the Software, and to permit persons to whom the Software is 
//	furnished to do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in 
//	all copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
//	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
//	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, 
//	WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//	THE SOFTWARE.
//

import UIKit
import AVFoundation

class SpeechFileViewController: UIViewController {

	@IBOutlet weak var textView: UITextView!

	var soundFilePath: String?
	
	lazy var audioPlayer: AVAudioPlayer? = {
		if let soundFilePath = self.soundFilePath {
			let fileURL = URL(fileURLWithPath: soundFilePath)
			return try? AVAudioPlayer(contentsOf: fileURL)
		}
		return nil
	}()

	override func viewDidLoad() {
		super.viewDidLoad()

		if let textfile = self.textfile, FileManager.default.fileExists(atPath: textfile) {
			self.textView.text = try? String(contentsOfFile: textfile, encoding: .utf8)
		}
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
	}

	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		self.navigationItem.title = self.filename
	}
	
	// MARK: -

	var filename: String? {
		return (self.soundFilePath as NSString?)?.lastPathComponent
	}
	
	var textfile: String? {
		return (self.soundFilePath as NSString?)?.appendingPathExtension("txt")
	}
	
	// MARK: -

	@IBAction func playAction(_ sender: UIBarButtonItem) {
		if let audioPlayer = self.audioPlayer {
			audioPlayer.prepareToPlay()
			audioPlayer.play()
		}
	}

}

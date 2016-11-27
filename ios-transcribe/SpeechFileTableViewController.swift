//
//	SpeechFileTableViewController.swift
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
import Speech


let localekey = "settings.locale"

class SpeechFileTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

	@IBOutlet weak var tableView: UITableView!
	@IBOutlet weak var progressView: UIProgressView!
	@IBOutlet weak var languageButtonItem: UIBarButtonItem!

	lazy var english: Locale = {
		return Locale(identifier: "en-US")
	}()

	var locale: Locale {
		get {
			if let code = UserDefaults.standard.string(forKey: localekey) {
				return Locale(identifier: code)
			}
			return Locale(identifier: "ja-JP")
		}
		set {
			self.speechRecognizer = SFSpeechRecognizer(locale: newValue)
			UserDefaults.standard.set(newValue.languageCode, forKey: localekey)
			UserDefaults.standard.synchronize()
			if self.isViewLoaded {
				self.updateLanguageLabel()
			}
		}
	}

	var files = [String]()
	var speechRecognizer: SFSpeechRecognizer!

	// MARK: -

	override func viewDidLoad() {
		print("document directory: \(self.documentDirectory)")

		super.viewDidLoad()

		self.updateList()

		if TARGET_OS_SIMULATOR != 0 {
			let alert = UIAlertController(title: "Caution", message: "Speach Recoginer may not work on simulator.", preferredStyle: .alert)
			alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
			self.present(alert, animated: true, completion: nil)
		}
		self.progressView.isHidden = true
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		self.updateLanguageLabel()
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}

	func updateLanguageLabel() {
		self.languageButtonItem.title = self.english.localizedString(forIdentifier: self.locale.identifier)
	}

	// MARK: -

	var documentDirectory: String {
		return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
	}

	@IBAction func reloadAction(_ sender: UIBarButtonItem) {
		self.updateList()
		self.tableView.reloadData()
	}
	
	func updateList() {
		let directory = self.documentDirectory
		var files = [String]()
		let items = try! FileManager.default.contentsOfDirectory(atPath: directory)
		for item in items {
			if (item as NSString).pathExtension.lowercased() == "mp3" {
				files.append((directory as NSString).appendingPathComponent(item))
			}
		}
		self.files = files
		print("files = \(files.count)")
	}

	@IBAction func processAction(_ sender: UIBarButtonItem) {

		SFSpeechRecognizer.requestAuthorization { (status) in
			switch status {
			case .authorized:
				sender.isEnabled = false
				DispatchQueue.global(qos: .default).async {
					self.processSoundFiles()
					DispatchQueue.main.async {
						sender.isEnabled = true
					}
				}
			default:
				let alert = UIAlertController(title: "Alert", message: "Permission denied for accessing Speech recognizer.", preferredStyle: .alert)
				alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
				self.present(alert, animated: true, completion: nil)
				break
			}
		}

	}

	func processSoundFiles() {
		DispatchQueue.main.sync {
			self.progressView.isHidden = false
			self.progressView.progress = 0
		}
		let semaphore = DispatchSemaphore(value: 1)
		for (index, file) in self.files.enumerated() {
			let transcriptPath = (file as NSString).appendingPathExtension("txt")!
			let filename = (file as NSString).lastPathComponent
			if FileManager.default.fileExists(atPath: transcriptPath) {
				if let string = try? String(contentsOfFile: transcriptPath, encoding: .utf8) {
					print("\(index)\t\(filename)\t\(string)")
					DispatchQueue.main.async {
						self.progressView.progress = Float(index) / Float(self.files.count)
					}
				}
			}
			else {
				let fileURL = URL(fileURLWithPath: file)
				let request = SFSpeechURLRecognitionRequest(url: fileURL)
				semaphore.wait()
				self.speechRecognizer.recognitionTask(with: request, resultHandler: { (result, error) in
					if let error = error {
						print("\(index)\t\(filename)\t\(error)")
						DispatchQueue.main.async {
							self.progressView.progress = Float(index) / Float(self.files.count)
						}
						semaphore.signal()
					}
					else if let result = result, result.isFinal {
						let transcription = result.bestTranscription
						let string = transcription.formattedString
						let transcriptPathURL = URL(fileURLWithPath: transcriptPath)
						try! string.write(to: transcriptPathURL, atomically: true, encoding: .utf8)
						print("\(index)\t\(filename)\t\(string)")
						DispatchQueue.main.async {
							let indexPath = IndexPath(row: index, section: 0)
							self.tableView.reloadRows(at: [indexPath], with: .none)
						}
						DispatchQueue.main.async {
							self.progressView.progress = Float(index) / Float(self.files.count)
						}
						semaphore.signal()
					}
				})
			}
		}
		print("finished processing files")
		DispatchQueue.main.sync {
			self.progressView.isHidden = true
		}
	}

	// MARK: -

	@IBAction func chooseLocale(_ sender: AnyObject) {
		let viewController = self.storyboard?.instantiateViewController(withIdentifier: "LocalChoiceView") as! LocalChoiceViewController
		viewController.locale = self.locale
		viewController.delegate = self
		self.navigationController?.pushViewController(viewController, animated: true)
	}

	// MARK: -
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.files.count
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let file = self.files[indexPath.row] as NSString
		let cell = self.tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
		cell.textLabel?.text = file.lastPathComponent
		let transcriptPath = file.appendingPathExtension("txt")!
		if FileManager.default.fileExists(atPath: transcriptPath), let text = try? String(contentsOfFile: transcriptPath, encoding: .utf8) {
			cell.detailTextLabel?.text = text
		}
		else {
			cell.detailTextLabel?.text = nil
		}
		return cell
	}

	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let soundFile = self.files[indexPath.row]
		let viewController = self.storyboard!.instantiateViewController(withIdentifier: "SpeechFileView") as! SpeechFileViewController
		viewController.soundFilePath = soundFile
		self.navigationController?.pushViewController(viewController, animated: true)
	}

}

extension SpeechFileTableViewController: SFSpeechRecognizerDelegate {

	public func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
		
	}

}

extension SpeechFileTableViewController: LocalChoiceViewControllerDelegate {

	func localChoiceViewControllerDidChooseLocal(_ locale: Locale) {
		self.locale = locale
	}

}





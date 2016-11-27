//
//	LocalChoiceViewController.swift
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


protocol LocalChoiceViewControllerDelegate: class {
	func localChoiceViewControllerDidChooseLocal(_ local: Locale)
}


class LocalChoiceViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

	@IBOutlet weak var tableView: UITableView!
	weak var delegate: LocalChoiceViewControllerDelegate?

	var locale: Locale! {
		didSet {
			print("\(locale.identifier)")
		}
	}

	lazy var english: Locale = {
		return Locale(identifier: "en-US")
	}()

	private var supportedLocales: [Locale] {
		return Array(SFSpeechRecognizer.supportedLocales())
	}

	lazy var locales: [Locale] = {
		return self.supportedLocales.sorted { (a, b) -> Bool in
			if	let la = self.english.localizedString(forIdentifier: a.identifier),
				let lb = self.english.localizedString(forIdentifier: b.identifier) {
				return la < lb
			}
			return false
		}
	}()

	// MARK: -

	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		assert(self.locale != nil)
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		let index = self.locales.index(of: self.locale)!
		let indexPath = IndexPath(row: index, section: 0)
		self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .middle)
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}
	
	@IBAction func saveAction(_ sender: Any) {
		self.delegate?.localChoiceViewControllerDidChooseLocal(self.locale)
		_ = self.navigationController?.popViewController(animated: true)
	}

	@IBAction func cancelAction(_ sender: Any) {
		_ = self.navigationController?.popViewController(animated: true)
	}

	// MARK: -
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.locales.count
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let locale: Locale = self.locales[indexPath.row]
		let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
		let english = Locale(identifier: "en")
		let title = english.localizedString(forIdentifier: locale.identifier)
		cell.textLabel?.text = title
		cell.detailTextLabel?.text = locale.identifier
		return cell
	}

	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		self.locale = self.locales[indexPath.row]
	}

}

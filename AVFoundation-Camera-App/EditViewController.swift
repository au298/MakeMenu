//
//  EditViewController.swift
//  AVFoundation-Camera-App2
//
//  Created by 古田聖直 on 2024/06/08.
//

import UIKit

class EditViewController: UIViewController {
    
    @IBOutlet weak var editTextField: UITextField!
    
    var receivedText: String?  // 受け取るテキスト用のプロパティ
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // 受け取ったテキストをeditTextFieldに設定
        if let text = receivedText {
            editTextField.text = text
        }
        
        let toolbar = UIToolbar()
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace,
                                    target: nil,
                                    action: nil)
        
        let done = UIBarButtonItem(title: "完了",
                                   style: .done,
                                   target: self,
                                   action: #selector(didTapDoneButton))
        
        toolbar.items = [space, done]
        toolbar.sizeToFit()
        editTextField.inputAccessoryView = toolbar
        
    }
    
    @IBAction func backButtonTapped(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func didTapDoneButton() {
        editTextField.resignFirstResponder()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toMakeMenu" {
            if let makemenuVC = segue.destination as? MakemenuViewController {
                makemenuVC.receivedText = editTextField.text
            }
        }
    }
}

import UIKit

class ResultViewController: UIViewController {
    
    @IBOutlet weak var resultTextView: UITextView!
    
    var recognizedObject: [String]?  // 配列として受け取る
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 配列の内容を改行で連結して表示
        if let recognizedObjects = recognizedObject {
            resultTextView.text = recognizedObjects.joined(separator: "\n")
        }
    }
    
    @IBAction func backButtonTapped(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
}

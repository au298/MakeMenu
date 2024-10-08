import UIKit

protocol ChatGPTDelegate {
    func fetchIdea(from prompt: String) async -> String
}

class MakemenuViewController: UIViewController {
    let chatGPT: ChatGPTDelegate = ChatGPT()
    
    var receivedText: String?
    @IBOutlet weak var menuText: UILabel!
    
    @IBAction func backButtonTapped(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        generateMenu()
    }

    func generateMenu() {
        // ChatGPT APIリクエストを送信するメソッドを呼び出します
        
        Task {
            self.menuText.text = await fetchMenuIdeas(for: receivedText ?? "")
        }
    }

    func fetchMenuIdeas(for text: String) async -> String {
        return await chatGPT.fetchIdea(from: text)
    }
}

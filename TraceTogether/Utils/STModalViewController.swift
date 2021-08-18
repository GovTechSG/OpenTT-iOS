//
//  STModalViewController.swift
//  OpenTraceTogether

import UIKit

class STModalViewController: UIViewController {

    @IBOutlet weak var mainTextLabel: UILabel!
    let mainText: String?

    init(_ inputText: String) {
      mainText = inputText
      super.init(nibName: "STModalViewController", bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        mainTextLabel.text = mainText
        // Do any additional setup after loading the view.
    }

    override func awakeFromNib() {
      super.awakeFromNib()
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

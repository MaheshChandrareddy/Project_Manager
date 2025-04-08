//
//  NewProjectViewController.swift
//  ZenTask
//
//  Created by ORDOFY on 04/04/25.
//

import UIKit
import CoreData

class NewProjectViewController: UIViewController {

    @IBOutlet weak var nameTextField: UITextField!
    
    var name: String?
    var project: Project?
    var flow: flow = .add
    
    var refreshDataCallBack: (() -> ())?

    override func viewDidLoad() {
        super.viewDidLoad()
        nameTextField.text = flow == .edit ? name : ""
    }

    @IBAction func saveButtonTapped(_ sender: UIButton) {
        guard let name = nameTextField.text, !name.isEmpty else {
            showAlert(message: "Please enter a project name")
            return
        }
        switch flow{
        case .add:
            ProjectService.addProject(name: name, startDate: Date(), endDate: Calendar.current.date(byAdding: .minute, value: 1, to: Date())!){
                DispatchQueue.main.async {
                    self.refreshDataCallBack?()
                    self.dismiss(animated: true)
                }
            }
        case .edit:
            guard let project = project else { return}
            ProjectService.updateProject(project: project, name: name, startDate: Date(), endDate: Calendar.current.date(byAdding: .minute, value: 1, to: Date())!){
                DispatchQueue.main.async {
                    self.refreshDataCallBack?()
                    self.dismiss(animated: true)
                }
            }
        }
    }
    
    func showAlert(message: String) {
        let alert = UIAlertController(title: "Validation", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

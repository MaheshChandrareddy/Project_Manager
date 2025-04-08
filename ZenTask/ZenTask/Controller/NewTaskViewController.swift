//
//  NewTaskViewController.swift
//  ZenTask
//
//  Created by ORDOFY on 04/04/25.
//

import UIKit
import CoreData

class NewTaskViewController: UIViewController {

    @IBOutlet weak var titleTextField: UITextField!
    
    var project: Project!
    var task: Task?
    var refreshDataCallBack: (()->())?
    var flow: flow = .add
    var name: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        titleTextField.text = flow == .edit ? name : ""
    }

    @IBAction func saveButtonTapped(_ sender: UIButton) {
        guard let title = titleTextField.text, !title.isEmpty else {
            showAlert(message: "Please enter a task title")
            return
        }
        guard let project = self.project else {
            print("Project is nil")
            return
        }
        
        switch flow{
        case .add:
            TaskService.addTask(title: title, project: project){
                DispatchQueue.main.async {
                    self.refreshDataCallBack?()
                    self.dismiss(animated: true)
                }
            }
        case .edit:
            guard let task = task else {return}
            TaskService.updateTaskName(task: task, newName: title){
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

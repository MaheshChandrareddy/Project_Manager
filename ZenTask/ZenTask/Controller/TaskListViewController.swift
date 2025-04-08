//
//  TaskListViewController.swift
//  ZenTask
//
//  Created by ORDOFY on 04/04/25.
//

import UIKit
import CoreData

class TaskListViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!

    var project: Project!
    var tasks: [Task] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = project.name
        configureTableView()
        fetchTasks()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchTasks()
    }

    private func configureTableView() {
        tableView.register(UINib(nibName: "TaskTableViewCell", bundle: .main), forCellReuseIdentifier: "TaskTableViewCell")
    }

    func fetchTasks() {
        TaskService.fetchTasks(for: project) { [weak self] fetchedTasks in
            self?.tasks = fetchedTasks
            self?.tableView.reloadData()
        }
    }

    @IBAction func addTaskButtonHandler(_ sender: Any) {
        guard let vc = UIStoryboard(name: "Main", bundle: .main).instantiateViewController(withIdentifier: "NewTaskViewController") as? NewTaskViewController else { return }
        vc.refreshDataCallBack = {
            self.fetchTasks()
        }
        vc.project = project
        vc.flow = .add
        if #available(iOS 16.0, *) {
            vc.sheetPresentationController?.detents = [.custom(resolver: { context in
                return 190
            })]
        } else {
            // Fallback on earlier versions
        }
        navigationController?.present(vc, animated: true)
    }
    
    @objc func editProjectButtonHandler(_ sender: UIButton){
        guard let vc = UIStoryboard(name: "Main", bundle: .main).instantiateViewController(withIdentifier: "NewTaskViewController") as? NewTaskViewController else { return }
        vc.refreshDataCallBack = {
            self.fetchTasks()
        }
        vc.project = project
        vc.flow = .edit
        vc.task = tasks[sender.tag]
        vc.name = tasks[sender.tag].title
        if #available(iOS 16.0, *) {
            vc.sheetPresentationController?.detents = [.custom(resolver: { context in
                return 190
            })]
        } else {
            // Fallback on earlier versions
        }
        navigationController?.present(vc, animated: true)
    }
    
    @objc func deleteProjectButtonHandler(_ sender: UIButton){
        let index = sender.tag
        TaskService.delete(task: tasks[index] ) {
            self.tasks.remove(at: index)
            self.tableView.reloadData()
        }
    }
}

extension TaskListViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tasks.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskTableViewCell", for: indexPath) as! TaskTableViewCell
        cell.configure(with: tasks[indexPath.row])
        cell.editButton.tag = indexPath.row
        cell.deleteButton.tag = indexPath.row
        cell.editButton.addTarget(self, action: #selector(editProjectButtonHandler), for: .touchUpInside)
        cell.deleteButton.addTarget(self, action: #selector(deleteProjectButtonHandler), for: .touchUpInside)
        return cell
    }
}

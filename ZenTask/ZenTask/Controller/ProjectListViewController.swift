//
//  ProjectListViewController.swift
//  ZenTask
//
//  Created by ORDOFY on 04/04/25.
//

import UIKit

protocol DataRefreshable: AnyObject {
    func refreshData()
}

class ProjectListViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!

    var projects: [Project] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Listen to sync update
           NotificationCenter.default.addObserver(
               self,
               selector: #selector(reloadUI),
               name: .iCloudSyncDidUpdate,
               object: nil
           )
        tableView.register(UINib(nibName: "ProjectTableViewCell", bundle: .main), forCellReuseIdentifier: "ProjectTableViewCell")
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        loadProjects()
    }

    func loadProjects() {
        ProjectService.fetchProjects { [weak self] Project in
            self?.projects = Project
            self?.tableView.reloadData()
        }
    }

    @IBAction func addProjectButtonTapped(_ sender: UIButton) {
        guard let vc = UIStoryboard(name: "Main", bundle: .main).instantiateViewController(withIdentifier: "NewProjectViewController") as? NewProjectViewController else { return }
        // to refresh data
        vc.refreshDataCallBack = {
            self.loadProjects()
        }
        if #available(iOS 16.0, *) {
            vc.sheetPresentationController?.detents = [.custom(resolver: { context in
                return 190
            })]
        } else {
            // Fallback on earlier versions
        }
        navigationController?.present(vc, animated: true)
    }
    
    @objc func reloadUI() {
        loadProjects() // your method that reads from Core Data
    }
    
    @objc func editProjectButtonHandler(_ sender: UIButton){
        let index = sender.tag
        let selectedProject = projects[index]
        guard let vc = UIStoryboard(name: "Main", bundle: .main).instantiateViewController(withIdentifier: "NewProjectViewController") as? NewProjectViewController else { return }
        // to refresh data
        vc.flow = .edit
        vc.project = selectedProject
        vc.name = selectedProject.name
        vc.refreshDataCallBack = {
            self.loadProjects()
        }
        // preseting the view control
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
        ProjectService.deleteProject(projects[index] ) {
            self.projects.remove(at: index)
            self.tableView.reloadData()
        }
    }
}

// MARK: - UITableViewDataSource
extension ProjectListViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return projects.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProjectTableViewCell", for: indexPath) as! ProjectTableViewCell
        let project = projects[indexPath.row]
        cell.textLabel?.text = project.name ?? "Unnamed Project"
        cell.editButton.tag = indexPath.row
        cell.deleteButton.tag = indexPath.row
        cell.editButton.addTarget(self, action: #selector(editProjectButtonHandler), for: .touchUpInside)
        cell.deleteButton.addTarget(self, action: #selector(deleteProjectButtonHandler), for: .touchUpInside)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedProject = projects[indexPath.row]
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(identifier: "TaskListViewController") as! TaskListViewController
        vc.project = selectedProject
        navigationController?.pushViewController(vc, animated: true)
    }
}

//
//  TaskTableViewCell.swift
//  ZenTask
//
//  Created by ORDOFY on 04/04/25.
//

import UIKit

class TaskTableViewCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dueDateLabel: UILabel!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    
    func configure(with task: Task) {
        titleLabel.text = task.title
        dueDateLabel.text = task.isCompleted ? "Completed" : "Pending"
    }
}

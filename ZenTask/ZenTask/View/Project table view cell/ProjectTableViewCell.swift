//
//  ProjectTableViewCell.swift
//  ZenTask
//
//  Created by ORDOFY on 04/04/25.
//

import UIKit

class ProjectTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func configure(with project: Project) {
        titleLabel.text = project.name
    }
}

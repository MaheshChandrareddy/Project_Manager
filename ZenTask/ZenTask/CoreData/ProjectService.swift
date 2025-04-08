//
//  ProjectService.swift
//  ZenTask
//
//  Created by ORDOFY on 04/04/25.
//

import Foundation
import CoreData

class ProjectService {

    // MARK: - Fetch All Projects
    static func fetchProjects(completion: @escaping ([Project]) -> Void) {
        CoreDataManager.shared.performBackgroundTask { context in
            let request: NSFetchRequest<Project> = Project.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: true)]

            do {
                let results = try context.fetch(request)
                let mainContext = CoreDataManager.shared.context
                let converted = results.map { mainContext.object(with: $0.objectID) as! Project }
                DispatchQueue.main.async {
                    completion(converted)
                }
            } catch {
                print(" Error fetching projects: \(error)")
                DispatchQueue.main.async {
                    completion([])
                }
            }
        }
    }

    // MARK: - Add New Project
    static func addProject(name: String, startDate: Date, endDate: Date, completion: (() -> Void)? = nil) {
        CoreDataManager.shared.performBackgroundTask { context in
            let project = Project(context: context)
            project.name = name
            project.startDate = startDate
            project.endDate = endDate

            do {
                try context.save()
                DispatchQueue.main.async {
                    completion?()
                }
            } catch {
                print("Error saving project: \(error)")
            }
        }
    }

    // MARK: - Update Project
    static func updateProject(project: Project, name: String?, startDate: Date?, endDate: Date?, completion: (() -> Void)? = nil) {
        CoreDataManager.shared.performBackgroundTask { context in
            guard let projectInContext = context.object(with: project.objectID) as? Project else { return }

            if let name = name {
                projectInContext.name = name
            }
            if let start = startDate {
                projectInContext.startDate = start
            }
            if let end = endDate {
                projectInContext.endDate = end
            }

            do {
                try context.save()
                DispatchQueue.main.async {
                    completion?()
                }
            } catch {
                print("Error updating project: \(error)")
            }
        }
    }

    // MARK: - Delete Project (and its Tasks)
    static func deleteProject(_ project: Project, completion: (() -> Void)? = nil) {
        CoreDataManager.shared.performBackgroundTask { context in
            let projectObj = context.object(with: project.objectID)
            context.delete(projectObj)

            do {
                try context.save()
                DispatchQueue.main.async {
                    completion?()
                }
            } catch {
                print("Error deleting project: \(error)")
            }
        }
    }

    // MARK: - Batch Delete All Projects
    static func deleteAllProjects(completion: (() -> Void)? = nil) {
        CoreDataManager.shared.performBackgroundTask { context in
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Project.fetchRequest()
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            deleteRequest.resultType = .resultTypeObjectIDs

            do {
                let result = try context.execute(deleteRequest) as? NSBatchDeleteResult
                let objectIDs = result?.result as? [NSManagedObjectID] ?? []

                let changes: [AnyHashable: Any] = [
                    NSDeletedObjectsKey: objectIDs
                ]
                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [CoreDataManager.shared.context])

                DispatchQueue.main.async {
                    completion?()
                }
            } catch {
                print("Error batch deleting projects: \(error)")
            }
        }
    }

    // MARK: - Lightweight Fetch: Only Project Names
    static func fetchProjectNames(completion: @escaping ([String]) -> Void) {
        CoreDataManager.shared.performBackgroundTask { context in
            let request = NSFetchRequest<NSDictionary>(entityName: "Project")
            request.resultType = .dictionaryResultType
            request.propertiesToFetch = ["name"]

            do {
                let results = try context.fetch(request)
                let names = results.compactMap { $0["name"] as? String }
                DispatchQueue.main.async {
                    completion(names)
                }
            } catch {
                print("Failed to fetch project names: \(error)")
                DispatchQueue.main.async {
                    completion([])
                }
            }
        }
    }
}

//
//  TaskService.swift
//  ZenTask
//
//  Created by ORDOFY on 04/04/25.
//

import Foundation
import CoreData

class TaskService {
    // MARK: - Add New Task
    static func addTask(title: String, project: Project, completion: (() -> Void)? = nil) {
        CoreDataManager.shared.performBackgroundTask { context in
            guard let projectInContext = context.object(with: project.objectID) as? Project else { return }

            let task = Task(context: context)
            task.title = title
            task.isCompleted = false
            task.createdAt = Date()
            task.project = projectInContext

            do {
                try context.save()
                DispatchQueue.main.async {
                    completion?()
                }
            } catch {
                print("Error saving task: \(error)")
            }
        }
    }

    // MARK: - Fetch Tasks for a Project
    static func fetchTasks(for project: Project, completion: @escaping ([Task]) -> Void) {
        CoreDataManager.shared.performBackgroundTask { context in
            guard let projectInContext = context.object(with: project.objectID) as? Project else {
                DispatchQueue.main.async { completion([]) }
                return
            }

            // Fetch related tasks directly from the relationship
            let tasksSet = projectInContext.tasks as? Set<Task> ?? []
            let sortedTasks = tasksSet.sorted { ($0.title ?? "") < ($1.title ?? "") }

            // Convert back to main context if needed
            let mainContext = CoreDataManager.shared.context
            let mainContextTasks = sortedTasks.map { mainContext.object(with: $0.objectID) as! Task }

            DispatchQueue.main.async {
                completion(mainContextTasks)
            }
        }
    }


    // MARK: - Fetch Only Task Titles (Lightweight Fetch)
    static func fetchTaskSpecificInfo(for project: Project, completion: @escaping ([String]) -> Void) {
        CoreDataManager.shared.performBackgroundTask { context in
            guard let projectInContext = context.object(with: project.objectID) as? Project else {
                DispatchQueue.main.async { completion([]) }
                return
            }

            let request = NSFetchRequest<NSDictionary>(entityName: "Task")
            request.resultType = .dictionaryResultType // light weight
            request.predicate = NSPredicate(format: "project == %@", projectInContext)
            request.propertiesToFetch = ["title", "isCompleted"]

            do {
                let results = try context.fetch(request)
                let titles = results.compactMap { $0["title"] as? String }
                DispatchQueue.main.async {
                    completion(titles)
                }
            } catch {
                print("Failed to fetch task titles: \(error)")
                DispatchQueue.main.async {
                    completion([])
                }
            }
        }
    }
  
    // MARK: - Update Task Name
    static func updateTaskName(task: Task, newName: String, completion: (() -> Void)? = nil) {
        CoreDataManager.shared.performBackgroundTask { context in
            guard let taskInContext = context.object(with: task.objectID) as? Task else {
                DispatchQueue.main.async { completion?() }
                return
            }

            taskInContext.title = newName

            do {
                try context.save()
                DispatchQueue.main.async {
                    completion?()
                }
            } catch {
                print("Error updating task name: \(error)")
                DispatchQueue.main.async {
                    completion?()
                }
            }
        }
    }

    // MARK: - Delete Single Task
    static func delete(task: Task, completion: (() -> Void)? = nil) {
        CoreDataManager.shared.performBackgroundTask { context in
            let obj = context.object(with: task.objectID)
            context.delete(obj)

            do {
                try context.save()
                DispatchQueue.main.async {
                    completion?()
                }
            } catch {
                print("Error deleting task: \(error)")
            }
        }
    }



    // MARK: - autoreleasepool
    static func bulkInsertTasks(titles: [String], for project: Project, completion: (() -> Void)? = nil) {
        CoreDataManager.shared.performBackgroundTask { context in
            guard let projectInContext = context.object(with: project.objectID) as? Project else { return }

            for title in titles {
                autoreleasepool {
                    let task = Task(context: context)
                    task.title = title
                    task.isCompleted = false
                    task.createdAt = Date()
                    task.project = projectInContext
                }
            }

            do {
                try context.save()
                DispatchQueue.main.async {
                    completion?()
                }
            } catch {
                print("Error in bulk insert: \(error)")
            }
        }
    }


    // MARK: - Batch Delete Completed Tasks (Performance Optimized)
    static func deleteCompletedTasks(for project: Project, completion: (() -> Void)? = nil) {
        CoreDataManager.shared.performBackgroundTask { context in
            guard let projectInContext = context.object(with: project.objectID) as? Project else { return }

            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Task.fetchRequest()
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "project == %@", projectInContext),
                NSPredicate(format: "isCompleted == YES")
            ])

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
                print("Error batch deleting completed tasks: \(error)")
            }
        }
    }
}

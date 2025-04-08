//
//  CoreDataManager.swift
//  ZenTask
//
//  Created by ORDOFY on 04/04/25.
//
import Foundation
import CoreData

class CoreDataManager {
    
    static let shared = CoreDataManager()
    
    let persistentContainer: NSPersistentCloudKitContainer
    
    private init() {

        persistentContainer = NSPersistentCloudKitContainer(name: "TaskManager")
        
        // migration
        let description = persistentContainer.persistentStoreDescriptions.first!
        description.configuration = "Cloud"
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        
        // iCloud-specific settings
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
            containerIdentifier: "iCloud.com.ZenTask.mrk"
        )
        persistentContainer.persistentStoreDescriptions = [description]
        persistentContainer.loadPersistentStores { (desc, error) in
            if let error = error {
                fatalError("Core Data load error: \(error)")
            }
        }
        
        // Merge background changes into main context
        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
        
        // Handle data conflicts properly (main wins) icould
        persistentContainer.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // Set up remote change notifications
        setupiCloudNotifications()
    }
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Context save error: \(error)")
            }
        }
    }
    
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        persistentContainer.performBackgroundTask(block)
    }
    
    // MARK: - iCloud Sync Support
    
    func setupiCloudNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRemoteStoreChange),
            name: .NSPersistentStoreRemoteChange,
            object: persistentContainer.persistentStoreCoordinator
        )
    }
    
    @objc func handleRemoteStoreChange(_ notification: Notification) {
        DispatchQueue.main.async {
            self.saveContext()
            do {
                try self.persistentContainer.viewContext.save()
                NotificationCenter.default.post(name: .iCloudSyncDidUpdate, object: nil)
            } catch {
                print("Error saving after remote change: \(error)")
            }
        }
    }
}

extension Notification.Name {
    static let iCloudSyncDidUpdate = Notification.Name("iCloudSyncDidUpdate")
}


// manual migration logic
 class UserDetailsToUserDataMigrationPolicy: NSEntityMigrationPolicy {
     override func createDestinationInstances(
         forSource sInstance: NSManagedObject,
         in mapping: NSEntityMapping,
         manager: NSMigrationManager
     ) throws {
         // Create UserData
         let userData = NSEntityDescription.insertNewObject(forEntityName: "UserData", into: manager.destinationContext)
         userData.setValue(sInstance.value(forKey: "name"), forKey: "name")
         userData.setValue(sInstance.value(forKey: "email"), forKey: "email")

         // Create UserAddress
         let userAddress = NSEntityDescription.insertNewObject(forEntityName: "UserAddress", into: manager.destinationContext)
         userAddress.setValue(sInstance.value(forKey: "street"), forKey: "street")
         userAddress.setValue(sInstance.value(forKey: "city"), forKey: "city")
         userAddress.setValue(sInstance.value(forKey: "zip"), forKey: "zip")

         // Set relationship
         userData.setValue(userAddress, forKey: "address")

         // Register
         manager.associate(sourceInstance: sInstance, withDestinationInstance: userData, for: mapping)
     }
 }



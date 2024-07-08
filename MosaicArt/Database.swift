//  Database.swift
//  MosaicArt
//
//  Created by Fluffy on 7/8/24.
//

import Foundation
import FirebaseCore
import FirebaseFirestore


    


func addDocument() async {
    let db = Firestore.firestore()
    // Add a new document with a generated ID
    do {
        let ref = try await db.collection("users").addDocument(data: [
            "first": "Ricky",
            "last": "Lin",
            "born": 2005
        ])
        print("Document added with ID: \(ref.documentID)")
    } catch {
        print("Error adding document: \(error)")
    }
}

// Call these functions at an appropriate place in your app lifecycle
func setupDatabase() {
    print("enter setupdatabase")
    Task {
        await addDocument()
    }
}

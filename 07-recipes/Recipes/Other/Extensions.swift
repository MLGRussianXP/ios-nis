//
//  Extensions.swift
//  Recipes
//
//  Created by dkqz on 27.11.2025.
//

import Foundation
import SwiftUI

extension Encodable {
    func asDictionary() -> [String: Any] {
        guard let data = try? JSONEncoder().encode(self) else {
            return [:]
        }
        
        do {
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            return json ?? [:]
        } catch {
            return [:]
        }
    }
}

extension View {
    func toUIImage() -> UIImage? {
        let renderer = ImageRenderer(content: self)
        renderer.scale = 0.4
        return renderer.uiImage
    }
}

extension Image {
    var base64: String? {
        guard let image = self.toUIImage() else {
            return nil
        }
        
        return image.base64
     }
}

extension UIImage {
    var base64: String? {
        self.jpegData(compressionQuality: 0.4)?.base64EncodedString()
    }
}

extension String {
    var ImageFromBase64: Image? {
        guard let imageData = Data(base64Encoded: self, options: .ignoreUnknownCharacters) else {
            return nil
        }
        
        guard let uiImage = UIImage(data: imageData) else {
            return nil
        }
        
        return Image(uiImage: uiImage)
    }
}

extension Preview {
    static let user = User(
        id: "123",
        username: "johndoe",
        email: "john@doe.com",
        joined: Date().timeIntervalSince1970
    )
    
    static let ingredient = Ingredient(
        id: "123",
        title: "Bread",
        quantity: 100,
        foodQuantityType: 0
    )
    
    static let recipe = Recipe(
        id: "123",
        title: "Hamburger",
        author: "Gordon Ramsay",
        difficulty: 4,
        createdById: "123",
        createdAt: Date().timeIntervalSince1970,
        timeToCookInSeconds: 123,
        type: "dinner",
        ingredients: [ingredient],
        recipeSteps: [
            RecipeStep(
                id: "123",
                text: "Bake bread",
                time: 3,
                timeType: "minutes"
            ),
            RecipeStep(
                id: "123",
                text: "Cut salad",
                time: 1,
                timeType: "minutes"
            )
        ],
        images: []
    )
    
    static let recipeStep = RecipeStep(
        id: "123",
        text: "Bake bread",
        time: 3,
        timeType: "Minutes"
    )
}

//
//  IngredientView.swift
//  Recipes
//
//  Created by dkqz on 27.11.2025.
//

import SwiftUI

struct IngredientView: View {
    @State private var quantity: String = ""
    
    var ingredient: Binding<Ingredient>
    let deleteAction: () -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            TextField("Title", text: ingredient.title)
                .textFieldStyle(DefaultTextFieldStyle())
            
            HStack {
                TextField("Quantity", text: $quantity)
                    .keyboardType(.numberPad)
                    .onChange(of: quantity, initial: false) { _, newValue in
                        ingredient.wrappedValue.quantity = Int(newValue) ?? 0
                    }
                    .onAppear {
                        quantity = String(ingredient.wrappedValue.quantity)
                    }
                
                Picker(
                    "",
                    selection: ingredient.foodQuantityType
                ) {
                    ForEach(0..<Utils.foodQuantityType.count, id: \.self) { i in
                        Text("\(Utils.foodQuantityType[i])").tag(i)
                    }
                }
                .frame(minWidth: 140)
                .pickerStyle(.automatic)
            }
        }
        .swipeActions {
            Button {
                deleteAction()
            } label: {
                Label("Remove", systemImage: "trash")
            }
            .tint(.red)
        }
    }
}

#Preview {
    IngredientView(
        ingredient: Binding(get: { return Preview.ingredient }, set: { _ in })
    ) {}
}

//
//  ActionButtonsView.swift
//  Alethia
//
//  Created by Angelo Carasig on 12/4/2025.
//

import SwiftUI

private extension Button {
    func actionButton(_ isActive: Bool) -> some View {
        self.padding(.horizontal, 4)
            .lineLimit(1)
            .fontWeight(.medium)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .foregroundColor(isActive ? .background : .text)
            .background(isActive ? .text : .tint, in: .rect(cornerRadius: 12, style: .continuous))
            .cornerRadius(12)
    }
}

struct ActionButtonsView: View {
    @EnvironmentObject var vm: DetailsViewModel
    
    var details: Detail {
        vm.details!
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Button {
                print("TODO: Toggling Library!")
            } label: {
                LibraryButton()
            }
            .actionButton(!details.manga.inLibrary)
            
            Button {
                print("TODO: Adding Origin!")
            } label: {
                OriginButton()
            }
            .actionButton(vm.entry.sourceId != nil)
            .disabled(!details.manga.inLibrary || vm.entry.fetchUrl == nil)
            
            QuickButtonsView()
        }
        .frame(height: 45)
        .animation(.easeInOut(duration: 0.3), value: details.manga.inLibrary)
    }
    
    @ViewBuilder
    private func LibraryButton() -> some View {
        HStack {
            Image(systemName: details.manga.inLibrary ? "heart.fill" : "plus")
            Text(details.manga.inLibrary ? "In Library" : "Add to Library")
        }
    }
    
    @ViewBuilder
    private func OriginButton() -> some View {
        HStack {
            Image(systemName: "plus.square.dashed")
            Text(details.manga.inLibrary ? "\(details.origins.count) Source\((details.origins.count == 1) ? "" : "s")" : "Add Source")
        }
    }
}

private struct QuickButtonsView: View {
    @EnvironmentObject var vm: DetailsViewModel
    
    @State private var showConfirmation = false
    @State private var confirmationData: ConfirmationData? = nil
    
    private struct ConfirmationData {
        let message: String
        let action: () -> Void
    }
    
    private struct Option {
        var title: String
        var systemImage: String
        var action: () -> Void
    }
    
    private var options: [Option] = [
        Option(title: "Refresh Chapters", systemImage: "arrow.clockwise", action: {}),
        Option(title: "Refresh Metadata", systemImage: "rectangle.and.text.magnifyingglass", action: {}),
        Option(title: "Merge Wizard", systemImage: "plus.rectangle.fill.on.rectangle.fill", action: {}),
        Option(title: "Download All Chapters", systemImage: "arrow.down.circle.fill", action: {}),
        Option(title: "Remove All Downloads", systemImage: "trash.fill", action: {}),
        Option(title: "Mark All As Read", systemImage: "checkmark.circle.fill", action: {}),
        Option(title: "Mark All As Unread", systemImage: "x.circle.fill", action: {})
    ]
    
    var body: some View {
        Menu {
            ForEach(options, id: \.title) { option in
                Button(action: option.action) {
                    Label(option.title, systemImage: option.systemImage)
                        .foregroundColor(.background)
                }
            }
        } label: {
            Image(systemName: "ellipsis")
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
                .foregroundColor(.background)
                .background(.text, in: .rect(cornerRadius: 12, style: .continuous))
                .cornerRadius(12)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    ForEach(options, id: \.title) { option in
                        Button(action: option.action) {
                            Label(option.title, systemImage: option.systemImage)
                                .foregroundColor(.background)
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
        }
        //        .sheet(isPresented: $vm.showMergeExistingSheet) {
        //            ExistingMergeSheet(vm: vm)
        //        }
        .alert("Are you sure?", isPresented: $showConfirmation) {
            Button("Confirm", role: .destructive) { confirmationData?.action() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(confirmationData?.message ?? "This action cannot be undone.")
        }
    }
    
    private func showConfirmationPrompt(message: String, action: @escaping () -> Void) {
        confirmationData = ConfirmationData(message: message, action: action)
        showConfirmation = true
    }
}

//
//  ActionButtonsView.swift
//  Alethia
//
//  Created by Angelo Carasig on 12/4/2025.
//

import SwiftUI

private extension Button {
    func actionButton(_ isActive: Bool) -> some View {
        self.padding(.horizontal, Constants.Padding.minimal)
            .lineLimit(1)
            .fontWeight(.medium)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .foregroundColor(isActive ? .background : .text)
            .background(isActive ? .text : .tint, in: .rect(cornerRadius: 12, style: .continuous))
            .cornerRadius(Constants.Corner.Radius.button)
    }
}

struct ActionButtonsView: View {
    @EnvironmentObject var vm: DetailsViewModel
    
    var body: some View {
        HStack(spacing: Constants.Spacing.large) {
            Button {
                vm.toggleInLibrary()
            } label: {
                LibraryButton()
            }
            .actionButton(vm.details?.manga.inLibrary ?? false)
            
            Button {
                print("TODO: Adding Origin!")
            } label: {
                OriginButton()
            }
            .actionButton(vm.sourcePresent)
            .disabled(
                vm.details != nil &&
                !vm.details!.manga.inLibrary
                // TODO: new way to figure out source
                // vm.entry.fetchUrl == nil
            )
            
            QuickButtonsView()
        }
        .frame(height: 45)
        .animation(.easeInOut(duration: 0.3), value: vm.details?.manga.inLibrary)
    }
    
    @ViewBuilder
    private func LibraryButton() -> some View {
        HStack {
            Image(systemName: vm.inLibrary ? "heart.fill" : "plus")
            Text(vm.inLibrary ? "In Library" : "Add to Library")
        }
    }
    
    @ViewBuilder
    private func OriginButton() -> some View {
        HStack {
            Image(systemName: "plus.square.dashed")
            Text(vm.inLibrary ?
                 "^[\(vm.details?.origins.count ?? 0) Source](inflected: true)" :
                    "Add Source"
            )
        }
    }
}

private struct QuickButtonsView: View {
    @EnvironmentObject var vm: DetailsViewModel
    
    @State private var showConfirmation = false
    @State private var confirmationAction: ActionType? = nil
    
    private enum ActionType: String, CaseIterable {
        case editDetails = "Edit Details"
        case refreshChapters = "Refresh Chapters"
        case refreshMetadata = "Refresh Metadata"
        case mergeWizard = "Merge Wizard"
        case downloadAllChapters = "Download All Chapters"
        case removeAllDownloads = "Remove All Downloads"
        case markAllAsRead = "Mark All As Read"
        case markAllAsUnread = "Mark All As Unread"
        
        var systemImage: String {
            switch self {
            case .editDetails:          return "pencil"
            case .refreshChapters:      return "arrow.clockwise"
            case .refreshMetadata:      return "rectangle.and.text.magnifyingglass"
            case .mergeWizard:          return "plus.rectangle.fill.on.rectangle.fill"
            case .downloadAllChapters:  return "arrow.down.circle.fill"
            case .removeAllDownloads:   return "trash.fill"
            case .markAllAsRead:        return "checkmark.circle.fill"
            case .markAllAsUnread:      return "x.circle.fill"
            }
        }
        
        var requiresConfirmation: Bool {
            switch self {
            case .removeAllDownloads, .markAllAsRead, .markAllAsUnread:
                return true
            default:
                return false
            }
        }
        
        var confirmationMessage: String {
            switch self {
            case .markAllAsRead:
                return "Are you sure you want to mark all chapters as read?"
            case .markAllAsUnread:
                return "Are you sure you want to mark all chapters as unread?"
            default:
                return "This action cannot be undone."
            }
        }
    }
    
    var body: some View {
        Menu {
            ForEach(ActionType.allCases, id: \.self) { action in
                Button {
                    handleAction(action)
                } label: {
                    Label(action.rawValue, systemImage: action.systemImage)
                }
            }
        } label: {
            Image(systemName: "ellipsis")
                .frame(
                    width: Constants.Icon.Size.regular,
                    height: Constants.Icon.Size.regular
                )
                .contentShape(.rect)
                .foregroundColor(.background)
                .background(.text, in: .rect(
                    cornerRadius: Constants.Corner.Radius.button,
                    style: .continuous
                ))
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    ForEach(ActionType.allCases, id: \.self) { action in
                        Button {
                            handleAction(action)
                        } label: {
                            Label(action.rawValue, systemImage: action.systemImage)
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
        }
        .alert("Confirmation", isPresented: $showConfirmation) {
            Button("Confirm") {
                executeAction()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(confirmationAction?.confirmationMessage ?? "")
        }
    }
    
    private func handleAction(_ action: ActionType) {
        if action.requiresConfirmation {
            confirmationAction = action
            showConfirmation = true
        } else {
            executeAction(action)
        }
    }
    
    private func executeAction(_ action: ActionType? = nil) {
        let actionToExecute = action ?? confirmationAction
        
        guard let actionToExecute = actionToExecute else { return }
        
        switch actionToExecute {
        case .editDetails:
            // Implement edit details action
            break
            
        case .refreshChapters:
            // Implement refresh chapters action
            break
            
        case .refreshMetadata:
            // Implement refresh metadata action
            break
            
        case .mergeWizard:
            // Implement merge wizard action
            break
            
        case .downloadAllChapters:
            // Implement download all chapters action
            break
            
        case .removeAllDownloads:
            // Implement remove all downloads action
            break
            
        case .markAllAsRead:
            vm.markAllChapters(asRead: true)
            
        case .markAllAsUnread:
            vm.markAllChapters(asRead: false)
        }
    }
}

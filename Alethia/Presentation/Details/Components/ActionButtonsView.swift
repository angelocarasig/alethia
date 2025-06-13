//
//  ActionButtonsView.swift
//  Alethia
//
//  Created by Angelo Carasig on 12/4/2025.
//

import Core
import SwiftUI

private extension Button {
    func actionButton(_ isActive: Bool) -> some View {
        self.padding(.horizontal, .Padding.minimal)
            .lineLimit(1)
            .fontWeight(.medium)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .foregroundColor(isActive ? .background : .text)
            .background(isActive ? .text : .tint, in: .rect(cornerRadius: .Corner.button, style: .continuous))
            .cornerRadius(.Corner.button)
    }
}

struct ActionButtonsView: View {
    @EnvironmentObject var vm: DetailsViewModel
    
    @State private var addingToLibrary: Bool = false
    
    var body: some View {
        HStack(spacing: .Spacing.regular) {
            Button {
                if vm.inLibrary {
                    vm.removeFromLibrary()
                }
                else {
                    addingToLibrary = true
                }
            } label: {
                LibraryButton()
            }
            .actionButton(vm.inLibrary)
            .sheet(isPresented: $addingToLibrary) {
                AddToLibrarySheet()
            }
            
            Button {
                Task {
                    await vm.addOrigin()
                }
            } label: {
                OriginButton()
            }
            .actionButton(vm.sourcePresent)
            .disabled(vm.isAddingOrigin || (vm.details != nil && !vm.inLibrary))
            
            QuickButtonsView()
        }
        .frame(height: 50)
        .animation(.easeInOut(duration: 0.3), value: vm.inLibrary)
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
        if !vm.isAddingOrigin {
            HStack {
                Image(systemName: "plus.square.dashed")
                Text(vm.inLibrary ?
                     "^[\(vm.details?.origins.count ?? 0) Source](inflect: true)" :
                        "Add Source"
                )
            }
        }
        else {
            ProgressView()
        }
    }
}

private struct QuickButtonsView: View {
    @EnvironmentObject var vm: DetailsViewModel
    
    @State private var showConfirmation: Bool = false
    @State private var confirmationAction: ActionType? = nil
    
    // action-type specific
    @State private var showEditDetails: Bool = false
    
    private enum ActionType: String, CaseIterable {
        case editDetails = "Edit Details"
        case refresh = "Refresh"
        case mergeWizard = "Merge Wizard"
        case downloadAllChapters = "Download All Chapters"
        case removeAllDownloads = "Remove All Downloads"
        case markAllAsRead = "Mark All As Read"
        case markAllAsUnread = "Mark All As Unread"
        
        var systemImage: String {
            switch self {
            case .editDetails:          return "pencil"
            case .refresh:              return "rectangle.and.text.magnifyingglass"
            case .mergeWizard:          return "plus.rectangle.fill.on.rectangle.fill"
            case .downloadAllChapters:  return "arrow.down.circle.fill"
            case .removeAllDownloads:   return "trash.fill"
            case .markAllAsRead:        return "checkmark.circle.fill"
            case .markAllAsUnread:      return "x.circle.fill"
            }
        }
        
        var requiresConfirmation: Bool {
            switch self {
            case .refresh, .removeAllDownloads, .markAllAsRead, .markAllAsUnread:
                return true
            default:
                return false
            }
        }
        
        var confirmationMessage: String {
            switch self {
            case .refresh:
                return "This will fetch all latest chapters and metadata."
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
                .padding(.horizontal, .Padding.minimal)
                .lineLimit(1)
                .fontWeight(.medium)
                .frame(width: 50, height: 50)
                .foregroundColor(.background)
                .background(Color.text, in: .rect(cornerRadius: 12, style: .continuous))
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
        .sheet(isPresented: $showEditDetails) {
            // TODO: 
            EmptyView()
                .environmentObject(vm)
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
            showEditDetails = true
            
        case .refresh:
            vm.refreshMetadata()
            
        case .mergeWizard:
            // Implement merge wizard action
            break
            
        case .downloadAllChapters:
            vm.downloadAllChapters()
            break
            
        case .removeAllDownloads:
            vm.deleteAllChapters()
            break
            
        case .markAllAsRead:
            vm.markAllChapters(asRead: true)
            
        case .markAllAsUnread:
            vm.markAllChapters(asRead: false)
        }
    }
}

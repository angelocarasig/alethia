//
//  LibraryFilterView.swift
//  Alethia
//
//  Created by Angelo Carasig on 7/5/2025.
//

import SwiftUI
import Flow

struct LibraryFilterView: View {
    @EnvironmentObject private var vm: LibraryViewModel
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Filters")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button("Reset to Default") {
                        vm.filters.reset()
                    }
                    .disabled(vm.filters.isEmpty)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 6)
                
                HStack(spacing: 8) {
                    Text("Sorting By")
                        .foregroundColor(.secondary)
                    
                    Text(vm.filters.sortType.rawValue)
                        .fontWeight(.medium)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.appBlue)
                        .foregroundColor(.text)
                        .cornerRadius(15)
                    
                    Text("•")
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text(vm.filters.sortDirection.rawValue)
                        .fontWeight(.medium)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.appBlue)
                        .foregroundColor(.text)
                        .cornerRadius(15)
                }
                .font(.subheadline)
                .padding(.bottom, 6)
                
                HStack(spacing: 8) {
                    Text("Active Filters")
                        .foregroundColor(.secondary)
                    
                    if vm.filters.isEmpty {
                        Text("None")
                            .fontWeight(.medium)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.tint)
                            .foregroundColor(.text)
                            .cornerRadius(15)
                    }
                    
                    HFlow {
                        ForEach(vm.filters.activeFilters, id: \.id) { filter in
                            Text(filter.name)
                                .fontWeight(.medium)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(filter.color)
                                .foregroundColor(.text)
                                .cornerRadius(15)
                        }
                    }
                }
                .font(.subheadline)
            }
            
            Divider().padding(.vertical, 8)
            
            VStack(spacing: 12) {
                SortOptions()
                
                Divider().padding(.vertical, 8)
                
                FilterOptions()
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
}

extension LibraryFilterView {
    @ViewBuilder
    private func SortOptions() -> some View {
        VStack {
            Text("Sort By")
                .font(.headline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ForEach(LibrarySortType.allCases) { sortType in
                let isActive = vm.filters.sortType == sortType
                
                Button {
                    withAnimation {
                        if isActive {
                            vm.filters.sortDirection.toggle()
                        }
                        else {
                            vm.filters.sortType = sortType
                        }
                    }
                } label: {
                    HStack {
                        Text(sortType.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        if isActive {
                            Image(systemName: "arrow.up")
                                .rotationEffect(.degrees(vm.filters.sortDirection == .ascending ? 0 : 180))
                                .animation(.easeInOut, value: vm.filters.sortDirection)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .foregroundColor(.text)
                    .background(isActive ? Color.appBlue : Color.tint)
                    .cornerRadius(15)
                }
            }
        }
    }
}


extension LibraryFilterView {
    @ViewBuilder
    private func FilterOptions() -> some View {
//        TagSearchFilterView()
//        
//        Divider()
//        
//        AddedDateFilter()
//        
//        Divider()
//        
//        UpdatedDateFilter()
//        
//        Divider()
//        
//        ContentTypeFilterView()
//        
//        Divider()
//        
//        TrackingFilterView()
    }
}

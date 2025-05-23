//
//  EndDetails.swift
//  Alethia
//
//  Created by Angelo Carasig on 19/5/2025.
//

import SwiftUI

struct EndDetails: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            Spacer().frame(height: 150)
            
            ContentSection()
            
            Spacer()
            
            Text("Next Chapter Stuff ...")
            
            TrackerSection()
            
            Spacer()
            
            Recommendations()
            
            Spacer().frame(height: 150)
        }
        .padding(.horizontal, Constants.Padding.screen)
        .frame(width: UIScreen.main.bounds.width)
    }
    
    @ViewBuilder
    private func ContentSection() -> some View {
        VStack(spacing: Constants.Spacing.large) {
            HStack {
                Image(systemName: "checkmark.circle")
                    .fontWeight(.semibold)
                    .foregroundStyle(.green)
                
                Text("Finished Reading")
                    .fontWeight(.bold)
            }
            .font(.title)
            
            VStack(spacing: Constants.Spacing.large) {
                Text("Chapter 23")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text("Alone With You.")
                    .font(.title2)
                    .fontWeight(.bold)
                    .lineLimit(3, reservesSpace: true)
                    .multilineTextAlignment(.center)
            }
            
            Spacer().frame(height: 50)
            
            GeometryReader { geometry in
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Text("Exit")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding()
                            .frame(width: geometry.size.width * 0.35, alignment: .center)
                            .frame(maxHeight: .infinity)
                            .background(Color.accentColor)
                            .cornerRadius(Constants.Corner.Radius.button)
                    }
                    .buttonStyle(.plain)
                    
                    Button {} label: {
                        HStack {
                            Text("Next Chapter")
                            Image(systemName: "chevron.right")
                        }
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.text)
                        .padding()
                        .frame(width: geometry.size.width * 0.6, alignment: .center)
                        .frame(maxHeight: .infinity)
                        .background(Color.tint)
                        .cornerRadius(Constants.Corner.Radius.button)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom, 15)
            }
            .frame(height: 75)
        }
    }
    
    @ViewBuilder
    private func TrackerSection() -> some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.minimal) {
            Text("TRACKERS")
                .font(.footnote)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .padding(.bottom, Constants.Padding.regular)
            
            HStack {
                Image("AniList")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .cornerRadius(Constants.Corner.Radius.regular)
                
                VStack(alignment: .leading) {
                    Text("Unknown Title")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    
                    Text("Last Updated \n Mon 21st May, 2021")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    HStack {
                        Text("Syncing")
                            .font(.headline)
                            .padding(Constants.Padding.regular)
                            .background(
                                RoundedRectangle(cornerRadius: Constants.Corner.Radius.regular)
                                    .fill(Color.blue.opacity(0.5))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: Constants.Corner.Radius.regular)
                                            .stroke(Color.blue.opacity(0.9), lineWidth: 2)
                                    )
                            )
                            .foregroundColor(Color.blue)
                            .cornerRadius(Constants.Corner.Radius.regular)
                    }
                    
//                    HStack {
//                        Text("Synced")
//                            .font(.headline)
//                            .padding(Constants.Padding.regular)
//                            .background(
//                                RoundedRectangle(cornerRadius: Constants.Corner.Radius.regular)
//                                    .fill(Color.green.opacity(0.5))
//                                    .overlay(
//                                        RoundedRectangle(cornerRadius: Constants.Corner.Radius.regular)
//                                            .stroke(Color.green.opacity(0.9), lineWidth: 2)
//                                    )
//                            )
//                            .foregroundColor(Color.green)
//                            .cornerRadius(Constants.Corner.Radius.regular)
//                        
//                        Image(systemName: "checkmark.circle")
//                            .foregroundColor(Color.green)
//                    }
//                    
//                    HStack {
//                        Text("Error")
//                            .font(.headline)
//                            .padding(Constants.Padding.regular)
//                            .background(
//                                RoundedRectangle(cornerRadius: Constants.Corner.Radius.regular)
//                                    .fill(Color.red.opacity(0.5))
//                                    .overlay(
//                                        RoundedRectangle(cornerRadius: Constants.Corner.Radius.regular)
//                                            .stroke(Color.red.opacity(0.9), lineWidth: 2)
//                                    )
//                            )
//                            .foregroundColor(Color.red)
//                            .cornerRadius(Constants.Corner.Radius.regular)
//                        
//                        Image(systemName: "arrow.trianglehead.counterclockwise")
//                            .foregroundColor(Color.red)
//                    }
                    
                    Text("1/\(999) Chapters")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    @ViewBuilder
    private func Recommendations() -> some View {
        Text("TODO: ")
        Text("Similar In Your Library")
        Text("Others In Collections")
        Text("Authors Other Works")
        Text("Others By Scanlator")
    }
}

#Preview {
    EndDetails()
}

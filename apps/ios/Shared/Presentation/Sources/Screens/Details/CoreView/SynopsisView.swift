//
//  SynopsisView.swift
//  Alethia
//
//  Created by Angelo Carasig on 12/4/2025.
//

import SwiftUI

struct SynopsisView: View {
    @Environment(\.dimensions) private var dimensions
    @Environment(\.theme) private var theme
    
    var synopsis: AttributedString
    
    @State private var isExpanded: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: dimensions.spacing.regular) {
            Text(synopsis)
                .lineLimit(isExpanded ? nil : 6)
                .foregroundStyle(theme.colors.foreground)
                .onTapGesture {
                    withAnimation(theme.animations.expand) {
                        isExpanded.toggle()
                    }
                }
            
            Button {
                withAnimation(theme.animations.expand) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: dimensions.spacing.minimal) {
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    Text(isExpanded ? "Show Less" : "Show More")
                        .font(.caption)
                }
                .foregroundStyle(theme.colors.accent)
            }
        }
    }
}

#Preview {
    SynopsisView(synopsis: """
10 years ago, after "the Gate" that connected the real world with the monster world opened, some of the ordinary, everyday people received the power to hunt monsters within the Gate. They are known as "Hunters". However, not all Hunters are powerful. My name is Sung Jin-Woo, an E-rank Hunter. I'm someone who has to risk his life in the lowliest of dungeons, the "World's Weakest". Having no skills whatsoever to display, I barely earned the required money by fighting in low-leveled dungeons… at least until I found a hidden dungeon with the hardest difficulty within the D-rank dungeons! In the end, as I was accepting death, I suddenly received a strange power, a quest log that only I could see, a secret to leveling up that only I know about! If I trained in accordance with my quests and hunted monsters, my level would rise. Changing from the weakest Hunter to the strongest S-rank Hunter!
---
**Links:**
- Official English Translation [<Pocket Comics>](https://www.pocketcomics.com/comic/320) | [<WebNovel>](https://www.webnovel.com/comic/only-i-level-up-(solo-leveling)_15227640605485101) | [<Tapas>](https://tapas.io/series/solo-leveling-comic/info)
- Alternate Official Raw - [Kakao Webtoon](https://webtoon.kakao.com/content/나-혼자만-레벨업/2320)
""")
    .environment(\.theme, Theme())
    .environment(\.dimensions, Dimensions())
    .padding()
}

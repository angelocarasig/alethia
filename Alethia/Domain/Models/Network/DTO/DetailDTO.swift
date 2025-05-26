//
//  DetailDTO.swift
//  Alethia
//
//  Created by Angelo Carasig on 17/11/2024.
//

import Foundation

struct DetailDTO: Codable {
    let manga: MangaDTO
    let origin: OriginDTO
    let chapters: [ChapterDTO]
}

struct MangaDTO: Codable {
    let title: String
    let authors: [String]
    let synopsis: String
    let alternativeTitles: [String]
    let tags: [String]
}

struct OriginDTO: Codable {
    let slug: String
    let url: String
    let referer: String
    let covers: [String]
    let status: String
    let classification: String
    let creation: String
}

struct ChapterDTO: Codable {
    let title: String
    let slug: String
    let number: Double
    let scanlator: String
    let date: String
}

let mockDetailDTO: DetailDTO = DetailDTO(
    manga: MangaDTO(
        title: "The Legendary Hero Returns",
        authors: ["Akira Yamamoto", "Sakura Tanaka"],
        synopsis: "After 1000 years of slumber, the legendary hero awakens to a world that has forgotten him. Now he must reclaim his place in a land ruled by dark forces while uncovering the truth behind his long sleep.",
        alternativeTitles: ["Legendary Hero's Return", "Hero Reborn", "千年勇者の帰還"],
        tags: ["Action", "Adventure", "Fantasy", "Isekai", "Reincarnation"]
    ),
    origin: OriginDTO(
        slug: "legendary-hero-returns",
        url: "https://mangasource.com/series/legendary-hero-returns",
        referer: "https://mangasource.com",
        covers: [
            "https://mangasource.com/covers/legendary-hero-returns/1.jpg",
            "https://mangasource.com/covers/legendary-hero-returns/2.jpg"
        ],
        status: "Ongoing",
        classification: "Shounen",
        creation: "2020-05-15"
    ),
    chapters: [
        ChapterDTO(
            title: "Prologue: The Awakening",
            slug: "prologue-the-awakening",
            number: 1.0,
            scanlator: "HeroScan",
            date: "2020-06-01T00:00:00Z"
        ),
        ChapterDTO(
            title: "The Ruined Kingdom",
            slug: "the-ruined-kingdom",
            number: 2.0,
            scanlator: "HeroScan",
            date: "2020-06-15T00:00:00Z"
        ),
        ChapterDTO(
            title: "First Battle",
            slug: "first-battle",
            number: 3.0,
            scanlator: "MangaPower",
            date: "2020-07-01T00:00:00Z"
        ),
        ChapterDTO(
            title: "The Mysterious Girl",
            slug: "the-mysterious-girl",
            number: 4.0,
            scanlator: "MangaPower",
            date: "2020-07-15T00:00:00Z"
        )
    ]
)

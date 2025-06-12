# Alethia Database Schema

## Overview

Alethia uses SQLite with GRDB as the database layer. The schema is designed to support a flexible manga reading application with multiple content sources, tracking capabilities, and user library management.

**Current Version**: 1.0.4

## Entity Relationship Diagram

### Version 1.0.4

```mermaid
erDiagram
    Host ||--o{ Source : "has many"
    Source ||--o{ SourceRoute : "has many"
    Source ||--o{ Origin : "references"
    
    Manga ||--o{ Title : "has many"
    Manga ||--o{ Cover : "has many"
    Manga ||--o{ Origin : "has many"
    Manga }o--o{ Author : "many-to-many"
    Manga }o--o{ Tag : "many-to-many"
    Manga }o--o{ Collection : "many-to-many"
    
    Origin }|--|| Source : "belongs to"
    Origin ||--o{ Chapter : "has many"
    Origin }|--|| Manga : "belongs to"
    Origin }o--o{ Scanlator : "many-to-many"
    
    Scanlator ||--o{ Chapter : "has many"
    Chapter }|--|| Origin : "belongs to"
    Chapter }|--|| Scanlator : "belongs to"
    
    MangaAuthor }|--|| Manga : "joins"
    MangaAuthor }|--|| Author : "joins"
    
    MangaTag }|--|| Manga : "joins"
    MangaTag }|--|| Tag : "joins"
    
    MangaCollection }|--|| Manga : "joins"
    MangaCollection }|--|| Collection : "joins"
    
    OriginScanlator }|--|| Origin : "joins"
    OriginScanlator }|--|| Scanlator : "joins"

    Host {
        int64 id PK
        string name
        string author
        string repository
        string baseUrl UK
    }
    
    Source {
        int64 id PK
        string name
        string icon
        string path
        string website
        string description
        bool pinned
        bool disabled
        int64 hostId FK
    }
    
    SourceRoute {
        int64 id PK
        string name
        string path
        int64 sourceId FK
    }
    
    Manga {
        int64 id PK
        string title
        string synopsis
        datetime addedAt
        datetime updatedAt
        datetime lastReadAt
        bool inLibrary
        string orientation
        bool showAllChapters
        bool showHalfChapters
    }
    
    Title {
        int64 id PK
        string title
        int64 mangaId FK
    }
    
    Cover {
        int64 id PK
        bool active
        string url
        string path
        int64 mangaId FK
    }
    
    Author {
        int64 id PK
        string name UK
    }
    
    Tag {
        int64 id PK
        string name UK
    }
    
    Collection {
        int64 id PK
        string name UK
        string color
        string icon
        int ordering
    }
    
    Origin {
        int64 id PK
        int64 mangaId FK
        int64 sourceId FK
        string slug
        string url
        string referer
        string classification
        string status
        datetime createdAt
        int priority
    }
    
    Scanlator {
        int64 id PK
        string name UK
    }
    
    Chapter {
        int64 id PK
        int64 originId FK
        int64 scanlatorId FK
        string title
        string slug
        double number
        datetime date
        double progress
        string localPath
    }
    
    OriginScanlator {
        int64 originId FK
        int64 scanlatorId FK
        int priority
    }
    
    MangaAuthor {
        int64 authorId FK
        int64 mangaId FK
    }
    
    MangaTag {
        int64 tagId FK
        int64 mangaId FK
    }
    
    MangaCollection {
        int64 mangaId FK
        int64 collectionId FK
    }
```

# Alethia Database Schema

## Overview

Alethia uses SQLite with GRDB as the database layer. The schema is designed to support a flexible manga reading application with multiple content sources, tracking capabilities, and user library management but this file will only document at specific versions how the schema changes.

**Current Version**: 1.0.3

## Entity Relationship Diagram

### Version 1.0.3

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
    Origin ||--o{ Scanlator : "has many"
    
    Scanlator ||--o{ Chapter : "has many"
    Chapter }|--|| Origin : "belongs to"
    Chapter }|--|| Scanlator : "belongs to"
    
    MangaAuthor }|--|| Manga : "joins"
    MangaAuthor }|--|| Author : "joins"
    
    MangaTag }|--|| Manga : "joins"
    MangaTag }|--|| Tag : "joins"
    
    MangaCollection }|--|| Manga : "joins"
    MangaCollection }|--|| Collection : "joins"

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
        String color
        String icon
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
        int64 originId FK
        string name
        int priority
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

## Version History

### Changes from 1.0.2 to 1.0.3
- Added `lastReadAt` column to `Manga` table to track reading history

### Changes from 1.0.1 to 1.0.2
- Added `color` and `icon` columns to `Collection` table for personalization

### Changes from 1.0.0 to 1.0.1
- Added migration to update manga `updatedAt` timestamps based on most recent chapter dates

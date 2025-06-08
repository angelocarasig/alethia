# Change Log
All notable changes to this project will be documented in this file.
 
The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [1.0.4] - 2025-06-08
### Database Migration
- **Version**: 1.0.3 → 1.0.4
- **Tables Affected**: `scanlator`, `originScanlator` (new), `chapter`
- **Migration**: 
 - Restructure scanlator table to be globally unique
 - Create new `originScanlator` join table for many-to-many relationships
 - Migrate existing scanlator data preserving all relationships and priorities
- **Reason**: Enable global scanlator management while maintaining per-origin priority ordering

### Added
- MINOR New `OriginScanlator` join table model for many-to-many relationship between origins and scanlators
- Added `originScanlator` table with composite primary key and priority management
- Added `scanlatorsExtended` query interface to fetch scanlators with their per-origin priorities

### Changed
- MAJOR Restructured `Scanlator` model to be globally unique (similar to Authors and Tags)
- Removed `originId` and `priority` from `Scanlator` table
- Updated `ScanlatorExtended` virtual model to include origin-specific priority and origin information
- Modified chapter queries to work with new global scanlator structure

### Migration Details
- Extracts unique scanlator names from existing data
- Creates origin-scanlator relationships preserving original priorities
- Updates chapter references to use new global scanlator IDs
- Maintains data integrity throughout migration process

---

## [1.0.3] - 2025-06-05

### Database Migration
- **Version**: 1.0.2 → 1.0.3
- **Tables Affected**: `manga`
- **Migration**: Add `lastReadAt` column to manga table
- **Reason**: Track when manga was last read for better library organization and sorting

### Changed
- PATCH Added `lastReadAt` property to manga table to track reading history
- Added database migration from 1.0.2 to 1.0.3 for manga table

---

## [1.0.2] - 2025-06-04

### Database Migration
- **Version**: 1.0.1 → 1.0.2
- **Tables Affected**: `collection`
- **Migration**: Add icon and color props to collection
- **Reason**: Introducing collection grouping functionality, adding some personalisation fields

### Changed
- PATCH Updated collection with added `icon` and `color` properties
- Added according database migration from 1.0.1 to 1.0.2 for affected tables

---

## [1.0.1] - 2025-01-07

### Database Migration
- **Version**: 1.0.0 → 1.0.1
- **Tables Affected**: `manga`
- **Migration**: Updates all manga entries to set their `updatedAt` timestamp based on the most recent chapter date across all origins
- **Reason**: Ensures manga update timestamps accurately reflect content updates

### Changed
- PATCH Updated manga `updatedAt` property to reflect the most recent chapter date from all associated origins
- Added database migration to retroactively update existing manga entries with correct `updatedAt` values

## [1.0.0] - 2025-01-01
 
### Added
- Initial release with core manga reading functionality
- Database schema v1.0.0 with support for manga, chapters, sources, and metadata

---

## Database Schema

For the current database schema, see [DATABASE.md](./DATABASE.md) or view below:

<details>
<summary>Entity Relationship Diagram</summary>

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

</details>

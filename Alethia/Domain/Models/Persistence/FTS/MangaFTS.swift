//
//  MangaFTS.swift
//  Alethia
//
//  Created by Angelo Carasig on 9/6/2025.
//

import Foundation
import GRDB

struct MangaFTS: DatabaseModel {
    static func createTable(db: Database) throws {
        // Create FTS5 virtual table with proper tokenizer
        try db.create(virtualTable: "manga_fts", using: FTS5()) { t in
            t.tokenizer = .unicode61() // Better unicode support
            t.column("content")
            // Note: rowid is implicit in FTS5, no need to declare it
        }
        
        // Populate with existing data
        try db.execute(sql: """
            INSERT INTO manga_fts(rowid, content) 
            SELECT 
                m.id,
                m.title || ' ' || COALESCE(
                    (SELECT GROUP_CONCAT(t.title, ' ') 
                     FROM title t 
                     WHERE t.mangaId = m.id), 
                    ''
                )
            FROM manga m
        """)
        
        // Create triggers to keep FTS in sync
        try createTriggers(db: db)
    }
    
    static func migrate(with migrator: inout DatabaseMigrator, from version: Version) throws {
        // No migrations needed for now
    }
    
    private static func createTriggers(db: Database) throws {
        // Manga table triggers
        try db.execute(sql: """
            CREATE TRIGGER manga_fts_ai AFTER INSERT ON manga BEGIN
                INSERT INTO manga_fts(rowid, content) 
                VALUES (new.id, new.title);
            END
        """)
        
        try db.execute(sql: """
            CREATE TRIGGER manga_fts_ad AFTER DELETE ON manga BEGIN
                DELETE FROM manga_fts WHERE rowid = old.id;
            END
        """)
        
        try db.execute(sql: """
            CREATE TRIGGER manga_fts_au AFTER UPDATE ON manga BEGIN
                UPDATE manga_fts 
                SET content = new.title || ' ' || COALESCE(
                    (SELECT GROUP_CONCAT(t.title, ' ') 
                     FROM title t 
                     WHERE t.mangaId = new.id), 
                    ''
                )
                WHERE rowid = new.id;
            END
        """)
        
        // Title table triggers
        try db.execute(sql: """
            CREATE TRIGGER title_fts_ai AFTER INSERT ON title BEGIN
                UPDATE manga_fts 
                SET content = (
                    SELECT m.title || ' ' || COALESCE(
                        (SELECT GROUP_CONCAT(t.title, ' ') 
                         FROM title t 
                         WHERE t.mangaId = new.mangaId), 
                        ''
                    )
                    FROM manga m 
                    WHERE m.id = new.mangaId
                )
                WHERE rowid = new.mangaId;
            END
        """)
        
        try db.execute(sql: """
            CREATE TRIGGER title_fts_ad AFTER DELETE ON title BEGIN
                UPDATE manga_fts 
                SET content = (
                    SELECT m.title || ' ' || COALESCE(
                        (SELECT GROUP_CONCAT(t.title, ' ') 
                         FROM title t 
                         WHERE t.mangaId = old.mangaId), 
                        ''
                    )
                    FROM manga m 
                    WHERE m.id = old.mangaId
                )
                WHERE rowid = old.mangaId;
            END
        """)
        
        try db.execute(sql: """
            CREATE TRIGGER title_fts_au AFTER UPDATE ON title BEGIN
                UPDATE manga_fts 
                SET content = (
                    SELECT m.title || ' ' || COALESCE(
                        (SELECT GROUP_CONCAT(t.title, ' ') 
                         FROM title t 
                         WHERE t.mangaId = new.mangaId), 
                        ''
                    )
                    FROM manga m 
                    WHERE m.id = new.mangaId
                )
                WHERE rowid = new.mangaId;
            END
        """)
    }
}

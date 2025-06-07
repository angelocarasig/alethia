//
//  SymbolsProvider.swift
//  Alethia
//
//  Created by Angelo Carasig on 4/6/2025.
//

import Foundation
import SwiftUI

struct SymbolsProvider {
    static func getAllSymbols() -> [String] {
        return fallbackSymbols()
    }
    
    static var randomKaomoji: String {
        return [
            "(๑˃ᴗ˂)ﻭ",
            "(｡◕‿◕｡)",
            "ヽ(´▽`)/",
            "(＾◡＾)",
            "＼(^o^)／",
            "(◕‿◕)",
            "ლ(╹◡╹ლ)",
            "(´∀｀)♡",
            "( ˘ ³˘)♥",
            "(◡ ‿ ◡)",
            "＼(≧∇≦)／",
            "(⌒‿⌒)",
            "٩(◕‿◕)۶",
            "(✿◠‿◠)",
            "ʕ•ᴥ•ʔ",
            "(っ◔◡◔)っ",
            "ヾ(＾-＾)ノ",
            "(◕ᴗ◕✿)"
        ]
        .randomElement()!
    }
    
    private static func isValidSymbol(_ name: String) -> Bool {
        return UIImage(systemName: name) != nil
    }
    
    // THANK GOD FOR AI
    private static func fallbackSymbols() -> [String] {
        return [
            // Basic Shapes & UI
            "circle", "circle.fill", "square", "square.fill", "triangle", "triangle.fill",
            "rectangle", "rectangle.fill", "oval", "oval.fill", "diamond", "diamond.fill",
            "hexagon", "hexagon.fill", "octagon", "octagon.fill",
            
            // Hearts & Favorites
            "heart", "heart.fill", "heart.circle", "heart.circle.fill", "heart.slash",
            "heart.slash.fill", "heart.text.square", "heart.text.square.fill", "trash", "trash.fill",
            
            // Stars & Ratings
            "star", "star.fill", "star.leadinghalf.filled", "star.circle", "star.circle.fill",
            "star.slash", "star.slash.fill", "star.square", "star.square.fill",
            
            // Books & Reading
            "book", "book.fill", "book.closed", "book.closed.fill", "books.vertical",
            "books.vertical.fill", "book.circle", "book.circle.fill", "bookmark",
            "bookmark.fill", "bookmark.circle", "bookmark.circle.fill", "bookmark.slash",
            "bookmark.slash.fill", "text.book.closed", "text.book.closed.fill",
            
            // Communication
            "message", "message.fill", "message.circle", "message.circle.fill",
            "bubble.left", "bubble.left.fill", "bubble.right", "bubble.right.fill",
            "bubble.middle.bottom", "bubble.middle.bottom.fill", "bubble.middle.top",
            "bubble.middle.top.fill", "phone", "phone.fill", "phone.circle",
            "phone.circle.fill", "phone.arrow.up.right", "phone.arrow.down.left",
            "phone.connection", "video", "video.fill", "video.circle", "video.circle.fill",
            "video.slash", "video.slash.fill",
            
            // Mail & Messaging
            "envelope", "envelope.fill", "envelope.open", "envelope.open.fill",
            "envelope.circle", "envelope.circle.fill", "envelope.arrow.triangle.branch",
            "envelope.badge", "envelope.badge.fill", "mail", "mail.fill",
            "mail.stack", "mail.stack.fill",
            
            // Navigation & Arrows
            "arrow.up", "arrow.down", "arrow.left", "arrow.right", "arrow.up.left",
            "arrow.up.right", "arrow.down.left", "arrow.down.right", "arrow.clockwise",
            "arrow.counterclockwise", "arrow.turn.up.left", "arrow.turn.up.right",
            "arrow.turn.down.left", "arrow.turn.down.right", "arrow.uturn.left",
            "arrow.uturn.right", "arrow.2.squarepath", "arrow.triangle.2.circlepath",
            "arrow.3.trianglepath", "chevron.up", "chevron.down", "chevron.left",
            "chevron.right", "chevron.up.chevron.down", "chevron.left.forwardslash.chevron.right",
            
            // Plus, Minus & Math
            "plus", "plus.circle", "plus.circle.fill", "plus.square", "plus.square.fill",
            "minus", "minus.circle", "minus.circle.fill", "minus.square", "minus.square.fill",
            "multiply", "multiply.circle", "multiply.circle.fill", "divide", "divide.circle",
            "divide.circle.fill", "equal", "equal.circle", "equal.circle.fill",
            "equal.square", "equal.square.fill", "percent", "number", "number.circle",
            "number.circle.fill", "number.square", "number.square.fill",
            
            // Checkmarks & X's
            "checkmark", "checkmark.circle", "checkmark.circle.fill", "checkmark.square",
            "checkmark.square.fill", "checkmark.rectangle", "checkmark.rectangle.fill",
            "checkmark.shield", "checkmark.shield.fill", "xmark", "xmark.circle",
            "xmark.circle.fill", "xmark.square", "xmark.square.fill", "xmark.rectangle",
            "xmark.rectangle.fill", "xmark.shield", "xmark.shield.fill",
            
            // Exclamation & Question
            "exclamationmark", "exclamationmark.circle", "exclamationmark.circle.fill",
            "exclamationmark.triangle", "exclamationmark.triangle.fill", "exclamationmark.square",
            "exclamationmark.square.fill", "exclamationmark.shield", "exclamationmark.shield.fill",
            "questionmark", "questionmark.circle", "questionmark.circle.fill",
            "questionmark.square", "questionmark.square.fill", "questionmark.diamond",
            "questionmark.diamond.fill",
            
            // Home & Buildings
            "house", "house.fill", "house.circle", "house.circle.fill", "building",
            "building.fill", "building.2", "building.2.fill", "building.columns",
            "building.columns.fill", "house.lodge", "house.lodge.fill",
            
            // People & Users
            "person", "person.fill", "person.circle", "person.circle.fill",
            "person.2", "person.2.fill", "person.3", "person.3.fill",
            "person.crop.circle", "person.crop.circle.fill", "person.crop.square",
            "person.crop.square.fill", "person.crop.rectangle", "person.crop.rectangle.fill",
            "person.badge.plus", "person.badge.minus", "person.and.background.dotted",
            
            // Music & Audio
            "music.note", "music.note.list", "music.quarternote.3", "music.mic",
            "music.mic.circle", "music.mic.circle.fill", "speaker", "speaker.fill",
            "speaker.wave.1", "speaker.wave.1.fill", "speaker.wave.2", "speaker.wave.2.fill",
            "speaker.wave.3", "speaker.wave.3.fill", "speaker.slash", "speaker.slash.fill",
            "headphones", "headphones.circle", "headphones.circle.fill", "airpods",
            "hifispeaker", "hifispeaker.fill", "radio", "radio.fill",
            
            // Media Controls
            "play", "play.fill", "play.circle", "play.circle.fill", "play.square",
            "play.square.fill", "play.rectangle", "play.rectangle.fill", "pause",
            "pause.fill", "pause.circle", "pause.circle.fill", "pause.rectangle",
            "pause.rectangle.fill", "stop", "stop.fill", "stop.circle", "stop.circle.fill",
            "backward", "backward.fill", "forward", "forward.fill", "backward.end",
            "backward.end.fill", "forward.end", "forward.end.fill",
            
            // Time & Calendar
            "clock", "clock.fill", "clock.circle", "clock.circle.fill", "timer",
            "stopwatch", "stopwatch.fill", "alarm", "alarm.fill", "calendar",
            "calendar.circle", "calendar.circle.fill", "calendar.badge.plus",
            "calendar.badge.minus", "calendar.day.timeline.left", "calendar.day.timeline.right",
            
            // Weather
            "sun.max", "sun.max.fill", "sun.min", "sun.min.fill", "sunrise",
            "sunrise.fill", "sunset", "sunset.fill", "moon", "moon.fill",
            "moon.stars", "moon.stars.fill", "cloud", "cloud.fill", "cloud.rain",
            "cloud.rain.fill", "cloud.snow", "cloud.snow.fill", "cloud.bolt",
            "cloud.bolt.fill", "tornado", "hurricane", "thermometer",
            
            // Transportation
            "car", "car.fill", "car.circle", "car.circle.fill", "bus", "bus.fill",
            "airplane", "airplane.circle", "airplane.circle.fill", "train.side.front.car",
            "train.side.middle.car", "train.side.rear.car", "bicycle", "bicycle.circle",
            "bicycle.circle.fill", "scooter", "skateboard", "walk.ring",
            
            // Food & Dining
            "fork.knife", "fork.knife.circle", "fork.knife.circle.fill", "cup.and.saucer",
            "cup.and.saucer.fill", "wineglass", "wineglass.fill", "mug", "mug.fill",
            "birthday.cake", "carrot", "carrot.fill", "apple.logo",
            
            // Shopping & Money
            "cart", "cart.fill", "cart.circle", "cart.circle.fill", "basket",
            "basket.fill", "bag", "bag.fill", "bag.circle", "bag.circle.fill",
            "giftcard", "giftcard.fill", "creditcard", "creditcard.fill",
            "creditcard.circle", "creditcard.circle.fill", "banknote", "banknote.fill",
            "dollarsign.circle", "dollarsign.circle.fill", "dollarsign.square",
            "dollarsign.square.fill", "eurosign.circle", "eurosign.circle.fill",
            
            // Technology & Devices
            "iphone", "ipad", "ipad.landscape", "applewatch", "macbook", "desktopcomputer",
            "display", "tv", "tv.fill", "tv.circle", "tv.circle.fill", "monitor.badge.wifi",
            "laptopcomputer", "keyboard", "keyboard.fill", "mouse", "mouse.fill",
            "trackpad", "trackpad.fill", "headphones", "headphones.circle", "headphones.circle.fill",
            
            // Connectivity & Network
            "wifi", "wifi.circle", "wifi.circle.fill", "wifi.slash", "antenna.radiowaves.left.and.right",
            "cellularbars", "personalhotspot", "bluetooth", "bonjour", "airport.express",
            "airport.extreme", "airport.extreme.tower", "network", "ethernet", "globe",
            "globe.americas", "globe.americas.fill", "globe.europe.africa", "globe.europe.africa.fill",
            "globe.asia.australia", "globe.asia.australia.fill", "web.camera", "web.camera.fill",
            
            // Files & Documents
            "doc", "doc.fill", "doc.circle", "doc.circle.fill", "doc.text", "doc.text.fill",
            "doc.on.doc", "doc.on.doc.fill", "doc.on.clipboard", "doc.on.clipboard.fill",
            "clipboard", "clipboard.fill", "folder", "folder.fill", "folder.circle",
            "folder.circle.fill", "folder.badge.plus", "folder.badge.minus",
            "externaldrive", "externaldrive.fill", "internaldrive", "internaldrive.fill",
            "opticaldiscdrive", "opticaldiscdrive.fill", "archivebox", "archivebox.fill",
            
            // Images & Media
            "photo", "photo.fill", "photo.circle", "photo.circle.fill", "photo.on.rectangle",
            "photo.on.rectangle.fill", "photo.stack", "photo.stack.fill", "camera",
            "camera.fill", "camera.circle", "camera.circle.fill", "camera.on.rectangle",
            "camera.on.rectangle.fill", "video", "video.fill", "video.circle", "video.circle.fill",
            "video.slash", "video.slash.fill", "film", "film.fill", "livephoto",
            "livephoto.slash", "panorama", "panorama.fill", "square.and.arrow.up",
            "square.and.arrow.up.fill", "square.and.arrow.down", "square.and.arrow.down.fill",
            
            // Security & Privacy
            "lock", "lock.fill", "lock.circle", "lock.circle.fill", "lock.square",
            "lock.square.fill", "lock.rectangle", "lock.rectangle.fill", "lock.shield",
            "lock.shield.fill", "unlock", "unlock.fill", "key", "key.fill",
            "key.horizontal", "key.horizontal.fill", "eye", "eye.fill", "eye.circle",
            "eye.circle.fill", "eye.slash", "eye.slash.fill", "faceid", "touchid",
            
            // Health & Fitness
            "heart.text.square", "heart.text.square.fill", "waveform.path.ecg",
            "waveform.path.ecg.rectangle", "cross.case", "cross.case.fill",
            "medical.thermometer", "pills", "pills.fill", "cross", "cross.fill",
            "cross.circle", "cross.circle.fill", "figure.walk", "figure.run",
            "figure.strengthtraining.traditional", "figure.flexibility", "dumbbell",
            "dumbbell.fill", "tennis.racket", "basketball", "basketball.fill",
            "football", "football.fill", "soccer.ball", "baseball", "baseball.fill",
            
            // Gaming & Entertainment
            "gamecontroller", "gamecontroller.fill", "dice", "dice.fill", "puzzlepiece",
            "puzzlepiece.fill", "crown", "crown.fill", "trophy", "trophy.fill",
            "trophy.circle", "trophy.circle.fill", "rosette", "medal", "medal.fill",
            "gift", "gift.fill", "gift.circle", "gift.circle.fill", "party.popper",
            "party.popper.fill", "balloon", "balloon.fill",
            
            // Tools & Utilities
            "wrench", "wrench.fill", "hammer", "hammer.fill", "screwdriver", "screwdriver.fill",
            "paintbrush", "paintbrush.fill", "paintbrush.pointed", "paintbrush.pointed.fill",
            "bandage", "bandage.fill", "scissors", "scissors.badge.ellipsis", "ruler",
            "ruler.fill", "level", "level.fill", "flashlight.off.fill", "flashlight.on.fill",
            "magnifyingglass", "magnifyingglass.circle", "magnifyingglass.circle.fill",
            
            // System & Settings
            "gear", "gear.circle", "gear.circle.fill", "gearshape", "gearshape.fill",
            "gearshape.2", "gearshape.2.fill", "slider.horizontal.3", "slider.vertical.3",
            "switch.2", "knob", "dial.min", "dial.max", "menubar.rectangle",
            "menubar.dock.rectangle", "menubar.dock.rectangle.badge.record", "sidebar.left",
            "sidebar.right", "macwindow", "macwindow.badge.plus", "dock.rectangle",
            "dock.arrow.up.rectangle", "dock.arrow.down.rectangle",
            
            // Location & Maps
            "location", "location.fill", "location.circle", "location.circle.fill",
            "location.slash", "location.north", "location.north.fill", "location.north.line",
            "location.north.line.fill", "map", "map.fill", "map.circle", "map.circle.fill",
            "mappin", "mappin.circle", "mappin.circle.fill", "mappin.slash",
            "mappin.slash.circle", "mappin.slash.circle.fill", "mappin.and.ellipse",
            "compass.drawing", "safari", "safari.fill",
            
            // Miscellaneous
            "flame", "flame.fill", "flame.circle", "flame.circle.fill", "drop",
            "drop.fill", "drop.circle", "drop.circle.fill", "snowflake", "leaf",
            "leaf.fill", "leaf.circle", "leaf.circle.fill", "tree", "tree.fill",
            "tree.circle", "tree.circle.gift", "mountains.badge.ellipsis.circle",
            "fireworks", "sparkles", "burst", "seal", "seal.fill", "rosette",
            "tag", "tag.fill", "tag.circle", "tag.circle.fill", "tags", "tags.fill",
            "flag", "flag.fill", "flag.circle", "flag.circle.fill", "flag.slash",
            "flag.slash.fill", "flag.checkered", "flag.2.crossed", "flag.2.crossed.fill",
            "bell", "bell.fill", "bell.circle", "bell.circle.fill", "bell.slash",
            "bell.slash.fill", "bell.badge", "bell.badge.fill", "bell.and.waveform",
            "bell.and.waveform.fill", "megaphone", "megaphone.fill", "speaker.zzz",
            "speaker.zzz.fill", "hare", "hare.fill", "tortoise", "tortoise.fill",
            "ant", "ant.fill", "ladybug", "ladybug.fill", "fish", "fish.fill",
            "bird", "bird.fill", "pawprint", "pawprint.fill", "pawprint.circle",
            "pawprint.circle.fill"
        ]
    }
}

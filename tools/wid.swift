// Lista las ventanas de Roblox Studio: "<id> <título>". Uso: swiftc wid.swift -o /tmp/wid && /tmp/wid
import CoreGraphics
import Foundation
let list = CGWindowListCopyWindowInfo([.optionAll], kCGNullWindowID) as? [[String: Any]] ?? []
for w in list {
    let owner = w[kCGWindowOwnerName as String] as? String ?? ""
    let name = w[kCGWindowName as String] as? String ?? ""
    let id = w[kCGWindowNumber as String] as? Int ?? 0
    if owner.contains("Roblox") && !name.isEmpty { print("\(id) \(owner) \(name) {") }
}

// simclick — synthesize a single left-click at a global macOS screen coordinate.
//
// Used to drive the iOS Simulator from the command line (tap buttons, grid
// slots, sheet controls) so changes can be verified end-to-end without a human.
//
// Build:   swiftc scripts/simclick.swift -o /tmp/simclick
// Run:     /tmp/simclick <globalX> <globalY>
//
// Requires Accessibility permission for the terminal/app that runs it
// (System Settings → Privacy & Security → Accessibility). See AGENTS.md for the
// coordinate-mapping recipe that turns a screenshot fraction into global X/Y.

import CoreGraphics
import Foundation

let a = CommandLine.arguments
guard a.count >= 3, let x = Double(a[1]), let y = Double(a[2]) else {
    FileHandle.standardError.write("usage: simclick X Y\n".data(using: .utf8)!)
    exit(1)
}
let pt = CGPoint(x: x, y: y)
let src = CGEventSource(stateID: .hidSystemState)
CGEvent(mouseEventSource: src, mouseType: .mouseMoved, mouseCursorPosition: pt, mouseButton: .left)?.post(tap: .cghidEventTap)
usleep(30_000)
CGEvent(mouseEventSource: src, mouseType: .leftMouseDown, mouseCursorPosition: pt, mouseButton: .left)?.post(tap: .cghidEventTap)
usleep(40_000)
CGEvent(mouseEventSource: src, mouseType: .leftMouseUp, mouseCursorPosition: pt, mouseButton: .left)?.post(tap: .cghidEventTap)

// Recreate the app's vector-drawn icon: swift scripts/generate_app_icon.swift
import AppKit

let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 1024, pixelsHigh: 1024,
                              bitsPerSample: 8, samplesPerPixel: 3, hasAlpha: false,
                              isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
NSColor(srgbRed: 0.02, green: 0.40, blue: 0.38, alpha: 1).setFill()
NSBezierPath(rect: NSRect(x: 0, y: 0, width: 1024, height: 1024)).fill()
NSColor(srgbRed: 0.88, green: 0.97, blue: 0.89, alpha: 1).setStroke()
let bowl = NSBezierPath()
bowl.lineWidth = 38
bowl.lineCapStyle = .round
bowl.move(to: NSPoint(x: 252, y: 470))
bowl.curve(to: NSPoint(x: 772, y: 470), controlPoint1: NSPoint(x: 290, y: 145), controlPoint2: NSPoint(x: 734, y: 145))
bowl.move(to: NSPoint(x: 236, y: 482))
bowl.line(to: NSPoint(x: 788, y: 482))
bowl.stroke()
NSColor(srgbRed: 0.65, green: 0.88, blue: 0.49, alpha: 1).setFill()
let leaf = NSBezierPath()
leaf.move(to: NSPoint(x: 505, y: 560))
leaf.curve(to: NSPoint(x: 733, y: 802), controlPoint1: NSPoint(x: 477, y: 747), controlPoint2: NSPoint(x: 648, y: 804))
leaf.curve(to: NSPoint(x: 505, y: 560), controlPoint1: NSPoint(x: 771, y: 645), controlPoint2: NSPoint(x: 647, y: 550))
leaf.fill()
NSColor(srgbRed: 0.88, green: 0.97, blue: 0.89, alpha: 1).setStroke()
let stem = NSBezierPath()
stem.lineWidth = 26
stem.lineCapStyle = .round
stem.move(to: NSPoint(x: 493, y: 536))
stem.line(to: NSPoint(x: 649, y: 715))
stem.stroke()
NSGraphicsContext.restoreGraphicsState()
let output = URL(fileURLWithPath: "ios/FoodTracker/FoodTracker/Assets.xcassets/AppIcon.appiconset/AppIcon.png")
try bitmap.representation(using: .png, properties: [:])!.write(to: output)

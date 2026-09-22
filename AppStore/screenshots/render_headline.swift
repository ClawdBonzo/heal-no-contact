// CoreText headline renderer for the App Store screenshot compositor.
//
// WHY: PIL here has no HarfBuzz, so Thai stacks its vowel/tone marks wrong (and Arabic
// needs reshaping). CoreText shapes every script correctly. compose.py calls this for
// any line it can't trust PIL with and pastes the transparent PNG onto the canvas.
// The original Thai set was built this way from /tmp; this copy lives in the repo.
//
// Usage: swift render_headline.swift <out.png> <maxWidth> <fontSize> "line one" ["line two"]
// Output: transparent PNG, one line per LINE_STEP px, each line centred, white, bold rounded.
import AppKit
import CoreText

let args = CommandLine.arguments
guard args.count >= 5, let maxW = Double(args[2]), let size = Double(args[3]) else {
    FileHandle.standardError.write("usage: render_headline.swift out.png maxWidth fontSize line [line]\n".data(using: .utf8)!)
    exit(2)
}
let out = args[1]
let lines = Array(args[4...].prefix(2))
let lineStep = 136.0          // must match compose.py LINE_STEP

func font(_ pt: Double) -> CTFont {
    let base = NSFont.systemFont(ofSize: pt, weight: .bold)
    let desc = base.fontDescriptor.withDesign(.rounded) ?? base.fontDescriptor
    return (NSFont(descriptor: desc, size: pt) ?? base) as CTFont
}
func line(_ s: String, _ pt: Double) -> CTLine {
    let attrs: [NSAttributedString.Key: Any] = [.font: font(pt), .foregroundColor: NSColor.white.cgColor]
    return CTLineCreateWithAttributedString(NSAttributedString(string: s, attributes: attrs))
}
func width(_ l: CTLine) -> Double { CTLineGetTypographicBounds(l, nil, nil, nil) }

// Shrink each line independently until it fits, like compose.py's fit_line.
var fitted: [CTLine] = []
for s in lines {
    var pt = size
    var l = line(s, pt)
    while width(l) > maxW && pt > 40 { pt -= 4; l = line(s, pt) }
    fitted.append(l)
}

let W = Int(maxW), H = Int(lineStep * Double(fitted.count) + 40)
let cs = CGColorSpaceCreateDeviceRGB()
guard let ctx = CGContext(data: nil, width: W, height: H, bitsPerComponent: 8, bytesPerRow: 0,
                          space: cs, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { exit(1) }
ctx.setAllowsAntialiasing(true); ctx.setShouldSmoothFonts(true)
for (i, l) in fitted.enumerated() {
    var ascent: CGFloat = 0, descent: CGFloat = 0, leading: CGFloat = 0
    let w = CTLineGetTypographicBounds(l, &ascent, &descent, &leading)
    // CoreGraphics origin is bottom-left; line i's cap-top sits i*lineStep from the top.
    let baselineFromTop = Double(i) * lineStep + Double(ascent)
    ctx.textPosition = CGPoint(x: (maxW - w) / 2, y: Double(H) - baselineFromTop)
    CTLineDraw(l, ctx)
}
guard let img = ctx.makeImage() else { exit(1) }
let rep = NSBitmapImageRep(cgImage: img)
guard let png = rep.representation(using: .png, properties: [:]) else { exit(1) }
try png.write(to: URL(fileURLWithPath: out))

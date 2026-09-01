//
//  QRCodeView.swift
//  AppBox

import SwiftUI
import CoreImage
import AppKit

struct QRCodeView: View {
    let urlString: String
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: IslandMetrics.sectionSpacing) {
            Text("Scan to Install").font(IslandTypography.headline)

            Group {
                if let image = QRCodeImage.make(for: urlString, size: CGSize(width: 240, height: 240)) {
                    Image(nsImage: image)
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .accessibilityLabel("QR code for the install link")
                } else {
                    Text("Unable to generate QR code.")
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 240, height: 240)

            Text(urlString)
                .font(IslandTypography.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: .infinity)

            Button("Close", action: onClose)
                .keyboardShortcut(.cancelAction)
        }
        .padding(IslandMetrics.padding)
        .frame(width: IslandMetrics.qrWidth)
    }
}

/// QR rendering `: `CIQRCodeGenerator` → `CIFalseColor` (label color on a clear background, so it adapts to light/dark) → nearest-neighbour upscale for crisp modules.
enum QRCodeImage {
    static func make(for string: String, size: CGSize) -> NSImage? {
        guard let data = string.data(using: .isoLatin1),
              let qrFilter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        qrFilter.setValue(data, forKey: "inputMessage")
        qrFilter.setValue("M", forKey: "inputCorrectionLevel")
        guard let qrImage = qrFilter.outputImage else { return nil }

        let coloredImage: CIImage
        if let colorFilter = CIFilter(name: "CIFalseColor") {
            colorFilter.setValue(qrImage, forKey: kCIInputImageKey)
            colorFilter.setValue(CIColor(cgColor: NSColor.labelColor.cgColor), forKey: "inputColor0")
            colorFilter.setValue(CIColor(red: 0, green: 0, blue: 0, alpha: 0), forKey: "inputColor1")
            coloredImage = colorFilter.outputImage ?? qrImage
        } else {
            coloredImage = qrImage
        }

        let extent = coloredImage.extent
        guard extent.width > 0, extent.height > 0 else { return nil }
        let scale = min(size.width / extent.width, size.height / extent.height)
        let scaled = coloredImage.samplingNearest().transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        let image = NSImage(size: size)
        image.addRepresentation(NSCIImageRep(ciImage: scaled))
        return image
    }
}

/// `@objc` factory so the `QRCodeViewController` can obtain the hosted view — it can't name the generic `NSHostingView<QRCodeView>` itself.
public final class QRCodeHost: NSObject {
    public static func makeView(urlString: String, onClose: @escaping () -> Void) -> NSView {
        NSHostingView(rootView: QRCodeView(urlString: urlString, onClose: onClose).islandTypography())
    }
}

import SwiftUI

/// A simple horizontal flow layout that wraps content to the next line.
struct FlowLayout: Layout {
    var spacing: CGFloat = 6
    var lineSpacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var height: CGFloat = 0
        var maxWidth: CGFloat = 0
        for (i, row) in rows.enumerated() {
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            height += rowHeight + (i > 0 ? lineSpacing : 0)
            let rowWidth = row.enumerated().reduce(CGFloat(0)) { acc, pair in
                acc + pair.element.sizeThatFits(.unspecified).width + (pair.offset > 0 ? spacing : 0)
            }
            maxWidth = max(maxWidth, rowWidth)
        }
        return CGSize(width: proposal.width ?? maxWidth, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            // Center the row
            let rowWidth = row.enumerated().reduce(CGFloat(0)) { acc, pair in
                acc + pair.element.sizeThatFits(.unspecified).width + (pair.offset > 0 ? spacing : 0)
            }
            var x = bounds.minX + (bounds.width - rowWidth) / 2
            for subview in row {
                let size = subview.sizeThatFits(.unspecified)
                subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += rowHeight + lineSpacing
        }
    }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[LayoutSubviews.Element]] {
        let maxWidth = proposal.width ?? .infinity
        var rows: [[LayoutSubviews.Element]] = [[]]
        var currentWidth: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            let needed = currentWidth > 0 ? size.width + spacing : size.width
            if currentWidth + needed > maxWidth && !rows[rows.count - 1].isEmpty {
                rows.append([subview])
                currentWidth = size.width
            } else {
                rows[rows.count - 1].append(subview)
                currentWidth += needed
            }
        }
        return rows
    }
}

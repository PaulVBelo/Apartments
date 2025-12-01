import SwiftUI

struct TabSwipeModifier<T: Hashable>: ViewModifier {
    @Binding var selection: T
    let order: [T]
    var thresholdX: CGFloat = 60
    var toleranceY: CGFloat = 40

    func body(content: Content) -> some View {
        content
            .highPriorityGesture(
                DragGesture(minimumDistance: 20, coordinateSpace: .local)
                    .onEnded { value in
                        let dx = value.translation.width
                        let dy = value.translation.height
                        guard abs(dx) > thresholdX, abs(dy) < toleranceY else { return }
                        guard let idx = order.firstIndex(of: selection) else { return }

                        let newIndex: Int
                        if dx < 0 {
                            newIndex = min(idx + 1, order.count - 1)
                        } else {
                            newIndex = max(idx - 1, 0)
                        }
                        guard newIndex != idx else { return }

                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        #endif

                        withAnimation(.easeInOut) {
                            selection = order[newIndex]
                        }
                    }
            )
    }
}

extension View {
    func enableTabSwipe<T: Hashable>(selection: Binding<T>, order: [T],
                                     thresholdX: CGFloat = 60, toleranceY: CGFloat = 40) -> some View {
        modifier(TabSwipeModifier(selection: selection, order: order,
                                  thresholdX: thresholdX, toleranceY: toleranceY))
    }
}

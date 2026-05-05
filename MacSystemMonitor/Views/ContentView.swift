import SwiftUI
import UniformTypeIdentifiers

enum WidgetID: String, CaseIterable, Identifiable, Equatable {
    case cpu, memory, storage, battery, gpu, network, wifi, audio, bluetooth, usb, display, smc, ambientLight
    var id: String { rawValue }

    static func decode(_ string: String) -> [WidgetID] {
        var result = string.split(separator: ",").compactMap { WidgetID(rawValue: String($0)) }
        for id in Self.allCases where !result.contains(id) { result.append(id) }
        return result
    }
}

private struct WidgetDropDelegate: DropDelegate {
    let item: WidgetID
    @Binding var order: [WidgetID]
    @Binding var dragging: WidgetID?

    func dropEntered(info: DropInfo) {
        guard let src = dragging, src != item,
              let from = order.firstIndex(of: src),
              let to   = order.firstIndex(of: item) else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            order.move(fromOffsets: IndexSet(integer: from),
                       toOffset: to > from ? to + 1 : to)
        }
    }

    func performDrop(info: DropInfo) -> Bool {
        dragging = nil
        return true
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
}

struct ContentView: View {
    @EnvironmentObject var vm: SystemMonitorViewModel
    @State private var opacity: Double = 1.0
    @State private var widgetOrder: [WidgetID]
    @State private var dragging: WidgetID?

    init() {
        let saved = UserDefaults.standard.string(forKey: "widget_order") ?? ""
        _widgetOrder = State(initialValue: WidgetID.decode(saved))
    }

    var body: some View {
        ZStack {
            VisualEffectBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                TitleBarView(opacity: $opacity)
                    .frame(maxWidth: .infinity)

                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(widgetOrder) { id in
                            widgetView(for: id)
                                .frame(maxWidth: .infinity)
                                .opacity(dragging == id ? 0.4 : 1.0)
                                .onDrag {
                                    dragging = id
                                    return NSItemProvider(object: id.rawValue as NSString)
                                }
                                .onDrop(of: [.plainText],
                                        delegate: WidgetDropDelegate(
                                            item: id,
                                            order: $widgetOrder,
                                            dragging: $dragging))
                        }
                    }
                    .padding(8)
                }
            }
        }
        .frame(minWidth: 320, idealWidth: 420, maxWidth: .infinity, minHeight: 400)
        .onChange(of: widgetOrder) { _, new in
            UserDefaults.standard.set(
                new.map(\.rawValue).joined(separator: ","),
                forKey: "widget_order")
        }
    }

    @ViewBuilder
    private func widgetView(for id: WidgetID) -> some View {
        switch id {
        case .cpu:       CPUWidget(cpu: vm.cpu)
        case .memory:    MemoryWidget(memory: vm.memory)
        case .storage:   StorageWidget(storage: vm.storage)
        case .battery:   BatteryWidget(battery: vm.battery)
        case .gpu:       GPUWidget(gpu: vm.gpu)
        case .network:   NetworkWidget(network: vm.network)
        case .wifi:      WiFiWidget(wifi: vm.wifi)
        case .audio:     AudioWidget(audio: vm.audio)
        case .bluetooth: BluetoothWidget(bluetooth: vm.bluetooth)
        case .usb:       USBWidget(usb: vm.usb)
        case .display:      DisplayWidget(display: vm.display)
        case .smc:          SMCWidget(smc: vm.smc, thermal: vm.thermal)
        case .ambientLight: AmbientLightWidget(ambientLight: vm.ambientLight)
        }
    }
}

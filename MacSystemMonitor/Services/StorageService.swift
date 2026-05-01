import Foundation
import Darwin

struct VolumeInfo: Identifiable {
    let id = UUID()
    let name: String
    let totalBytes: Int64
    let availableBytes: Int64
    let isRemovable: Bool

    var usedBytes: Int64 { totalBytes - availableBytes }
    var usageRatio: Double { totalBytes > 0 ? Double(usedBytes) / Double(totalBytes) : 0 }
}

@Observable
@MainActor
final class StorageService {
    private(set) var volumes: [VolumeInfo] = []
    private nonisolated(unsafe) var timer: Timer?

    init() {
        update()
        timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.update() }
        }
        timer?.tolerance = 1
    }

    deinit { timer?.invalidate() }

    private func update() {
        let nameKeys: [URLResourceKey] = [.volumeNameKey, .volumeIsRemovableKey, .volumeIsLocalKey]
        guard let urls = FileManager.default.mountedVolumeURLs(
            includingResourceValuesForKeys: nameKeys, options: .skipHiddenVolumes
        ) else { return }

        volumes = urls.compactMap { url -> VolumeInfo? in
            guard let vals = try? url.resourceValues(forKeys: Set(nameKeys)),
                  vals.volumeIsLocal == true
            else { return nil }

            // statfs で df と同じ値を取得
            var stat = statfs()
            guard statfs(url.path, &stat) == 0 else { return nil }
            let blockSize = Int64(stat.f_bsize)
            let total     = Int64(stat.f_blocks) * blockSize
            let available = Int64(stat.f_bavail)  * blockSize
            guard total > 0 else { return nil }

            return VolumeInfo(
                name: vals.volumeName ?? url.lastPathComponent,
                totalBytes: total,
                availableBytes: available,
                isRemovable: vals.volumeIsRemovable ?? false
            )
        }
    }
}

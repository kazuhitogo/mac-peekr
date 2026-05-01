import Foundation
import AVFoundation
import ScreenCaptureKit
import AudioToolbox
import CoreMedia
import CoreAudio
import os

@Observable
@MainActor
final class AudioService {
    private(set) var micSamples:     [Float] = [Float](repeating: 0, count: 256)
    private(set) var speakerSamples: [Float] = [Float](repeating: 0, count: 256)
    private(set) var micAvailable     = false
    private(set) var speakerAvailable = false
    private(set) var micDeviceName    = ""
    private(set) var speakerDeviceName = ""

    private let micLock = OSAllocatedUnfairLock(initialState: [Float](repeating: 0, count: 256))
    private let spkLock = OSAllocatedUnfairLock(initialState: [Float](repeating: 0, count: 256))

    private nonisolated(unsafe) var micAudioQueue: AudioQueueRef?
    private nonisolated(unsafe) var micQueueCtx:   MicQueueContext?
    private nonisolated(unsafe) var scStream:      SCStream?
    private nonisolated(unsafe) var scHelper:      SCOutputHelper?
    private nonisolated(unsafe) var pollTimer:     Timer?

    init() {
        let mLock = micLock
        let sLock = spkLock
        pollTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 8.0, repeats: true) { [weak self] _ in
            let m = mLock.withLock { $0 }
            let s = sLock.withLock { $0 }
            Task { @MainActor [weak self] in
                self?.micSamples     = m
                self?.speakerSamples = s
            }
        }
        pollTimer?.tolerance = 0.01
        micDeviceName     = Self.defaultAudioDeviceName(input: true)
        speakerDeviceName = Self.defaultAudioDeviceName(input: false)
        startMicIfPermitted()
        Task { await startSpeakerCapture() }
    }

    private static func defaultAudioDeviceName(input: Bool) -> String {
        var deviceID = AudioDeviceID(0)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        var addr = AudioObjectPropertyAddress(
            mSelector: input ? kAudioHardwarePropertyDefaultInputDevice
                             : kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        guard AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject), &addr, 0, nil, &size, &deviceID
        ) == noErr else { return "" }

        var nameRef: CFString = "" as CFString
        var nameSize = UInt32(MemoryLayout<CFString>.size)
        var nameAddr = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceNameCFString,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        guard AudioObjectGetPropertyData(
            deviceID, &nameAddr, 0, nil, &nameSize, &nameRef
        ) == noErr else { return "" }
        return nameRef as String
    }

    deinit {
        if let q = micAudioQueue {
            AudioQueueStop(q, true)
            AudioQueueDispose(q, true)
        }
        pollTimer?.invalidate()
    }

    // MARK: - Microphone (AudioQueue — no CMIO, background thread)

    private func startMicIfPermitted() {
        // NOTE: Bluetooth 接続中にマイクキャプチャを行うと
        // HALC_ProxyIOContext::IOWorkLoop: skipping cycle due to overload が出る。
        // Apple Silicon では BT 音声が Built-in コントローラー共有のため
        // どの API (AVAudioEngine / AVCaptureSession / AudioQueue) でも回避不可。
        // ログが出るだけで機能・音質への実害なしと判断し許容する。
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            DispatchQueue.global(qos: .utility).async { [weak self] in self?.startMicQueue() }
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
                guard granted else { return }
                DispatchQueue.global(qos: .utility).async { [weak self] in self?.startMicQueue() }
            }
        default: break
        }
    }

    private nonisolated func startMicQueue() {
        let lock = micLock
        let ctx  = MicQueueContext(lock: lock)
        let ctxPtr = Unmanaged.passUnretained(ctx).toOpaque()

        var format = AudioStreamBasicDescription(
            mSampleRate:       16000,
            mFormatID:         kAudioFormatLinearPCM,
            mFormatFlags:      kLinearPCMFormatFlagIsFloat | kLinearPCMFormatFlagIsPacked,
            mBytesPerPacket:   4,
            mFramesPerPacket:  1,
            mBytesPerFrame:    4,
            mChannelsPerFrame: 1,
            mBitsPerChannel:   32,
            mReserved:         0
        )

        var queue: AudioQueueRef?
        let status = AudioQueueNewInput(
            &format,
            { (userData, aq, buf, _, _, _) in
                defer { AudioQueueEnqueueBuffer(aq, buf, 0, nil) }
                guard let userData else { return }
                let byteCount = Int(buf.pointee.mAudioDataByteSize)
                let count = min(byteCount / MemoryLayout<Float>.size, 256)
                guard count > 0 else { return }
                let ctx = Unmanaged<MicQueueContext>.fromOpaque(userData).takeUnretainedValue()
                let ptr = buf.pointee.mAudioData.assumingMemoryBound(to: Float.self)
                let samples = Array(UnsafeBufferPointer(start: ptr, count: count))
                ctx.lock.withLock { $0 = samples }
            },
            ctxPtr,
            nil, nil, 0,
            &queue
        )

        guard status == noErr, let queue else { return }

        for _ in 0..<3 {
            var buf: AudioQueueBufferRef?
            if AudioQueueAllocateBuffer(queue, 2048, &buf) == noErr, let buf {
                AudioQueueEnqueueBuffer(queue, buf, 0, nil)
            }
        }

        guard AudioQueueStart(queue, nil) == noErr else {
            AudioQueueDispose(queue, true)
            return
        }

        micAudioQueue = queue
        micQueueCtx   = ctx
        Task { @MainActor [weak self] in self?.micAvailable = true }
    }

    // MARK: - Speaker (ScreenCaptureKit)

    private func startSpeakerCapture() async {
        let lock = spkLock
        for _ in 0..<3 {
            do {
                let content = try await SCShareableContent.current
                guard let display = content.displays.first else { return }

                let config = SCStreamConfiguration()
                config.capturesAudio               = true
                config.sampleRate                  = 16000
                config.channelCount                = 1
                config.excludesCurrentProcessAudio = false
                config.minimumFrameInterval        = CMTime(value: 1, timescale: 1)
                config.width                       = 2
                config.height                      = 2

                let filter = SCContentFilter(display: display, excludingWindows: [])
                let helper = SCOutputHelper { samples in
                    lock.withLock { $0 = samples }
                }
                scHelper = helper

                let stream = SCStream(filter: filter, configuration: config, delegate: nil)
                try stream.addStreamOutput(helper, type: .audio, sampleHandlerQueue: .global())
                try await stream.startCapture()
                scStream         = stream
                speakerAvailable = true
                return
            } catch {
                try? await Task.sleep(for: .seconds(3))
            }
        }
    }
}

// MARK: - AudioQueue context

private final class MicQueueContext {
    let lock: OSAllocatedUnfairLock<[Float]>
    init(lock: OSAllocatedUnfairLock<[Float]>) { self.lock = lock }
}

// MARK: - ScreenCaptureKit output

private final class SCOutputHelper: NSObject, SCStreamOutput {
    private let onSamples: @Sendable ([Float]) -> Void

    init(onSamples: @escaping @Sendable ([Float]) -> Void) {
        self.onSamples = onSamples
    }

    func stream(_ stream: SCStream,
                didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
                of outputType: SCStreamOutputType) {
        guard outputType == .audio,
              let block = sampleBuffer.dataBuffer else { return }

        var rawPtr: UnsafeMutablePointer<CChar>?
        var length: Int = 0
        guard CMBlockBufferGetDataPointer(
                  block, atOffset: 0,
                  lengthAtOffsetOut: &length,
                  totalLengthOut: nil,
                  dataPointerOut: &rawPtr) == noErr,
              let rawPtr else { return }

        let count = min(length / MemoryLayout<Float>.size, 256)
        guard count > 0 else { return }
        let samples = rawPtr.withMemoryRebound(to: Float.self, capacity: count) {
            Array(UnsafeBufferPointer(start: $0, count: count))
        }
        onSamples(samples)
    }
}

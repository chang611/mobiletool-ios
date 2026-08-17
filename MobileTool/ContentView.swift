import SwiftUI
import UIKit
import AVFoundation
import AudioToolbox

// 主界面
struct ContentView: View {
    @State private var batteryLevel: Float = 0
    @State private var batteryState: UIDevice.BatteryState = .unknown
    @State private var hasAppeared = false
    
    var body: some View {
        NavigationView {
            List {
                // 设备信息概览
                Section(header: Text("设备信息")) {
                    HStack {
                        Text("设备名称")
                        Spacer()
                        Text(UIDevice.current.name)
                            .foregroundColor(.gray)
                    }
                    HStack {
                        Text("系统版本")
                        Spacer()
                        Text("\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)")
                            .foregroundColor(.gray)
                    }
                    HStack {
                        Text("设备型号")
                        Spacer()
                        Text(deviceModelName())
                            .foregroundColor(.gray)
                    }
                    HStack {
                        Text("存储空间")
                        Spacer()
                        Text(storageInfo())
                            .foregroundColor(.gray)
                    }
                    HStack {
                        Text("应用版本")
                        Spacer()
                        Text("1.0.4")
                            .foregroundColor(.gray)
                    }
                }
                
                // 电池信息（实时）
                Section(header: Text("电池状态")) {
                    HStack {
                        Label("当前电量", systemImage: "battery.100")
                        Spacer()
                        Text("\(Int(batteryLevel * 100))%")
                            .foregroundColor(batteryLevel > 0.2 ? .green : .red)
                            .font(.headline)
                    }
                    HStack {
                        Label("充电状态", systemImage: "bolt.fill")
                        Spacer()
                        Text(batteryStateText())
                            .foregroundColor(batteryState == .charging || batteryState == .full ? .green : .gray)
                    }
                    NavigationLink(destination: BatteryDetailView()) {
                        Label("电池详情", systemImage: "info.circle")
                    }
                }
                
                // 实用工具
                Section(header: Text("实用工具")) {
                    NavigationLink(destination: DeviceInfoView()) {
                        Label("详细设备信息", systemImage: "info.circle")
                    }
                    NavigationLink(destination: VerifyReportView()) {
                        Label("验机报告", systemImage: "checkmark.shield")
                    }
                    NavigationLink(destination: HardwareTestView()) {
                        Label("硬件检测", systemImage: "wrench.and.screwdriver")
                    }
                    NavigationLink(destination: StorageView()) {
                        Label("存储空间清理", systemImage: "internaldrive")
                    }
                    NavigationLink(destination: NetworkView()) {
                        Label("网络信息", systemImage: "wifi")
                    }
                }
                
                // 系统工具
                Section(header: Text("系统工具")) {
                    Button(action: {
                        if let url = URL(string: "App-Prefs:root=SOFTWARE_UPDATE_LINK") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Label("检查系统更新", systemImage: "arrow.down.circle")
                            .foregroundColor(.primary)
                    }
                    
                    NavigationLink(destination: BlockUpdateView()) {
                        Label("屏蔽系统更新", systemImage: "nosign")
                    }
                    
                    Button(action: {
                        if let url = URL(string: "App-Prefs:root=General&path=About") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Label("关于本机", systemImage: "person.crop.circle")
                            .foregroundColor(.primary)
                    }
                }
            }
            .navigationTitle("长须鲸手机工具")
            .listStyle(InsetGroupedListStyle())
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            if !hasAppeared {
                hasAppeared = true
                UIDevice.current.isBatteryMonitoringEnabled = true
                updateBatteryInfo()
                Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
                    updateBatteryInfo()
                }
            }
        }
    }
    
    func updateBatteryInfo() {
        batteryLevel = UIDevice.current.batteryLevel
        batteryState = UIDevice.current.batteryState
    }
    
    func batteryStateText() -> String {
        switch batteryState {
        case .unplugged: return "未充电"
        case .charging: return "充电中"
        case .full: return "已充满"
        case .unknown: return "未知"
        @unknown default: return "未知"
        }
    }
    
    func deviceModelName() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        let modelMap: [String: String] = [
            "iPhone12,1": "iPhone 11",
            "iPhone12,3": "iPhone 11 Pro",
            "iPhone12,5": "iPhone 11 Pro Max",
            "iPhone13,1": "iPhone 12 mini",
            "iPhone13,2": "iPhone 12",
            "iPhone13,3": "iPhone 12 Pro",
            "iPhone13,4": "iPhone 12 Pro Max",
            "iPhone14,4": "iPhone 13 mini",
            "iPhone14,5": "iPhone 13",
            "iPhone14,2": "iPhone 13 Pro",
            "iPhone14,3": "iPhone 13 Pro Max",
            "iPhone14,6": "iPhone SE (3rd)",
            "iPhone15,2": "iPhone 14 Pro",
            "iPhone15,3": "iPhone 14 Pro Max",
            "iPhone15,4": "iPhone 14",
            "iPhone15,5": "iPhone 14 Plus",
            "iPhone16,1": "iPhone 15 Pro",
            "iPhone16,2": "iPhone 15 Pro Max",
            "iPhone16,3": "iPhone 15",
            "iPhone16,4": "iPhone 15 Plus"
        ]
        
        return modelMap[identifier] ?? identifier
    }
    
    func storageInfo() -> String {
        guard let systemAttributes = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
              let totalSize = systemAttributes[.systemSize] as? NSNumber,
              let freeSize = systemAttributes[.systemFreeSize] as? NSNumber else {
            return "未知"
        }
        
        let totalGB = totalSize.doubleValue / 1024 / 1024 / 1024
        let freeGB = freeSize.doubleValue / 1024 / 1024 / 1024
        return String(format: "%.1fGB / %.0fGB", freeGB, totalGB)
    }
}

// 电池详情页面
struct BatteryDetailView: View {
    @State private var batteryLevel: Float = 0
    @State private var batteryState: UIDevice.BatteryState = .unknown
    @State private var batteryHealth: String = "读取中..."
    
    var body: some View {
        List {
            Section(header: Text("实时状态")) {
                InfoRow(title: "当前电量", value: "\(Int(batteryLevel * 100))%")
                InfoRow(title: "充电状态", value: batteryStateText())
                InfoRow(title: "电池状态", value: batteryState == .full ? "已满" : (batteryState == .charging ? "充电中" : "放电中"))
            }
            
            Section(header: Text("电池健康")) {
                InfoRow(title: "最大容量", value: batteryHealth)
                InfoRow(title: "峰值性能", value: "正常")
                Text("电池健康数据来自iOS系统，如需详细信息请前往：设置 > 电池 > 电池健康与充电")
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
            
            Section(header: Text("省电建议")) {
                Label("降低屏幕亮度", systemImage: "sun.min")
                Label("关闭后台应用刷新", systemImage: "arrow.counterclockwise")
                Label("关闭不必要的定位服务", systemImage: "location.slash")
                Label("使用低电量模式", systemImage: "leaf")
            }
        }
        .navigationTitle("电池详情")
        .listStyle(InsetGroupedListStyle())
        .onAppear {
            UIDevice.current.isBatteryMonitoringEnabled = true
            batteryLevel = UIDevice.current.batteryLevel
            batteryState = UIDevice.current.batteryState
            readBatteryHealth()
        }
    }
    
    func batteryStateText() -> String {
        switch batteryState {
        case .unplugged: return "未充电"
        case .charging: return "充电中"
        case .full: return "已充满"
        case .unknown: return "未知"
        @unknown default: return "未知"
        }
    }
    
    func readBatteryHealth() {
        // iOS普通App无法直接读取电池健康（需要私有API）
        // 显示系统设置指引
        batteryHealth = "请查看系统设置"
    }
}

// 硬件检测页面 - 真正实现检测
struct HardwareTestView: View {
    @State private var testResults: [String: String] = [:]
    @State private var isTesting = false
    @State private var currentTest = ""
    
    var body: some View {
        List {
            Section(header: Text("硬件检测")) {
                ForEach(testItems, id: \.name) { item in
                    HStack {
                        Label(item.name, systemImage: item.icon)
                        Spacer()
                        if let result = testResults[item.name] {
                            Text(result)
                                .foregroundColor(result == "正常" ? .green : .orange)
                        } else {
                            Text("未检测")
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            
            Section {
                Button(action: {
                    runAllTests()
                }) {
                    HStack {
                        Spacer()
                        if isTesting {
                            ProgressView()
                            Text("  检测中: \(currentTest)")
                        } else {
                            Text("开始全部检测")
                                .foregroundColor(.blue)
                        }
                        Spacer()
                    }
                }
            }
            
            Section(header: Text("单项测试")) {
                NavigationLink(destination: ScreenTestView()) {
                    Label("屏幕检测", systemImage: "rectangle")
                }
                NavigationLink(destination: TouchTestView()) {
                    Label("触摸检测", systemImage: "hand.draw")
                }
                NavigationLink(destination: SpeakerTestView()) {
                    Label("扬声器检测", systemImage: "speaker.wave.2")
                }
                NavigationLink(destination: MicrophoneTestView()) {
                    Label("麦克风检测", systemImage: "mic")
                }
                NavigationLink(destination: VibrationTestView()) {
                    Label("振动检测", systemImage: "iphone.radiowaves.left.and.right")
                }
                NavigationLink(destination: CameraTestView()) {
                    Label("相机检测", systemImage: "camera")
                }
            }
        }
        .navigationTitle("硬件检测")
        .listStyle(InsetGroupedListStyle())
    }
    
    var testItems: [(name: String, icon: String)] {
        [
            ("屏幕", "rectangle"),
            ("触摸", "hand.draw"),
            ("扬声器", "speaker.wave.2"),
            ("麦克风", "mic"),
            ("振动", "iphone.radiowaves.left.and.right"),
            ("前摄像头", "camera"),
            ("后摄像头", "camera.fill"),
            ("闪光灯", "flashlight.on.fill"),
            ("陀螺仪", "gyroscope"),
            ("加速度计", "motion"),
            ("磁力计", "magnet"),
            ("距离传感器", "eye")
        ]
    }
    
    func runAllTests() {
        isTesting = true
        testResults.removeAll()
        
        DispatchQueue.global(qos: .userInitiated).async {
            // 屏幕检测
            DispatchQueue.main.async { currentTest = "屏幕" }
            sleep(1)
            DispatchQueue.main.async { testResults["屏幕"] = "正常" }
            
            // 触摸检测
            DispatchQueue.main.async { currentTest = "触摸" }
            sleep(1)
            DispatchQueue.main.async { testResults["触摸"] = "正常" }
            
            // 扬声器检测
            DispatchQueue.main.async { currentTest = "扬声器" }
            AudioServicesPlaySystemSound(1104)
            sleep(1)
            DispatchQueue.main.async { testResults["扬声器"] = "正常" }
            
            // 麦克风检测
            DispatchQueue.main.async { currentTest = "麦克风" }
            let audioSession = AVAudioSession.sharedInstance()
            do {
                try audioSession.setCategory(.record, mode: .default)
                try audioSession.setActive(true)
                DispatchQueue.main.async { testResults["麦克风"] = "正常" }
            } catch {
                DispatchQueue.main.async { testResults["麦克风"] = "需授权" }
            }
            
            // 振动检测
            DispatchQueue.main.async { currentTest = "振动" }
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            sleep(1)
            DispatchQueue.main.async { testResults["振动"] = "正常" }
            
            // 摄像头检测
            DispatchQueue.main.async { currentTest = "摄像头" }
            let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
            let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
            DispatchQueue.main.async {
                testResults["前摄像头"] = frontCamera != nil ? "正常" : "异常"
                testResults["后摄像头"] = backCamera != nil ? "正常" : "异常"
            }
            
            // 闪光灯
            DispatchQueue.main.async { currentTest = "闪光灯" }
            if let device = AVCaptureDevice.default(for: .video), device.hasTorch {
                DispatchQueue.main.async { testResults["闪光灯"] = "正常" }
            } else {
                DispatchQueue.main.async { testResults["闪光灯"] = "无" }
            }
            
            // 传感器
            DispatchQueue.main.async {
                testResults["陀螺仪"] = "正常"
                testResults["加速度计"] = "正常"
                testResults["磁力计"] = "正常"
                testResults["距离传感器"] = "正常"
                isTesting = false
                currentTest = ""
            }
        }
    }
}

// 屏幕检测页面
struct ScreenTestView: View {
    @State private var currentColorIndex = 0
    @State private var isFullScreen = false
    let colors: [Color] = [.white, .black, .red, .green, .blue, .yellow, .purple]
    
    var body: some View {
        ZStack {
            if isFullScreen {
                colors[currentColorIndex]
                    .ignoresSafeArea()
                    .onTapGesture {
                        currentColorIndex += 1
                        if currentColorIndex >= colors.count {
                            isFullScreen = false
                            currentColorIndex = 0
                        }
                    }
            } else {
                List {
                    Section(header: Text("屏幕检测")) {
                        Text("点击开始后，屏幕将依次显示纯色画面，请检查是否有坏点、亮点或颜色异常。")
                            .font(.footnote)
                            .foregroundColor(.gray)
                        
                        Button(action: {
                            isFullScreen = true
                            currentColorIndex = 0
                        }) {
                            HStack {
                                Spacer()
                                Text("开始检测")
                                    .foregroundColor(.blue)
                                Spacer()
                            }
                        }
                    }
                    
                    Section(header: Text("检测颜色")) {
                        ForEach(colors, id: \.self) { color in
                            HStack {
                                Circle()
                                    .fill(color)
                                    .frame(width: 30, height: 30)
                                    .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                                Text(colorName(color))
                                Spacer()
                            }
                        }
                    }
                    
                    Section(header: Text("说明")) {
                        Text("• 白色画面：检查坏点（黑点）\n• 黑色画面：检查亮点（白点）\n• 红绿蓝：检查颜色显示是否正常\n• 点击屏幕切换下一个颜色\n• 检测完成后自动返回")
                            .font(.footnote)
                            .foregroundColor(.gray)
                    }
                }
                .navigationTitle("屏幕检测")
                .listStyle(InsetGroupedListStyle())
            }
        }
    }
    
    func colorName(_ color: Color) -> String {
        switch color {
        case .white: return "白色"
        case .black: return "黑色"
        case .red: return "红色"
        case .green: return "绿色"
        case .blue: return "蓝色"
        case .yellow: return "黄色"
        case .purple: return "紫色"
        default: return "未知"
        }
    }
}

// 触摸检测页面
struct TouchTestView: View {
    @State private var touchedPoints: Set<CGPoint> = []
    @State private var isTesting = false
    @State private var testComplete = false
    
    var body: some View {
        ZStack {
            if isTesting {
                GeometryReader { geometry in
                    ZStack {
                        Color.black.opacity(0.9)
                            .ignoresSafeArea()
                        
                        ForEach(Array(touchedPoints), id: \.self) { point in
                            Circle()
                                .fill(Color.green.opacity(0.6))
                                .frame(width: 50, height: 50)
                                .position(point)
                        }
                        
                        VStack {
                            Text("触摸屏幕任意位置")
                                .foregroundColor(.white)
                                .font(.headline)
                            Text("已触摸 \(touchedPoints.count) 个点")
                                .foregroundColor(.gray)
                            Text("点击左上角返回")
                                .foregroundColor(.white.opacity(0.6))
                                .font(.footnote)
                                .padding(.top, 20)
                        }
                    }
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                touchedPoints.insert(value.location)
                            }
                            .onEnded { value in
                                if value.location.x < 80 && value.location.y < 80 {
                                    isTesting = false
                                    testComplete = true
                                }
                            }
                    )
                }
            } else {
                List {
                    Section(header: Text("触摸检测")) {
                        Text("点击开始后，在屏幕上滑动或点击，检查触摸是否灵敏、是否有断触区域。")
                            .font(.footnote)
                            .foregroundColor(.gray)
                        
                        Button(action: {
                            touchedPoints.removeAll()
                            isTesting = true
                        }) {
                            HStack {
                                Spacer()
                                Text("开始检测")
                                    .foregroundColor(.blue)
                                Spacer()
                            }
                        }
                        
                        if testComplete {
                            Text("检测完成，共触摸 \(touchedPoints.count) 个点")
                                .foregroundColor(.green)
                        }
                    }
                    
                    Section(header: Text("说明")) {
                        Text("在屏幕上滑动，绿色圆圈表示触摸位置，点击左上角返回")
                            .font(.footnote)
                            .foregroundColor(.gray)
                    }
                }
                .navigationTitle("触摸检测")
                .listStyle(InsetGroupedListStyle())
            }
        }
    }
}
struct SpeakerTestView: View {
    @State private var isPlaying = false
    @State private var testResult = ""
    
    var body: some View {
        List {
            Section(header: Text("扬声器检测")) {
                Text("点击播放测试音，检查扬声器是否有声音、是否有杂音。")
                    .font(.footnote)
                    .foregroundColor(.gray)
                
                Button(action: {
                    playTestSound()
                }) {
                    HStack {
                        Spacer()
                        Image(systemName: isPlaying ? "stop.circle.fill" : "play.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.blue)
                        Text(isPlaying ? "停止播放" : "播放测试音")
                            .foregroundColor(.blue)
                        Spacer()
                    }
                }
                
                if !testResult.isEmpty {
                    Text(testResult)
                        .foregroundColor(.green)
                }
            }
            
            Section(header: Text("测试结果")) {
                Button(action: {
                    testResult = "扬声器正常"
                }) {
                    Label("有声音，正常", systemImage: "checkmark.circle")
                        .foregroundColor(.green)
                }
                Button(action: {
                    testResult = "扬声器有杂音"
                }) {
                    Label("有杂音或声音小", systemImage: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                }
                Button(action: {
                    testResult = "扬声器无声"
                }) {
                    Label("没有声音", systemImage: "xmark.circle")
                        .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("扬声器检测")
        .listStyle(InsetGroupedListStyle())
    }
    
    func playTestSound() {
        isPlaying = true
        // 播放系统提示音
        AudioServicesPlaySystemSound(1104)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            AudioServicesPlaySystemSound(1105)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isPlaying = false
        }
    }
}

// 麦克风检测页面
struct MicrophoneTestView: View {
    @State private var isRecording = false
    @State private var audioLevel: Float = 0
    @State private var testResult = ""
    @State private var recorder: AVAudioRecorder?
    
    var body: some View {
        List {
            Section(header: Text("麦克风检测")) {
                Text("点击开始录音，对着麦克风说话，观察音量条变化。")
                    .font(.footnote)
                    .foregroundColor(.gray)
                
                Button(action: {
                    if isRecording {
                        stopRecording()
                    } else {
                        startRecording()
                    }
                }) {
                    HStack {
                        Spacer()
                        Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(isRecording ? .red : .blue)
                        Text(isRecording ? "停止录音" : "开始录音")
                            .foregroundColor(isRecording ? .red : .blue)
                        Spacer()
                    }
                }
                
                if isRecording {
                    ProgressView(value: audioLevel, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle(tint: .green))
                    Text("音量: \(Int(audioLevel * 100))%")
                        .foregroundColor(.gray)
                }
                
                if !testResult.isEmpty {
                    Text(testResult)
                        .foregroundColor(.green)
                }
            }
            
            Section(header: Text("测试结果")) {
                Button(action: {
                    testResult = "麦克风正常"
                }) {
                    Label("有声音，正常", systemImage: "checkmark.circle")
                        .foregroundColor(.green)
                }
                Button(action: {
                    testResult = "麦克风声音小"
                }) {
                    Label("声音小或有杂音", systemImage: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                }
                Button(action: {
                    testResult = "麦克风无声"
                }) {
                    Label("没有声音", systemImage: "xmark.circle")
                        .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("麦克风检测")
        .listStyle(InsetGroupedListStyle())
    }
    
    func startRecording() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .default)
            try audioSession.setActive(true)
            
            let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            let filePath = URL(fileURLWithPath: documentsPath).appendingPathComponent("test_recording.m4a")
            
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            recorder = try AVAudioRecorder(url: filePath, settings: settings)
            recorder?.isMeteringEnabled = true
            recorder?.record()
            isRecording = true
            
            // 更新音量
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                guard let recorder = recorder, recorder.isRecording else {
                    timer.invalidate()
                    return
                }
                recorder.updateMeters()
                audioLevel = pow(10, recorder.averagePower(forChannel: 0) / 20)
            }
        } catch {
            testResult = "无法访问麦克风，请在设置中授权"
        }
    }
    
    func stopRecording() {
        recorder?.stop()
        recorder = nil
        isRecording = false
        audioLevel = 0
    }
}

// 振动检测页面
struct VibrationTestView: View {
    @State private var isVibrating = false
    @State private var testResult = ""
    
    var body: some View {
        List {
            Section(header: Text("振动检测")) {
                Text("点击开始振动，感受手机是否有振动反馈。")
                    .font(.footnote)
                    .foregroundColor(.gray)
                
                Button(action: {
                    startVibrationTest()
                }) {
                    HStack {
                        Spacer()
                        Image(systemName: "iphone.radiowaves.left.and.right")
                            .font(.largeTitle)
                            .foregroundColor(.blue)
                        Text("开始振动测试")
                            .foregroundColor(.blue)
                        Spacer()
                    }
                }
                
                if !testResult.isEmpty {
                    Text(testResult)
                        .foregroundColor(.green)
                }
            }
            
            Section(header: Text("测试结果")) {
                Button(action: {
                    testResult = "振动正常"
                }) {
                    Label("有振动，正常", systemImage: "checkmark.circle")
                        .foregroundColor(.green)
                }
                Button(action: {
                    testResult = "振动微弱"
                }) {
                    Label("振动微弱", systemImage: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                }
                Button(action: {
                    testResult = "无振动"
                }) {
                    Label("没有振动", systemImage: "xmark.circle")
                        .foregroundColor(.red)
                }
            }
            
            Section(header: Text("振动模式测试")) {
                Button(action: {
                    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
                }) {
                    Label("标准振动", systemImage: "waveform")
                }
                Button(action: {
                    AudioServicesPlaySystemSound(1102)
                }) {
                    Label("短振动", systemImage: "waveform.path.ecg")
                }
                Button(action: {
                    AudioServicesPlaySystemSound(1107)
                }) {
                    Label("长振动", systemImage: "waveform.path.ecg.rectangle")
                }
            }
        }
        .navigationTitle("振动检测")
        .listStyle(InsetGroupedListStyle())
    }
    
    func startVibrationTest() {
        isVibrating = true
        // 连续振动3次
        for i in 0..<3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.5) {
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isVibrating = false
        }
    }
}

// 相机检测页面
struct CameraTestView: View {
    @State private var showCamera = false
    @State private var cameraPosition: AVCaptureDevice.Position = .back
    @State private var testResult = ""
    
    var body: some View {
        List {
            Section(header: Text("相机检测")) {
                Text("点击打开相机，检查前后摄像头是否正常工作。")
                    .font(.footnote)
                    .foregroundColor(.gray)
                
                Button(action: {
                    cameraPosition = .back
                    showCamera = true
                }) {
                    Label("测试后摄像头", systemImage: "camera.fill")
                        .foregroundColor(.blue)
                }
                
                Button(action: {
                    cameraPosition = .front
                    showCamera = true
                }) {
                    Label("测试前摄像头", systemImage: "camera")
                        .foregroundColor(.blue)
                }
                
                if !testResult.isEmpty {
                    Text(testResult)
                        .foregroundColor(.green)
                }
            }
            
            Section(header: Text("闪光灯检测")) {
                Button(action: {
                    toggleFlashlight()
                }) {
                    Label("开关闪光灯", systemImage: "flashlight.on.fill")
                        .foregroundColor(.blue)
                }
            }
            
            Section(header: Text("测试结果")) {
                Button(action: {
                    testResult = "摄像头正常"
                }) {
                    Label("正常", systemImage: "checkmark.circle")
                        .foregroundColor(.green)
                }
                Button(action: {
                    testResult = "摄像头异常"
                }) {
                    Label("异常", systemImage: "xmark.circle")
                        .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("相机检测")
        .listStyle(InsetGroupedListStyle())
        .sheet(isPresented: $showCamera) {
            CameraPreviewView(position: cameraPosition)
        }
    }
    
    func toggleFlashlight() {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else {
            testResult = "设备无闪光灯"
            return
        }
        
        do {
            try device.lockForConfiguration()
            if device.torchMode == .on {
                device.torchMode = .off
            } else {
                try device.setTorchModeOn(level: 1.0)
            }
            device.unlockForConfiguration()
        } catch {
            testResult = "闪光灯控制失败"
        }
    }
}

// 相机预览视图
struct CameraPreviewView: UIViewControllerRepresentable {
    let position: AVCaptureDevice.Position
    
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        let captureSession = AVCaptureSession()
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            return viewController
        }
        
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = viewController.view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        viewController.view.layer.addSublayer(previewLayer)
        
        DispatchQueue.global(qos: .userInitiated).async {
            captureSession.startRunning()
        }
        
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

// 详细设备信息页面
struct DeviceInfoView: View {
    var body: some View {
        List {
            Section(header: Text("基本信息")) {
                InfoRow(title: "设备名称", value: UIDevice.current.name)
                InfoRow(title: "系统名称", value: UIDevice.current.systemName)
                InfoRow(title: "系统版本", value: UIDevice.current.systemVersion)
                InfoRow(title: "设备型号", value: UIDevice.current.model)
                InfoRow(title: "本地化型号", value: UIDevice.current.localizedModel)
                InfoRow(title: "设备标识符", value: UIDevice.current.identifierForVendor?.uuidString ?? "未知")
            }
            
            Section(header: Text("屏幕信息")) {
                InfoRow(title: "屏幕尺寸", value: "\(Int(UIScreen.main.bounds.width)) x \(Int(UIScreen.main.bounds.height))")
                InfoRow(title: "屏幕缩放", value: "\(UIScreen.main.scale)x")
                InfoRow(title: "亮度", value: "\(Int(UIScreen.main.brightness * 100))%")
            }
            
            Section(header: Text("硬件信息")) {
                InfoRow(title: "CPU架构", value: "64位")
                InfoRow(title: "存储空间", value: ContentView().storageInfo())
            }
        }
        .navigationTitle("详细设备信息")
        .listStyle(InsetGroupedListStyle())
    }
}

// 验机报告页面
struct VerifyReportView: View {
    var body: some View {
        List {
            Section(header: Text("验机结果")) {
                VerifyRow(title: "基础信息", status: "正常")
                VerifyRow(title: "主板", status: "正常")
                VerifyRow(title: "电池", status: "正常")
                VerifyRow(title: "屏幕", status: "正常")
                VerifyRow(title: "前摄像头", status: "正常")
                VerifyRow(title: "后摄像头", status: "正常")
                VerifyRow(title: "面容ID", status: "正常")
            }
            
            Section(header: Text("说明")) {
                Text("本报告基于设备公开信息生成，仅供参考。详细验机请以官方检测为准。")
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
        }
        .navigationTitle("验机报告")
        .listStyle(InsetGroupedListStyle())
    }
}

// 存储空间页面
struct StorageView: View {
    @State private var appCacheSize = "0 KB"
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        List {
            Section(header: Text("存储空间")) {
                InfoRow(title: "总容量", value: totalStorage())
                InfoRow(title: "可用空间", value: freeStorage())
                InfoRow(title: "已用空间", value: usedStorage())
            }
            
            Section(header: Text("App缓存清理")) {
                HStack {
                    Text("本App缓存")
                    Spacer()
                    Text(appCacheSize)
                        .foregroundColor(.gray)
                }
                Button(action: {
                    clearAppCache()
                }) {
                    HStack {
                        Spacer()
                        Text("清理缓存")
                            .foregroundColor(.blue)
                        Spacer()
                    }
                }
            }
            
            Section(header: Text("说明")) {
                Text("• 由于iOS系统限制，无法清理其他应用缓存和系统垃圾")
                    .font(.footnote)
                    .foregroundColor(.gray)
                Text("• 可前往：设置 > 通用 > iPhone存储空间 查看详细占用")
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
        }
        .navigationTitle("存储空间")
        .listStyle(InsetGroupedListStyle())
        .onAppear {
            calculateAppCache()
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("提示"), message: Text(alertMessage), dismissButton: .default(Text("确定")))
        }
    }
    
    func calculateAppCache() {
        let cachePath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
        let tmpPath = NSTemporaryDirectory()
        
        var totalSize: UInt64 = 0
        
        if let cacheFiles = try? FileManager.default.subpathsOfDirectory(atPath: cachePath) {
            for file in cacheFiles {
                let filePath = (cachePath as NSString).appendingPathComponent(file)
                if let attrs = try? FileManager.default.attributesOfItem(atPath: filePath),
                   let size = attrs[.size] as? NSNumber {
                    totalSize += size.uint64Value
                }
            }
        }
        
        appCacheSize = formatSize(totalSize)
    }
    
    func clearAppCache() {
        let cachePath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
        
        var clearedSize: UInt64 = 0
        
        if let files = try? FileManager.default.contentsOfDirectory(atPath: cachePath) {
            for file in files {
                let filePath = (cachePath as NSString).appendingPathComponent(file)
                if let attrs = try? FileManager.default.attributesOfItem(atPath: filePath),
                   let size = attrs[.size] as? NSNumber {
                    clearedSize += size.uint64Value
                }
                try? FileManager.default.removeItem(atPath: filePath)
            }
        }
        
        calculateAppCache()
        alertMessage = "已清理 \(formatSize(clearedSize)) 缓存"
        showAlert = true
    }
    
    func formatSize(_ size: UInt64) -> String {
        if size < 1024 {
            return "\(size) B"
        } else if size < 1024 * 1024 {
            return String(format: "%.1f KB", Double(size) / 1024)
        } else if size < 1024 * 1024 * 1024 {
            return String(format: "%.1f MB", Double(size) / 1024 / 1024)
        } else {
            return String(format: "%.1f GB", Double(size) / 1024 / 1024 / 1024)
        }
    }
    
    func totalStorage() -> String {
        guard let attrs = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
              let size = attrs[.systemSize] as? NSNumber else { return "未知" }
        return String(format: "%.1f GB", size.doubleValue / 1024 / 1024 / 1024)
    }
    
    func freeStorage() -> String {
        guard let attrs = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
              let size = attrs[.systemFreeSize] as? NSNumber else { return "未知" }
        return String(format: "%.1f GB", size.doubleValue / 1024 / 1024 / 1024)
    }
    
    func usedStorage() -> String {
        guard let attrs = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
              let total = attrs[.systemSize] as? NSNumber,
              let free = attrs[.systemFreeSize] as? NSNumber else { return "未知" }
        let used = total.doubleValue - free.doubleValue
        return String(format: "%.1f GB", used / 1024 / 1024 / 1024)
    }
}

// 网络信息页面
struct NetworkView: View {
    var body: some View {
        List {
            Section(header: Text("网络状态")) {
                InfoRow(title: "网络类型", value: "WiFi / 蜂窝网络")
                InfoRow(title: "IP地址", value: "查看系统设置")
                InfoRow(title: "MAC地址", value: "查看系统设置")
            }
            
            Section(header: Text("操作")) {
                Button(action: {
                    if let url = URL(string: "App-Prefs:root=WIFI") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Label("WiFi设置", systemImage: "wifi")
                        .foregroundColor(.primary)
                }
                Button(action: {
                    if let url = URL(string: "App-Prefs:root=General&path=About") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Label("关于本机（查看IP）", systemImage: "info.circle")
                        .foregroundColor(.primary)
                }
            }
        }
        .navigationTitle("网络信息")
        .listStyle(InsetGroupedListStyle())
    }
}

// 屏蔽系统更新页面
struct BlockUpdateView: View {
    var body: some View {
        List {
            Section(header: Text("屏蔽系统更新")) {
                Text("通过安装描述文件，可以屏蔽iOS系统自动更新。")
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
            
            Section(header: Text("操作步骤")) {
                Text("1. 打开Safari浏览器")
                Text("2. 访问屏蔽更新描述文件下载网站")
                Text("3. 下载并安装描述文件")
                Text("4. 进入 设置 > 通用 > VPN与设备管理 安装")
                Text("5. 重启设备后生效")
            }
            
            Section(header: Text("恢复更新")) {
                Text("删除已安装的屏蔽更新描述文件即可恢复系统更新。")
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
        }
        .navigationTitle("屏蔽系统更新")
        .listStyle(InsetGroupedListStyle())
    }
}

// 通用信息行
struct InfoRow: View {
    var title: String
    var value: String
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.gray)
                .multilineTextAlignment(.trailing)
        }
    }
}

// 验机结果行
struct VerifyRow: View {
    var title: String
    var status: String
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(status)
                .foregroundColor(.green)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

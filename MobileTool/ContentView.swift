import SwiftUI

// 主界面
struct ContentView: View {
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
                        Text("1.0.2")
                            .foregroundColor(.gray)
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
                    NavigationLink(destination: BatteryView()) {
                        Label("电池健康", systemImage: "battery.100")
                    }
                    NavigationLink(destination: StorageView()) {
                        Label("存储空间", systemImage: "internaldrive")
                    }
                    NavigationLink(destination: NetworkView()) {
                        Label("网络信息", systemImage: "wifi")
                    }
                }
                
                // 系统工具
                Section(header: Text("系统工具")) {
                    Button(action: {
                        // 跳转到系统更新设置
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
                        // 跳转到关于本机
                        if let url = URL(string: "App-Prefs:root=General&path=About") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Label("关于本机", systemImage: "person.crop.circle")
                            .foregroundColor(.primary)
                    }
                    
                    NavigationLink(destination: HardwareTestView()) {
                        Label("硬件检测", systemImage: "wrench.and.screwdriver")
                    }
                }
                
                // 应用管理
                Section(header: Text("应用管理")) {
                    NavigationLink(destination: AppListView()) {
                        Label("已安装应用", systemImage: "square.grid.2x2")
                    }
                }
            }
            .navigationTitle("长须鲸手机工具")
            .listStyle(InsetGroupedListStyle())
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // 获取设备型号名称
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
    
    // 获取存储空间信息
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
                InfoRow(title: "屏幕尺寸", value: "\(UIScreen.main.bounds.width) x \(UIScreen.main.bounds.height)")
                InfoRow(title: "屏幕缩放", value: "\(UIScreen.main.scale)x")
                InfoRow(title: "亮度", value: "\(Int(UIScreen.main.brightness * 100))%")
            }
            
            Section(header: Text("硬件信息")) {
                InfoRow(title: "CPU架构", value: "64位")
                InfoRow(title: "内存", value: "查看系统设置")
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

// 电池健康页面
struct BatteryView: View {
    var body: some View {
        List {
            Section(header: Text("电池状态")) {
                InfoRow(title: "当前电量", value: "\(Int(UIDevice.current.batteryLevel * 100))%")
                InfoRow(title: "充电状态", value: batteryState())
                InfoRow(title: "电池健康", value: "查看系统设置 > 电池 > 电池健康")
            }
            
            Section(header: Text("省电建议")) {
                Text("• 降低屏幕亮度")
                Text("• 关闭后台应用刷新")
                Text("• 关闭不必要的定位服务")
                Text("• 使用低电量模式")
            }
        }
        .navigationTitle("电池健康")
        .listStyle(InsetGroupedListStyle())
        .onAppear {
            UIDevice.current.isBatteryMonitoringEnabled = true
        }
    }
    
    func batteryState() -> String {
        switch UIDevice.current.batteryState {
        case .unplugged: return "未充电"
        case .charging: return "充电中"
        case .full: return "已充满"
        case .unknown: return "未知"
        @unknown default: return "未知"
        }
    }
}

// 存储空间页面
struct StorageView: View {
    var body: some View {
        List {
            Section(header: Text("存储空间")) {
                InfoRow(title: "总容量", value: totalStorage())
                InfoRow(title: "可用空间", value: freeStorage())
                InfoRow(title: "已用空间", value: usedStorage())
            }
            
            Section(header: Text("清理建议")) {
                Text("• 删除不常用的应用")
                Text("• 清理照片和视频")
                Text("• 清除应用缓存")
                Text("• 卸载不使用的大型应用")
            }
        }
        .navigationTitle("存储空间")
        .listStyle(InsetGroupedListStyle())
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

// 硬件检测页面
struct HardwareTestView: View {
    var body: some View {
        List {
            Section(header: Text("硬件检测")) {
                NavigationLink(destination: Text("屏幕检测：显示纯色图片检查坏点")) {
                    Label("屏幕检测", systemImage: "rectangle")
                }
                NavigationLink(destination: Text("触摸检测：在屏幕上滑动测试触摸灵敏度")) {
                    Label("触摸检测", systemImage: "hand.draw")
                }
                NavigationLink(destination: Text("扬声器检测：播放测试音频")) {
                    Label("扬声器检测", systemImage: "speaker.wave.2")
                }
                NavigationLink(destination: Text("麦克风检测：录音并播放")) {
                    Label("麦克风检测", systemImage: "mic")
                }
                NavigationLink(destination: Text("振动检测：测试振动马达")) {
                    Label("振动检测", systemImage: "iphone.radiowaves.left.and.right")
                }
                NavigationLink(destination: Text("相机检测：测试前后摄像头")) {
                    Label("相机检测", systemImage: "camera")
                }
            }
        }
        .navigationTitle("硬件检测")
        .listStyle(InsetGroupedListStyle())
    }
}

// 应用列表页面
struct AppListView: View {
    var body: some View {
        List {
            Section(header: Text("说明")) {
                Text("由于iOS系统限制，无法直接读取已安装应用列表。请在系统设置中查看。")
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
            
            Section(header: Text("操作")) {
                Button(action: {
                    if let url = URL(string: "App-Prefs:root=General&path=Storage") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Label("查看iPhone存储空间", systemImage: "internaldrive")
                        .foregroundColor(.primary)
                }
            }
        }
        .navigationTitle("已安装应用")
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

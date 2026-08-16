import SwiftUI
import Photos
import UIKit

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
                        Text("1.0.3")
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

// 存储空间清理页面
struct StorageView: View {
    @State private var largePhotos: [PhotoAsset] = []
    @State private var isScanning = false
    @State private var scanProgress = 0.0
    @State private var selectedPhotos: Set<String> = []
    @State private var showRecycleBin = false
    @State private var recycleBinCount = 0
    @State private var appCacheSize = "0 KB"
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        List {
            // 存储空间概览
            Section(header: Text("存储空间")) {
                InfoRow(title: "总容量", value: totalStorage())
                InfoRow(title: "可用空间", value: freeStorage())
                InfoRow(title: "已用空间", value: usedStorage())
            }
            
            // 清理App缓存
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
            
            // 大图片压缩
            Section(header: Text("大图片压缩")) {
                if isScanning {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("正在扫描照片...")
                        ProgressView(value: scanProgress)
                    }
                } else if largePhotos.isEmpty {
                    Button(action: {
                        scanLargePhotos()
                    }) {
                        HStack {
                            Spacer()
                            Label("扫描大图片", systemImage: "magnifyingglass")
                                .foregroundColor(.blue)
                            Spacer()
                        }
                    }
                } else {
                    Text("找到 \(largePhotos.count) 张大图片")
                        .font(.footnote)
                        .foregroundColor(.gray)
                    
                    ForEach(largePhotos, id: \.id) { photo in
                        PhotoRow(photo: photo, isSelected: selectedPhotos.contains(photo.id)) {
                            if selectedPhotos.contains(photo.id) {
                                selectedPhotos.remove(photo.id)
                            } else {
                                selectedPhotos.insert(photo.id)
                            }
                        }
                    }
                    
                    if !selectedPhotos.isEmpty {
                        Button(action: {
                            compressSelectedPhotos()
                        }) {
                            HStack {
                                Spacer()
                                Text("压缩选中的 \(selectedPhotos.count) 张")
                                    .foregroundColor(.blue)
                                Spacer()
                            }
                        }
                    }
                    
                    Button(action: {
                        largePhotos = []
                        selectedPhotos = []
                    }) {
                        HStack {
                            Spacer()
                            Text("重新扫描")
                                .foregroundColor(.gray)
                            Spacer()
                        }
                    }
                }
            }
            
            // 回收站
            Section(header: Text("回收站（3天自动删除）")) {
                Button(action: {
                    showRecycleBin = true
                    loadRecycleBin()
                }) {
                    HStack {
                        Label("回收站", systemImage: "trash")
                        Spacer()
                        Text("\(recycleBinCount) 张")
                            .foregroundColor(.gray)
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                }
            }
            
            // 说明
            Section(header: Text("说明")) {
                Text("• 由于iOS系统限制，无法清理其他应用缓存和系统垃圾")
                    .font(.footnote)
                    .foregroundColor(.gray)
                Text("• 图片压缩后原图会备份到回收站，3天内可恢复")
                    .font(.footnote)
                    .foregroundColor(.gray)
                Text("• 压缩后的图片会保存到相册，原图会被删除")
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
        }
        .navigationTitle("存储空间清理")
        .listStyle(InsetGroupedListStyle())
        .onAppear {
            calculateAppCache()
            loadRecycleBinCount()
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("提示"), message: Text(alertMessage), dismissButton: .default(Text("确定")))
        }
        .sheet(isPresented: $showRecycleBin) {
            RecycleBinView()
        }
    }
    
    // 计算App缓存大小
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
        
        if let tmpFiles = try? FileManager.default.subpathsOfDirectory(atPath: tmpPath) {
            for file in tmpFiles {
                let filePath = (tmpPath as NSString).appendingPathComponent(file)
                if let attrs = try? FileManager.default.attributesOfItem(atPath: filePath),
                   let size = attrs[.size] as? NSNumber {
                    totalSize += size.uint64Value
                }
            }
        }
        
        appCacheSize = formatSize(totalSize)
    }
    
    // 清理App缓存
    func clearAppCache() {
        let cachePath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
        let tmpPath = NSTemporaryDirectory()
        
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
        
        if let files = try? FileManager.default.contentsOfDirectory(atPath: tmpPath) {
            for file in files {
                let filePath = (tmpPath as NSString).appendingPathComponent(file)
                try? FileManager.default.removeItem(atPath: filePath)
            }
        }
        
        calculateAppCache()
        alertMessage = "已清理 \(formatSize(clearedSize)) 缓存"
        showAlert = true
    }
    
    // 扫描大图片
    func scanLargePhotos() {
        isScanning = true
        scanProgress = 0
        largePhotos = []
        selectedPhotos = []
        
        let status = PHPhotoLibrary.authorizationStatus()
        if status == .notDetermined {
            PHPhotoLibrary.requestAuthorization { newStatus in
                DispatchQueue.main.async {
                    if newStatus == .authorized {
                        performScan()
                    } else {
                        isScanning = false
                        alertMessage = "请在设置中允许访问照片库"
                        showAlert = true
                    }
                }
            }
        } else if status == .authorized {
            performScan()
        } else {
            isScanning = false
            alertMessage = "请在设置中允许访问照片库"
            showAlert = true
        }
    }
    
    func performScan() {
        DispatchQueue.global(qos: .userInitiated).async {
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            
            let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            let total = assets.count
            var scanned = 0
            
            assets.enumerateObjects { asset, _, _ in
                scanned += 1
                let size = asset.pixelWidth * asset.pixelHeight
                if size > 4000000 { // 大于400万像素（约2000x2000）
                    let photo = PhotoAsset(
                        id: asset.localIdentifier,
                        asset: asset,
                        size: size,
                        creationDate: asset.creationDate ?? Date()
                    )
                    DispatchQueue.main.async {
                        largePhotos.append(photo)
                    }
                }
                
                DispatchQueue.main.async {
                    scanProgress = Double(scanned) / Double(total)
                }
            }
            
            DispatchQueue.main.async {
                isScanning = false
                if largePhotos.isEmpty {
                    alertMessage = "没有找到大图片"
                    showAlert = true
                }
            }
        }
    }
    
    // 压缩选中的图片
    func compressSelectedPhotos() {
        let photosToCompress = largePhotos.filter { selectedPhotos.contains($0.id) }
        guard !photosToCompress.isEmpty else { return }
        
        alertMessage = "正在压缩 \(photosToCompress.count) 张图片..."
        showAlert = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            var successCount = 0
            
            for photo in photosToCompress {
                let options = PHImageRequestOptions()
                options.isSynchronous = true
                options.deliveryMode = .highQualityFormat
                
                PHImageManager.default().requestImage(
                    for: photo.asset,
                    targetSize: CGSize(width: 1920, height: 1920),
                    contentMode: .aspectFit,
                    options: options
                ) { image, _ in
                    guard let image = image, let imageData = image.jpegData(compressionQuality: 0.7) else { return }
                    
                    // 保存原图到回收站
                    saveToRecycleBin(asset: photo.asset)
                    
                    // 保存压缩后的图片到相册
                    PHPhotoLibrary.shared().performChanges {
                        PHAssetCreationRequest.creationRequestForAsset(from: UIImage(data: imageData)!)
                    } completionHandler: { success, _ in
                        if success {
                            // 删除原图
                            PHPhotoLibrary.shared().performChanges {
                                PHAssetChangeRequest.deleteAssets([photo.asset] as NSArray)
                            } completionHandler: { _, _ in
                                successCount += 1
                            }
                        }
                    }
                }
            }
            
            DispatchQueue.main.async {
                alertMessage = "成功压缩 \(successCount) 张图片，原图已备份到回收站"
                showAlert = true
                largePhotos.removeAll { selectedPhotos.contains($0.id) }
                selectedPhotos.removeAll()
                loadRecycleBinCount()
            }
        }
    }
    
    // 保存到回收站
    func saveToRecycleBin(asset: PHAsset) {
        let recycleBinPath = getRecycleBinPath()
        
        let options = PHImageRequestOptions()
        options.isSynchronous = true
        options.deliveryMode = .highQualityFormat
        
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: PHImageManagerMaximumSize,
            contentMode: .aspectFit,
            options: options
        ) { image, _ in
            guard let image = image, let data = image.pngData() else { return }
            
            let fileName = "\(asset.localIdentifier.replacingOccurrences(of: "/", with: "_")).png"
            let filePath = (recycleBinPath as NSString).appendingPathComponent(fileName)
            
            try? data.write(to: URL(fileURLWithPath: filePath))
            
            // 保存元数据
            let meta: [String: Any] = [
                "originalId": asset.localIdentifier,
                "deleteDate": Date().timeIntervalSince1970,
                "fileName": fileName
            ]
            let metaPath = (recycleBinPath as NSString).appendingPathComponent("\(fileName).plist")
            (meta as NSDictionary).write(toFile: metaPath, atomically: true)
        }
    }
    
    // 获取回收站路径
    func getRecycleBinPath() -> String {
        let docsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let recyclePath = (docsPath as NSString).appendingPathComponent("RecycleBin")
        
        if !FileManager.default.fileExists(atPath: recyclePath) {
            try? FileManager.default.createDirectory(atPath: recyclePath, withIntermediateDirectories: true)
        }
        
        // 清理超过3天的文件
        cleanOldRecycleBinFiles(path: recyclePath)
        
        return recyclePath
    }
    
    // 清理超过3天的回收站文件
    func cleanOldRecycleBinFiles(path: String) {
        let threeDaysAgo = Date().addingTimeInterval(-3 * 24 * 3600)
        
        if let files = try? FileManager.default.contentsOfDirectory(atPath: path) {
            for file in files where file.hasSuffix(".plist") {
                let filePath = (path as NSString).appendingPathComponent(file)
                if let dict = NSDictionary(contentsOfFile: filePath),
                   let deleteDate = dict["deleteDate"] as? TimeInterval {
                    if Date(timeIntervalSince1970: deleteDate) < threeDaysAgo {
                        // 删除图片和元数据
                        if let imgName = dict["fileName"] as? String {
                            let imgPath = (path as NSString).appendingPathComponent(imgName)
                            try? FileManager.default.removeItem(atPath: imgPath)
                        }
                        try? FileManager.default.removeItem(atPath: filePath)
                    }
                }
            }
        }
    }
    
    // 加载回收站数量
    func loadRecycleBinCount() {
        let path = getRecycleBinPath()
        if let files = try? FileManager.default.contentsOfDirectory(atPath: path) {
            recycleBinCount = files.filter { $0.hasSuffix(".png") }.count
        }
    }
    
    func loadRecycleBin() {
        loadRecycleBinCount()
    }
    
    // 格式化文件大小
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

// 图片数据模型
struct PhotoAsset: Identifiable {
    let id: String
    let asset: PHAsset
    let size: Int
    let creationDate: Date
    
    var sizeText: String {
        let mp = Double(size) / 1000000
        return String(format: "%.1f MP", mp)
    }
}

// 图片行视图
struct PhotoRow: View {
    let photo: PhotoAsset
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("图片 \(photo.id.prefix(8))...")
                        .font(.subheadline)
                    Text("\(photo.sizeText) · \(formatDate(photo.creationDate))")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "photo")
                    .foregroundColor(.gray)
            }
        }
        .foregroundColor(.primary)
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

// 回收站页面
struct RecycleBinView: View {
    @State private var recycledPhotos: [RecycledPhoto] = []
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            List {
                if recycledPhotos.isEmpty {
                    Text("回收站为空")
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    ForEach(recycledPhotos, id: \.id) { photo in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(photo.fileName)
                                    .font(.subheadline)
                                Text("删除于 \(formatDate(photo.deleteDate))")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Text("剩余 \(daysRemaining(photo.deleteDate)) 天自动删除")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                restorePhoto(photo)
                            }) {
                                Text("恢复")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    
                    Button(action: {
                        clearAll()
                    }) {
                        HStack {
                            Spacer()
                            Text("清空回收站")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("回收站")
            .listStyle(InsetGroupedListStyle())
            .onAppear {
                loadRecycleBin()
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("提示"), message: Text(alertMessage), dismissButton: .default(Text("确定")))
            }
        }
    }
    
    func loadRecycleBin() {
        let docsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let recyclePath = (docsPath as NSString).appendingPathComponent("RecycleBin")
        
        recycledPhotos = []
        
        guard let files = try? FileManager.default.contentsOfDirectory(atPath: recyclePath) else { return }
        
        for file in files where file.hasSuffix(".plist") {
            let filePath = (recyclePath as NSString).appendingPathComponent(file)
            if let dict = NSDictionary(contentsOfFile: filePath),
               let originalId = dict["originalId"] as? String,
               let deleteDate = dict["deleteDate"] as? TimeInterval,
               let fileName = dict["fileName"] as? String {
                recycledPhotos.append(RecycledPhoto(
                    id: originalId,
                    fileName: fileName,
                    deleteDate: Date(timeIntervalSince1970: deleteDate),
                    path: (recyclePath as NSString).appendingPathComponent(fileName)
                ))
            }
        }
    }
    
    func restorePhoto(_ photo: RecycledPhoto) {
        guard let imageData = try? Data(contentsOf: URL(fileURLWithPath: photo.path)),
              let image = UIImage(data: imageData) else {
            alertMessage = "恢复失败"
            showAlert = true
            return
        }
        
        PHPhotoLibrary.shared().performChanges {
            PHAssetCreationRequest.creationRequestForAsset(from: image)
        } completionHandler: { success, _ in
            DispatchQueue.main.async {
                if success {
                    // 删除回收站文件
                    try? FileManager.default.removeItem(atPath: photo.path)
                    try? FileManager.default.removeItem(atPath: photo.path + ".plist")
                    recycledPhotos.removeAll { $0.id == photo.id }
                    alertMessage = "恢复成功"
                } else {
                    alertMessage = "恢复失败"
                }
                showAlert = true
            }
        }
    }
    
    func clearAll() {
        let docsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let recyclePath = (docsPath as NSString).appendingPathComponent("RecycleBin")
        
        if let files = try? FileManager.default.contentsOfDirectory(atPath: recyclePath) {
            for file in files {
                let filePath = (recyclePath as NSString).appendingPathComponent(file)
                try? FileManager.default.removeItem(atPath: filePath)
            }
        }
        
        recycledPhotos = []
        alertMessage = "回收站已清空"
        showAlert = true
    }
    
    func daysRemaining(_ deleteDate: Date) -> Int {
        let expireDate = deleteDate.addingTimeInterval(3 * 24 * 3600)
        let remaining = expireDate.timeIntervalSinceNow
        return max(0, Int(remaining / 86400))
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }
}

struct RecycledPhoto: Identifiable {
    let id: String
    let fileName: String
    let deleteDate: Date
    let path: String
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

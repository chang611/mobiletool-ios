import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            List {
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
                        Text(UIDevice.current.model)
                            .foregroundColor(.gray)
                    }
                    HStack {
                        Text("设备标识符")
                        Spacer()
                        Text(UIDevice.current.identifierForVendor?.uuidString ?? "未知")
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                    HStack {
                        Text("应用版本")
                        Spacer()
                        Text("1.0.1")
                            .foregroundColor(.gray)
                    }
                }
                
                Section(header: Text("功能")) {
                    NavigationLink(destination: Text("设备验机报告")) {
                        Label("设备验机", systemImage: "checkmark.shield")
                    }
                    NavigationLink(destination: Text("刷机工具")) {
                        Label("刷机工具", systemImage: "arrow.down.circle")
                    }
                    NavigationLink(destination: Text("硬件检测")) {
                        Label("硬件检测", systemImage: "wrench.and.screwdriver")
                    }
                    NavigationLink(destination: Text("应用管理")) {
                        Label("应用管理", systemImage: "square.grid.2x2")
                    }
                }
            }
            .navigationTitle("长须鲸手机工具")
            .listStyle(InsetGroupedListStyle())
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

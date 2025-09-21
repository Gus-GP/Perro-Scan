import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ClassificationViewModel()
    
    var body: some View {
        TabView {
            ScannerView()
                .environmentObject(viewModel)
                .tabItem {
                    Label("Scan", systemImage: "document.viewfinder.fill")
                }
            
            ResultsView()
                .environmentObject(viewModel)
                .tabItem {
                    Label("Results", systemImage: "list.number")
                }
            
            LibraryView()
                .tabItem {
                    Label("Library", systemImage: "books.vertical")
                }
        }
    }
}

#Preview {
    ContentView()
}

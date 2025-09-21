import SwiftUI

struct AppInfoView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // About
                    Group {
                        Text("About Perro Scan")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Perro Scan helps you identify dog breeds from photos using on-device machine learning. After you pick or take a photo, the app analyzes the image and shows the most likely breeds along with their probabilities.")
                            .foregroundColor(.secondary)
                    }

                    Divider()

                    // Privacy
                    Group {
                        Text("Your Privacy")
                            .font(.title3)
                            .fontWeight(.semibold)
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Photos stay on your device during analysis.", systemImage: "lock.fill")
                            Label("Perro Scan does not collect or transmit your images.", systemImage: "hand.raised.fill")
                            Label("Results are stored only in memory until you reset or close the app.", systemImage: "bolt.shield.fill")
                        }
                        Text("Sharing is optional: If you choose to share results or images using the app's Share options, your data will be shared only with the destinations you select (e.g., Messages, Photos, social apps). Perro Scan never uploads content on your behalf.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    .foregroundColor(.secondary)

                    Divider()

                    // Tips
                    Group {
                        Text("Photo Tips for Best Results")
                            .font(.title3)
                            .fontWeight(.semibold)
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Fill the frame with the dog; avoid distant shots.", systemImage: "camera.viewfinder")
                            Label("Good lighting: shoot in daylight or a well-lit room.", systemImage: "sun.max.fill")
                            Label("Keep the dog centered and in focus.", systemImage: "viewfinder")
                            Label("Avoid heavy filters, stickers, or obstructions.", systemImage: "sparkles")
                            Label("Try multiple angles: full body and clear face profile.", systemImage: "person.fill.viewfinder")
                            Label("One dog per photo works best.", systemImage: "1.circle.fill")
                        }
                        .foregroundColor(.secondary)
                    }

                    Divider()

                    // Feedback & Reviews
                    Group {
                        Text("Feedback & Reviews")
                            .font(.title3)
                            .fontWeight(.semibold)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your feedback helps improve the Perro Scan experience. Please consider leaving a review on the App Store.")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("About & Tips")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    AppInfoView()
}

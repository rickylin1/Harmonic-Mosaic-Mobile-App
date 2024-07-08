import SwiftUI

struct ContentView: View {
    
    @State private var mosaic: Mosaic?
    @State private var albumName: String = ""
    
    var body: some View {
        VStack {
            Text(mosaic?.albumName ?? "Mosaic Constructor")
                .bold()
                .font(.largeTitle)
                .padding(.bottom)
                

            if let mosaicUrl = mosaic?.mosaicUrl, let url = URL(string: mosaicUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipShape(Circle())
                    case .failure:
                        Image(systemName: "xmark.circle")
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            HStack {
                Image(systemName: "photo.on.rectangle.angled")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .padding()
                
                Text(mosaic?.mosaicUrl ?? "Create your own mosaic!")
                    .multilineTextAlignment(.center)
            }

            TextField("Enter album name", text: $albumName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button("Load Mosaic") {
                Task {
                    await loadMosaic()
                }
            }
            .padding()
        }
        .padding()
    }
    
    func loadMosaic() async {
        if mosaic != nil {
            // Reset the mosaic to default state
            mosaic = nil
            albumName = ""
        } else {
            // Load the mosaic as before
            do {
                mosaic = try await getMosaic(albumName: albumName)
            } catch MosaicError.invalidURL {
                print("Invalid URL")
            } catch MosaicError.invalidData {
                print("Invalid Data")
            } catch MosaicError.invalidResponse {
                print("Invalid Response")
            } catch {
                print("Unexpected error: \(error)")
            }
        }
    }
    
//    func getMosaic(albumName: String) async throws -> Mosaic {
//        let endpoint = "http://127.0.0.1:5000/AlbumCoverMosaic?albumName=\(albumName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
//        
//        guard let url = URL(string: endpoint) else {
//            throw MosaicError.invalidURL
//        }
//        
//        let (data, response) = try await URLSession.shared.data(from: url)
//        
//        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
//            throw MosaicError.invalidResponse
//        }
//        
//        do {
//            let decoder = JSONDecoder()
//            decoder.keyDecodingStrategy = .convertFromSnakeCase
//            return try decoder.decode(Mosaic.self, from: data)
//        } catch {
//            throw MosaicError.invalidData
//        }
//    }
    
    func getMosaic(albumName: String) async throws -> Mosaic {
        let endpoint = "http://127.0.0.1:5000/AlbumCoverMosaic"
        
        guard let url = URL(string: endpoint) else {
            throw MosaicError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let parameters: [String: Any] = ["albumName": albumName]
        request.httpBody = try? JSONSerialization.data(withJSONObject: parameters)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw MosaicError.invalidResponse
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(Mosaic.self, from: data)
        } catch {
            throw MosaicError.invalidData
        }
    }
    
    
}

struct Mosaic: Codable {
    let mosaicUrl: String
    let albumName: String
}

enum MosaicError: Error {
    case invalidURL
    case invalidResponse
    case invalidData
}

#Preview {
    ContentView()
}

import SwiftUI

struct ContentView: View {
    
    @State private var mosaic: Mosaic?
    @State private var albumName: String = ""
    @State private var artistName: String = ""
    @State private var red: Double = 0.0
    @State private var green: Double = 0.0
    @State private var blue: Double = 0.0
    @State private var selectedColorGroup: ColorGroup = .monochrome
    @State private var xTiles: Int = 200
    @State private var yTiles: Int = 200

    enum ColorGroup: String, CaseIterable, Identifiable {
        case analogous = "analogous"
        case complementary = "complementary"
        case triadic = "triadic"
        case monochrome = "monochrome"
        
        var id: String { self.rawValue }
    }

    
    var body: some View {
        VStack {
            Text(mosaic?.albumName ?? "Mosaic Constructor")
                .bold()
                .font(.largeTitle)
                .padding(.top)
                

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

//            HStack {
//                Image(systemName: "photo.on.rectangle.angled")
//                    .resizable()
//                    .scaledToFit()
//                    .frame(width: 50, height: 50)
//                    .padding()
//                
//                Text(mosaic?.mosaicUrl ?? "Create your own mosaic!")
//                    .multilineTextAlignment(.center)
//            }

            TextField("Enter album name", text: $albumName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()  
            TextField("Enter artist name", text: $artistName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            Text("Adjust RGB Colors")
                            .font(.headline)
                        
                        HStack {
                            Text("Red")
                            Slider(value: $red, in: 0...255, step: 1)
                            Text("\(Int(red))")
                        }
                        
                        HStack {
                            Text("Green")
                            Slider(value: $green, in: 0...255, step: 1)
                            Text("\(Int(green))")
                        }
                        
                        HStack {
                            Text("Blue")
                            Slider(value: $blue, in: 0...255, step: 1)
                            Text("\(Int(blue))")
                        }
                        
                        Color(red: red/255, green: green/255, blue: blue/255)
                            .frame(width: 50, height: 50)
                            .cornerRadius(10)
                            .padding()
            
            Picker("Color Group", selection: $selectedColorGroup) {
                           ForEach(ColorGroup.allCases) { group in
                               Text(group.rawValue).tag(group)
                           }
                       }
                       .pickerStyle(MenuPickerStyle())
                       .padding()
            HStack {
                            Text("xTiles")
                            Stepper(value: $xTiles, in: 1...500, step: 10) {
                                Text("\(xTiles)")
                            }
                        }
                        .padding()

                        HStack {
                            Text("yTiles")
                            Stepper(value: $yTiles, in: 1...500, step: 10) {
                                Text("\(yTiles)")
                            }
                        }
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
                mosaic = try await getMosaic(albumName: albumName, artist:artistName, red:red, green:green, blue:blue, colorGroup: selectedColorGroup.id,xTiles:xTiles, yTiles: yTiles)
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
    
    func getMosaic(albumName: String, artist: String, red: Double, green: Double, blue: Double , colorGroup: String, xTiles: Int, yTiles: Int) async throws -> Mosaic {
        let endpoint = "http://127.0.0.1:5000/AlbumCoverMosaic"
        
        guard let url = URL(string: endpoint) else {
            throw MosaicError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let parameters: [String: Any] = [
            "albumName": albumName,
            "artist": artist,
            "red": red,
            "green": green,
            "blue": blue,
            "colorGroup": colorGroup,
            "xTiles": xTiles,
            "yTiles": yTiles
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        
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
    var artist: String
    var red: Double
    var green: Double
    var blue: Double
    var colorGroup: String
    var xTiles: Int
    var yTiles: Int
}

enum MosaicError: Error {
    case invalidURL
    case invalidResponse
    case invalidData
}

#Preview {
    ContentView()
}

//
//  NadeView.swift
//  Popflash
//
//  Created by Seb Vidal on 11/02/2021.
//

import SwiftUI
import Kingfisher
import FirebaseFirestore
import AVKit

struct NadeView: View {
    
    @State var nade: Nade
    
    @State var rotation = 0.0
    
    @State var player = AVPlayer()
    @State var isPlaying = false
    @State var progress: Float = 0
    
    @State var showControls = false
    @State var fullscreen = false
    
    @State var selection = "Video"
    
    var body: some View {
        
        ZStack(alignment: .top) {
            
            VStack(spacing: 0) {
                
                Header(player: player)

                Image("dust2_radar")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: UIScreen.screenWidth,
                           height: selection == "Overview" ? UIScreen.screenWidth : UIScreen.screenWidth / 1.6)
                    .background(Color.black)
                    .animation(.easeInOut(duration: 0.2))
                    .opacity(selection == "Overview" ? 1 : 0)
                
                SegmentedControl(selection: $selection)
                    .animation(.easeInOut(duration: 0.2))
                
                ScrollView(axes: .vertical, showsIndicators: true) {
                    
                    Group {
                        
                        Details(nade: nade)
                            .frame(width: UIScreen.screenWidth)
                        
                        if !nade.compliments.isEmpty {
                            
                            Compliments(nade: $nade, player: $player)
                            
                        }
                        
                    }
                    .animation(.none)
                    
                }
                .animation(.easeInOut(duration: 0.2))
                
            }
            .edgesIgnoringSafeArea(.top)
            
            NadeContent(nade: nade,
                        player: player,
                        fullscreen: fullscreen,
                        contentSelection: selection)
            
            HStack {

                Spacer()
                
                CloseButton(player: player)
                    .padding([.trailing, .top])
                
            }
            
        }
        
    }
    
}

private struct Header: View {
    
    var player: AVPlayer
    
    var body: some View {
        
        ZStack(alignment: .top) {
            
            VideoPlayer(player: player)
                .frame(width: UIScreen.screenWidth,
                       alignment: .top)
            
            VisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
            
        }
        .frame(height: UIDevice.current.hasNotch ? 47 : 20)
        
    }
    
}

private struct CloseButton: View {
    
    @State var player: AVPlayer
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    var body: some View {
        
        Button {
            
            player.pause()
            presentationMode.wrappedValue.dismiss()
            
        } label: {
            
            ZStack {
                
                VisualEffectView(effect: UIBlurEffect(style: .systemThinMaterial))
                    .frame(width: 35, height: 35)
                
                Image(systemName: "multiply")
                    .font(.system(size: 20, weight: .semibold))
                
            }
            .cornerRadius(25)
            
        }
        .buttonStyle(PlainButtonStyle())
        
    }
    
}

private struct NadeContent: View {
    
    var nade: Nade
    var player: AVPlayer
    
    @State var fullscreen: Bool
    
    var contentSelection: String
    
    var body: some View {
        
        ZStack(alignment: .top) {
            
            VideoView(nade: nade, player: player, fullscreen: $fullscreen)
                .edgesIgnoringSafeArea(.all)
                .opacity(contentSelection == "Video" ? 1 : 0)
            
            KFImage(URL(string: nade.lineup))
                .resizable()
                .pinchToZoom()
                .frame(height: UIScreen.screenWidth / 1.6)
                .opacity(contentSelection == "Line-up" ? 1 : 0)
            
        }
        
    }
    
}

private struct VideoView: View {
    
    @State var nade: Nade
    @State var player: AVPlayer
    
    @State var rotation = 0.0
    @State var isPlaying = false
    @State var progress: Float = 0
    @State var showControls = false
    @Binding var fullscreen: Bool
    
    var body: some View {
        
        ZStack(alignment: fullscreen ? .center : .top) {
            
            Rectangle()
                .foregroundColor(.black)
                .edgesIgnoringSafeArea(.all)
                .opacity(fullscreen ? 1 : 0)
                .animation(.easeInOut(duration: 0.25))
            
            ZStack(alignment: .center) {
                
                VideoPlayer(player: player)
                    .onTapGesture {
                        
                        showControls.toggle()
                        
                    }
                    .onAppear() {
                        
                        player.replaceCurrentItem(with: AVPlayerItem(url: URL(string: nade.video)!))
                        
                        self.player.addPeriodicTimeObserver(forInterval: CMTimeMake(value: 1, timescale: 100), queue: .main) { (_) in
                            
                            self.progress = self.getSliderValue()
                            
                            if self.progress == 1.0 {
                                
                                self.isPlaying = false
                                
                            }
                        }
                        
                    }
                
                Rectangle()
                    .foregroundColor(.black)
                    .opacity(showControls ? 0.4 : 0)
                
                VideoControls(player: $player, isPlaying: self.$isPlaying, progress: self.$progress, fullscreen: self.$fullscreen)
                    .opacity(showControls ? 1 : 0)
                
            }
            .frame(width: fullscreen ? UIScreen.screenWidth * 1.777 : UIScreen.screenWidth,
                   height: fullscreen ? UIScreen.screenWidth : (UIScreen.screenWidth) / 1.6)
            .rotationEffect(.degrees(rotation))
            .offset(y: fullscreen ? 0 : UIDevice.current.hasNotch ? 47 : 20)
            .animation(.easeInOut(duration: 0.25))
            .onRotate { orientation in
                
                if orientation == .portrait {
                    
                    fullscreen = false
                    rotation = 0.0
                    
                } else if orientation == .landscapeLeft {
                    
                    fullscreen = true
                    rotation = 90.0
                    
                } else if orientation == .landscapeRight {
                    
                    fullscreen = true
                    rotation = -90.0
                    
                }
                
            }
            
        }
        
    }
    
    func getSliderValue() -> Float{
        
        return Float(self.player.currentTime().seconds / (self.player.currentItem?.duration.seconds)!)
    }
    
    func getSeconds() -> Double{
        
        return Double(Double(self.progress) * (self.player.currentItem?.duration.seconds)!)
    }
    
}

struct SegmentedControl: View {
    
    @Binding var selection: String
    
    var options = ["Video", "Line-up", "Overview"]
    
    var body: some View {
        
        Picker("Video or Lineup", selection: $selection) {
            
            ForEach(options, id: \.self) {
                
                Text($0)
                
            }
            
        }
        .pickerStyle(SegmentedPickerStyle())
        .frame(width: UIScreen.screenWidth - 28)
        .padding(.top, 16)
        .padding(.bottom, 14)
        
    }
    
}

private struct Details: View {
    
    var nade: Nade
    
    var body: some View {
        
        VStack(alignment: .leading) {
            
            HStack {
                
                VStack(alignment: .leading) {
                    
                    Text(nade.map)
                        .foregroundColor(.gray)
                        .fontWeight(.semibold)
                        .padding(.top, -12)
                        .padding(.horizontal)
                    
                    Text(nade.name)
                        .font(.system(size: 22))
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    Text(nade.shortDescription)
                        .padding(.top, 4)
                        .padding(.horizontal)
                    
                }
                
                Spacer()
                
                FavouriteButton(id: nade.id)
                    .padding()
                    .padding(.bottom, 8)
                
            }
            
            VideoInfo(nade: nade)
                .padding(.top, -8)
            
            if !nade.warning.isEmpty {
                
                Warning(warning: nade.warning)
                
            }
            
            Text(nade.longDescription.replacingOccurrences(of: "\\n", with: "\n"))
                .padding(.horizontal)
            
        }
        
    }
    
    func videoDetails(nade: Nade) -> [Detail] {
        
        let details = [Detail(name: "VIEWS", value: "\(nade.views)", image: Image(systemName: "eye.fill")),
                       Detail(name: "FAVOURITES", value: "\(nade.favourites)", image: Image(systemName: "heart.fill")),
                       Detail(name: "TICK RATE", value: nade.tick, image: Image(systemName: "clock.fill")),
                       Detail(name: "JUMP BIND", value: nade.bind, image: Image("keyboard.fill")),
                       Detail(name: "SIDE", value: nade.side, image: Image("\(nade.side.lowercased()).fill")),
                       Detail(name: "TYPE", value: nade.type, image: Image(systemName: "circle.fill"))]
        
        return details
        
    }
    
}

private struct FavouriteButton: View {
    
    var id: String
    
    @AppStorage("favourites.nades") var favouriteNades: Array = [String()]
    
    var body: some View {
        
        ZStack {
            
            VisualEffectView(effect: UIBlurEffect(style: .systemThinMaterial))
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            
            Button {
                
                if favouriteNades.contains(id) {
                    
                    if let index = favouriteNades.firstIndex(of: id) {
                        
                        favouriteNades.remove(at: index)
                    }
                    
                } else {
                    
                    favouriteNades.append(id)
                    
                }
                
            } label: {
                
                if favouriteNades.contains(id) {
                    
                    Image(systemName: "heart.fill")
                        .font(.system(size: 21))
                        .foregroundColor(Color("Heart"))
                    
                } else {
                    
                    Image(systemName: "heart")
                        .font(.system(size: 21))
                    
                }
                
            }
            .offset(y: 0.5)
            
        }
        
    }
    
}

struct VideoInfo: View {
    
    var nade: Nade

    var body: some View {
    
        ScrollView(axes: .horizontal, showsIndicators: false) {
        
            VStack {
            
                Divider()
                    .padding(.horizontal)
                    
                HStack {
                    
                    Spacer()
                        .frame(width: 24)
                
                    ForEach(videoDetails(detailsOf: nade), id: \.self) { detail in
                    
                        ZStack {
                            
                            detail.image
                                .foregroundColor(Color("Detail_Icon"))
                                .frame(width: 80)
                        
                            VStack {
                    
                                Text(detail.name)
                                    .font(.system(size: 11))
                                    .fontWeight(.semibold)
                                
                                Spacer()
                                    .frame(height: 36)
                                
                                Text(detail.value)
                                    .font(.system(size: 12))
                                    .fontWeight(.semibold)
                                    
                            }
                        
                        }
                        .padding(.vertical, 2)
                        .padding(.horizontal, 4)
                        .foregroundColor(Color("Detail_Name"))
                        
                        if detail != videoDetails(detailsOf: nade).last {

                            Divider()
                                .frame(height: 40)

                        }
                    
                    }
                    
                    Spacer()
                        .frame(width: 24)
                
                }
                
                Divider()
                    .padding(.horizontal)

            
            }
        
        }
    
    }
    
    func videoDetails(detailsOf: Nade) -> [Detail] {
        
        let nade = detailsOf
        
        let details = [Detail(name: "VIEWS", value: "\(nade.views)", image: Image(systemName: "eye.fill")),
                       Detail(name: "FAVOURITES", value: "\(nade.favourites)", image: Image(systemName: "heart.fill")),
                       Detail(name: "TICK RATE", value: nade.tick, image: Image(systemName: "clock.fill")),
                       Detail(name: "JUMP BIND", value: nade.bind, image: Image("keyboard.fill")),
                       Detail(name: "SIDE", value: nade.side, image: Image("\(nade.side.lowercased()).fill")),
                       Detail(name: "TYPE", value: nade.type, image: Image(systemName: "circle.fill"))]
        
        return details
        
    }

}

private struct Warning: View {
    
    var warning: String
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 0) {
            
            HStack {
                
                ZStack {
                    
                    Image(systemName: "triangle.fill")
                        .foregroundColor(.black)
                        .font(.system(size: 20))
                    
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.yellow)
                        .font(.system(size: 24))
                    
                }
                .padding(.leading, 4)
                .padding(.trailing, 4)
                
                Text("\(warning)")
                
            }
            
            Divider()
                .padding(.top, 8)
            
        }
        .padding(.horizontal)
        
    }
    
}

private struct Compliments: View {
    
    @StateObject private var complimentsViewModel = NadesViewModel()
    
    @Binding var nade: Nade
    @Binding var player: AVPlayer
    
    let processor = CroppingImageProcessor(size: CGSize(width: 1284, height: 1), anchor: CGPoint(x: 0.5, y: 1.0))
    
    var body: some View {
        
        ScrollView(axes: .horizontal, showsIndicators: false) {
            
            VStack(alignment: .leading) {
                
                Divider()
                    .frame(minWidth: UIScreen.screenWidth - 32)
                    .padding(.horizontal)
                    .padding(.bottom, 4)
                    .onAppear() {
                        
                        print(nade.compliments)
                        
                        self.complimentsViewModel.fetchData(ref: Firestore.firestore().collection("nades")
                                                                    .whereField("id", in: nade.compliments))
                        
                    }
                
                Text("Use With")
                    .font(.system(size: 20))
                    .fontWeight(.semibold)
                    .padding(.leading, 18)
                
                HStack {
                    
                    Spacer()
                        .frame(width: 16)
                    
                    ForEach(complimentsViewModel.nades, id: \.self) { comp in
                        
                        Button {
                            
                            nade = comp
                            player.replaceCurrentItem(with: AVPlayerItem(url: URL(string: comp.video)!))
                            
                        } label: {
                            
                            ComplimentCell(nade: comp)
                                .padding(.bottom, 18)
                            
                        }
                        .buttonStyle(ComplimentsCellButtonStyle())
                        
                    }
                    
                    Spacer()
                        .frame(width: 8)
                    
                }
                
            }
            
        }
        .frame(width: UIScreen.screenWidth)
        
    }
    
}

private struct VideoPlayer: UIViewControllerRepresentable {
    
    var player: AVPlayer
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<VideoPlayer>) -> AVPlayerViewController {
        
        let controller = AVPlayerViewController()
        
        controller.player = player
        controller.showsPlaybackControls = false
        controller.videoGravity = .resizeAspectFill
        
        return controller
        
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: UIViewControllerRepresentableContext<VideoPlayer>) { }
    
}

private struct VideoControls: View {
    
    @Binding var player: AVPlayer
    @Binding var isPlaying: Bool
    @Binding var progress: Float
    @Binding var fullscreen: Bool
    
    var body: some View {
        
        ZStack {
            
            VStack {
                
                HStack {
                    
                    Spacer()
                    
                    Button {
                        
                        player.seek(to: CMTime(seconds: 0, preferredTimescale: 1))
                        
                    } label: {
                        
                        Image(systemName: "backward.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 26))
                        
                    }
                    
                    Spacer()
                    
                    Button {
                        
                        if !isPlaying {
                            
                            if progress == 1 {
                                
                                player.seek(to: CMTime(seconds: 0, preferredTimescale: 1))
                                
                            }
                            
                            player.play()
                            isPlaying = true
                            
                        } else {
                            
                            player.pause()
                            isPlaying = false
                            
                        }
                        
                    } label: {
                        
                        if progress == 1 {
                            
                            Image(systemName: "gobackward")
                                .foregroundColor(.white)
                                .font(.system(size: 36, weight: .bold))
                            
                        } else {
                            
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 42))
                            
                        }
                        
                    }
                    .frame(width: 45)
                    
                    Spacer()
                    
                    Button {
                        
                        player.seek(to: player.currentItem!.duration)
                        
                    } label: {
                        
                        Image(systemName: "forward.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 26))
                        
                    }
                    
                    Spacer()
                    
                }
                
            }
            
            VStack {
                
                Spacer()
                
                ProgressBar(value: $progress, player: $player, isplaying: $isPlaying)
                    .padding(.horizontal, fullscreen ? 34 : 20)
                    .padding(.bottom, fullscreen ? 26: 16)
                
            }
            
        }
        
    }
    
}

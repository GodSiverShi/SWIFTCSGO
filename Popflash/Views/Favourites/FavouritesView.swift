//
//  FavouritesView.swift
//  Popflash
//
//  Created by Seb Vidal on 13/02/2021.
//

import SwiftUI
import Kingfisher
import FirebaseFirestore

struct FavouritesView: View {
    
    @State var statusOpacitiy = 0.0
    
    @AppStorage("favourites.nades") var favouriteNades: Array = [String]()
    
    var statusBarBlur: some View {
        
        VisualEffectView(effect: UIBlurEffect(style: .systemThinMaterial))
            .frame(height: 47)
            .edgesIgnoringSafeArea(.top)
        
    }
    
    var body: some View {
        
        NavigationView {
            
            ZStack {
                
                ScrollView {
                    
                    Header()
                    
                    ScrollView(axes: .horizontal,
                               showsIndicators: false,
                               offsetChanged: {
                                
                                let offset = $0.y
                                
                                statusOpacitiy = Double((1 / 35) * -offset)
                                
                               }) {
                        
                        FavouriteMaps()
                        
                    }
                    .padding(.top, -6)
                    
                    FavouriteNades()
                        .padding(.horizontal)
                    
                }
                .onAppear {
                    standard.set(2, forKey: "tabSelection")
                    
                }
                .navigationBarTitle("Favourites", displayMode: .inline)
                .navigationBarHidden(true)
                
                statusBarBlur
                    .opacity(0.0)
                
            }
            
        }
        
    }
    
}

private struct FavouriteMaps: View {
    
    @ObservedObject var mapsViewModel = MapsViewModel()
    
    @State private var showingFavouriteMapsEdittingView = false
    
    @AppStorage("tabSelection") var tabSelection: Int = 0
    @AppStorage("favourites.maps") private var favouriteMaps: Array = [String]()
    
    var body: some View {
        
        VStack(alignment: .leading) {
            
            Divider()
                .frame(minWidth: UIScreen.screenWidth - 32)
                .padding(.horizontal)
                .padding(.bottom, 4)
            
            Text("Maps")
                .font(.system(size: 20))
                .fontWeight(.semibold)
                .padding(.leading, 18)
            
            HStack {
                
                Spacer()
                    .frame(width: 8)
                
                if mapsViewModel.maps.isEmpty {
                    
                    ForEach(favouriteMaps.filter({ $0 != "" }), id: \.self) { _ in
                        
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .frame(width: 100, height: 150)
                            .foregroundColor(Color("Loading"))
                            .padding([.leading, .bottom], 16)
                            .padding(.trailing, -8)
                        
                    }
                    
                } else {
                    
                    ForEach(favouriteMaps.filter({ $0 != "" }), id: \.self) { favouriteMap in
                        
                        let map = mapsViewModel.maps.first(where: { $0.name == favouriteMap })!
                        
                        NavigationLink(destination: MapsDetailView(map: map)) {
                            
                            FavouriteMapCell(map: map)
                                .contentShape(Rectangle())
                            
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                    }
                    
                }
                
                Button {
                    
                    showingFavouriteMapsEdittingView.toggle()
                    
                } label: {
                    
                    ZStack {
                        
                        Rectangle()
                            .frame(width: 100, height: 150)
                            .foregroundColor(Color("Favourite_Map_Background"))
                        
                        Circle()
                            .frame(width: 50, height: 50)
                            .foregroundColor(Color("Favourite_Map_Button"))
                        
                        Image(systemName: "plus")
                            .foregroundColor(.blue)
                            .font(.system(size: 24))
                        
                    }
                    .cornerRadius(10)
                    .shadow(radius: 4, y: 3)
                    .padding(.leading, 12)
                    .padding(.bottom, 16)
                    .padding(.trailing, -8)
                    
                }
                
                Spacer()
                    .frame(width: 24)
                
            }
            .buttonStyle(PlainButtonStyle())
            
            Divider()
                .frame(minWidth: UIScreen.screenWidth - 32)
                .padding(.top, -8)
                .padding(.horizontal)
            
            
            
        }
        .onAppear() {
            
            tabSelection = 2
            
            self.mapsViewModel.fetchData(ref: Firestore.firestore().collection("maps"))
            
        }
        .sheet(isPresented: $showingFavouriteMapsEdittingView, content: {
            
            EditFavouriteMapsView()
            
        })
        
    }
    
}


private struct FavouriteMapCell: View {
    
    var map: Map
    
    var body: some View {
        
        ZStack(alignment: .center) {
            
            KFImage(URL(string: map.background))
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 100, height: 150)
            
            KFImage(URL(string: map.icon))
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 65)
                .shadow(radius: 10)
                .shadow(radius: 10)
                .shadow(radius: 10)
            
        }
        .cornerRadius(10)
        .shadow(radius: 5, y: 4)
        .padding(.leading, 8)
        .padding(.bottom, 16)
        
    }
    
}

private struct FavouriteNades: View {
    
    @StateObject var favouritesViewModel = NadesViewModel()
    
    @AppStorage("favourites.nades") var favouriteNades = [String]()
    
    @State var selectedNade: Nade?
    @State var nadeViewIsPresented = false
    
    var body: some View {
        
        VStack {
            
            HStack {
                
                Text("Grenades")
                    .font(.system(size: 20))
                    .fontWeight(.semibold)
                    .padding(.top, -4)
                    .padding(.leading, 2)
                
                Spacer()
                
            }
            
            ForEach(favouritesViewModel.nades, id: \.self) { nade in
                
                Button {
                    
                    self.selectedNade = nade
                    nadeViewIsPresented.toggle()
                    
                } label: {
                    
                    FavouriteNadeCell(nade: nade)
                        .clipShape(
                            
                            RoundedRectangle(cornerRadius: 15, style: .continuous)
                            
                        )
                        .shadow(radius: 5, y: 4)
                        .padding(.bottom, 8)
                    
                }
                .buttonStyle(PlainButtonStyle())
                .fullScreenCover(item: self.$selectedNade) { item in
                    
                    NadeView(nade: item)
                    
                }
                
            }
            
        }
        .onAppear() {
            
            self.favouritesViewModel.fetchData(ref: Firestore.firestore().collection("nades").whereField("id", in: favouriteNades))
            
        }
        
    }
    
}

private struct FavouriteNadeCell: View {
    
    var nade: Nade
    
    var body: some View {
        
        ZStack(alignment: .leading) {
            
            Rectangle()
                .foregroundColor(Color("Background"))
                .frame(height: 106)
            
            HStack(alignment: .top) {
                
                KFImage(URL(string: nade.thumbnail))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 166, height: 106)
                    .clipped()
                
                VStack(alignment: .leading) {
                    
                    Text(nade.map)
                        .foregroundColor(.gray)
                        .font(.system(size: 14))
                        .fontWeight(.semibold)
                        .padding(.top, 8)
                        .padding(.leading, 4)
                    
                    Text(nade.name)
                        .fontWeight(.semibold)
                        .padding(.top, 0)
                        .padding(.leading, 4)
                        .lineLimit(2)
                    
                    Spacer()
                    
                    HStack {
                        
                        Image(systemName: "eye.fill")
                            .font(.system(size: 10))
                        
                        Text(String(nade.views))
                            .font(.system(size: 12))
                        
                        Image(systemName: "heart.fill")
                            .font(.system(size: 12))
                        
                        Text(String(nade.favourites))
                            .font(.system(size: 12))
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .padding(.trailing, 12)
                        
                    }
                    .padding(.leading, 6)
                    .padding(.bottom, 10)
                    
                }
                
            }
            
        }
        
    }
    
}

private struct Header: View {
    var body: some View {
        VStack {
            Spacer()
                .frame(height: 48)
            
            HStack {
                Text("Favourites")
                    .font(.system(size: 32))
                    .fontWeight(.bold)
                    .padding(.leading)
                Spacer()
            }
        }
    }
}

struct FavouritesView_Previews: PreviewProvider {
    static var previews: some View {
        FavouritesView()
    }
}

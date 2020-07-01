//
//  ContentView.swift
//  Instafilter
//
//  Created by Dathan Wong on 6/29/20.
//  Copyright © 2020 Dathan Wong. All rights reserved.
//

import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

struct ContentView: View {
    
    @State private var image: Image?
    @State private var filterIntensity = 0.5
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    @State private var showingFilterSheet = false
    @State private var processedImage: UIImage?
    @State private var imageText = "Tap to select a picture"
    @State private var errorText = false
    @State private var navTitle = "InstaFilter"
    
    @State private var currentFilter: CIFilter = CIFilter.sepiaTone()
    let context = CIContext()
    
    var body: some View {
        let intensity = Binding<Double> (
            get: {
                self.filterIntensity
        },
            set: {
                self.filterIntensity = $0
                self.applyProcessing()
        }
        )
        
        return NavigationView{
            VStack{
                ZStack{
                    Rectangle()
                        .fill(Color.secondary)
                    if self.image != nil{
                        self.image?
                            .resizable()
                            .scaledToFit()
                    }else{
                        Text("\(self.imageText)")
                            .foregroundColor(self.errorText ? .red : .white)
                            .font(.headline)
                    }
                }.onTapGesture {
                    self.showingImagePicker = true
                }
                HStack{
                    Text("Intensity")
                    Slider(value: intensity)
                }
                .padding()
                HStack{
                    Button("Change Filter"){
                        self.showingFilterSheet = true
                    }
                    
                    Spacer()
                    Button("Save"){
                        if(self.image == nil){
                            self.imageText = "Please select a photo before saving"
                            self.errorText = true
                            return
                        }
                        self.errorText = false
                        self.imageText = "Tap to select a picture"
                        guard let processedImage = self.processedImage else{
                            return
                        }
                        let imageSaver = ImageSaver()
                        imageSaver.successHandler = {
                            print("Success!")
                        }
                        imageSaver.errorHandler = {
                            print("Failed to save photo: \($0.localizedDescription)")
                        }
                        imageSaver.writeToPhotoAlbum(image: processedImage)
                        
                    }
                }
                .padding()
            }.navigationBarTitle("\(self.navTitle)")
            .sheet(isPresented: $showingImagePicker, onDismiss: loadImage) {
                ImagePicker(image: self.$inputImage)
                        
            }
            .actionSheet(isPresented: self.$showingFilterSheet) {
                    ActionSheet(title: Text("Select a filter"), message: Text("Select filter"), buttons: [
                        .default(Text("Edges")){
                            self.navTitle = "Edges"
                            self.setFilter(CIFilter.edges())
                        },
                        .default(Text("Gaussian Blur")){
                            self.navTitle = "Gaussian Blur"
                            self.setFilter(CIFilter.gaussianBlur())
                        },
                        .default(Text("Pixellate")){
                            self.navTitle = "Pixellate"
                            self.setFilter(CIFilter.pixellate())
                        },
                        .default(Text("Sepia Tone")){
                            self.navTitle = "Sepia Tone"
                            self.setFilter(CIFilter.sepiaTone())
                        },
                        .cancel()
                    ])
            }
        }
        
    }
    
    func loadImage(){
        guard let inputImage = inputImage else{
            return
        }
        let beginImage = CIImage(image: inputImage)
        currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
        applyProcessing()
    }
    
    func applyProcessing(){
        let inputKeys = currentFilter.inputKeys
        if inputKeys.contains(kCIInputIntensityKey){
            currentFilter.setValue(filterIntensity, forKey: kCIInputIntensityKey)
        }
        if inputKeys.contains(kCIInputRadiusKey){
            currentFilter.setValue(filterIntensity*200, forKey: kCIInputRadiusKey)
        }
        if inputKeys.contains(kCIInputScaleKey){
            currentFilter.setValue(filterIntensity*10, forKey: kCIInputScaleKey)
        }
        if inputKeys.contains(kCIInputWidthKey){
            currentFilter.setValue(filterIntensity, forKey: kCIInputWidthKey)
        }
        guard let outputImage = currentFilter.outputImage else{
            return
        }
        if let cgimg = context.createCGImage(outputImage, from: outputImage.extent){
            let uiImage = UIImage(cgImage: cgimg)
            image = Image(uiImage: uiImage)
            processedImage = uiImage
        }
    }
    
    func setFilter(_ filter: CIFilter){
        currentFilter = filter
        loadImage()
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

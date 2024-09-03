//
//  GenerationView.swift
//  ExampleCode
//
//  Created by Atay Sultangaziev on 3/9/24.
//

import Lottie
import SwiftUI

struct GenerationView: View {
    @ObservedObject private var viewModel: GenerationViewModel
    
    private var isGenerationButtonDisable: Bool {
        viewModel.textRequest.isEmpty
    }
    
    init(_ viewModel: GenerationViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                NavigationLink(
                    destination: SceneFactory.createAudioResultView(viewModel.generatedAudio),
                    isActive: $viewModel.isGenerationReady) {
                        EmptyView()
                    }
                Image("main.background")
                    .resizable()
                    .ignoresSafeArea()
                VStack {
                    ScrollView(.vertical) {
                        TextField("", text: $viewModel.textRequest)
                            .padding(.leading)
                            .frame(height: 44)
                            .foregroundColor(.white)
                            .font(.jostRegular(17))
                            .background(Color.itemViewBackground)
                            .cornerRadius(10)
                            .multilineTextAlignment(.leading)
                            .addGradientBorder(viewModel.isTextRequestEmpty ? .error : .gray, cornerRadius: 10)
                            .padding(.horizontal, 16)
                            .placeholder(when: viewModel.textRequest.isEmpty) {
                                Text("enterRequest".localized)
                                    .foregroundColor(viewModel.isTextRequestEmpty ? Color.emptyRequest : .white)
                                    .font(.jostRegular(17))
                                    .padding(.leading, 32)
                            }
                            .onTapGesture {
                                viewModel.isTextRequestEmpty = false
                            }
                        //                    .background(Color.red)
                        if viewModel.selectedGenre != .noGenre {
                            PromptsView(viewModel: viewModel)
                        }
//                                                .background(Color.green)
                        CategoryView(viewModel: viewModel, items: Genre.allCases)
                        //                    .padding(.bottom)
//                                            .background(Color.blue)
                        CategoryView(viewModel: viewModel, items: Mood.allCases)
//                                            .background(Color.blue)
                        CategoryView(viewModel: viewModel, items: Duration.allCases)
//                                            .background(Color.blue)
                    }
                    Button {
                        viewModel.generatePressed()
                    } label: {
                        Text("generate".localized)
                            .frame(width: 311, height: 44)
                            .font(.jostExtraBold(17))
                            .background(
                                ZStack {
                                    LinearGradient(
                                        colors: isGenerationButtonDisable ? Color.inactiveButtonColors : Color.accentColors,
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                    if !isGenerationButtonDisable {
                                        LinearGradient(
                                            colors: Color.subscribeButonOverlay,
                                            startPoint: .top,
                                            endPoint: .center
                                        )
                                    }
                                }
                            )
                            .foregroundColor(isGenerationButtonDisable ? .inactiveButtonFontColor : .black)
                            .cornerRadius(16)
                    }
                    .addGradientBorder(
                        Color.generateButtonBorder,
                        width: isGenerationButtonDisable ? 0 : 1,
                        cornerRadius: 16,
                        startPoint: .top, endPoint: .bottom)
                    .shadow(color: isGenerationButtonDisable ? Color.clear : Color.accentShadow,
                            radius: 8, x: /*@START_MENU_TOKEN@*/0.0/*@END_MENU_TOKEN@*/, y: 3)
                    .padding(.bottom, 75)
                }
                .padding(.top)
                .ignoresSafeArea(.keyboard)
                .onTapGesture {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil, from: nil, for: nil
                    )
                }
            }
            .navigationBarItems(
                leading: PremiumButton(),
                trailing: FreeAttemptsLabel()
            )
            .navigationBarHidden(viewModel.isFullVersion)
        }
        .navigationViewStyle(.stack)
    }
}

// MARK: - Preview

struct GenerationView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = GenerationViewModel()
        return GenerationView(viewModel)
    }
}

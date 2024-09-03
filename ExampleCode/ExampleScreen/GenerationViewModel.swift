//
//  GenerationViewModel.swift
//  ExampleCode
//
//  Created by Atay Sultangaziev on 3/9/24.
//

import Combine
import Foundation

final class GenerationViewModel: ObservableObject {
    
    private let generationService: GenerationService
    
    @Published var isFullVersion = PurchaseManager.shared.isFullVersion
    @Published var textRequest: String = "" {
        didSet {
            isTextRequestEmpty = false
        }
    }
    @Published var selectedGenre: Genre = .noGenre
    @Published var selectedMood: Mood = .noMood
    @Published var selectedDuration: Duration = .tenSeconds
    @Published var selectedPrompt: String = ""
    
    @Published var isTextRequestEmpty = false
    @Published var isGenerationReady = false
    
    private var isNeedToShowLoader: Bool {
        get {
            NavigationService.shared.isNeedToShowLoader
        }
        set {
            NavigationService.shared.isNeedToShowLoader = newValue
        }
    }
    
    private var isNeedToShowLongWaitingView: Bool {
        get {
            NavigationService.shared.isNeedToShowLongWaitingView
        }
        set {
            NavigationService.shared.isNeedToShowLongWaitingView = newValue
        }
    }
    
    private var generationsPerDay: Int {
        Service.shared.userSettings.generationsPerDay
    }
    
    private var generationWorkItem: DispatchWorkItem?
    
    // FIXME: navigationlink needs non optional
    @Published var generatedAudio: AudioItem = AudioItem(
        prompt: "",
        genre: .pop,
        mood: .relaxed,
        duration: .tenSeconds)

    private var cancellables = Set<AnyCancellable>()
    
    init(_ generationService: GenerationService = GenerationServiceImp()) {
        self.generationService = generationService
        setupBindings()
        startListenMonetizationStatus()
    }
}

// MARK: - Private methods

private extension GenerationViewModel {
    
    func setupBindings() {
        generationService.generationSubject
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    print("success")
                case .failure(let error):
                    self.handleErrorGeneration(error)
                }
            }, receiveValue: { audio in
                self.generatedAudio = audio
                self.showResult()
            })
            .store(in: &cancellables)
    }
    
    func handleErrorGeneration(_ error: Error) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.handleErrorGeneration(error)
            }
            return
        }
        guard let netError = error as? NetworkServiceError else {
            print(error.localizedDescription)
            showServerAlert()
            return
        }
        
        switch netError {
        case .notConnectedToInternet:
            showNoInternetAlert()
        case .serverUnavailable, .invalidServerResponse(code: _):
            showServerAlert()
        default:
            showServerAlert()
        }
        print(netError.localizedInfo ?? "Network Error")
    }
    
    func showResult() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.showResult()
            }
            return
        }
        generationWorkItem?.cancel()
        guard isNeedToShowLoader || isNeedToShowLongWaitingView else {
            return
        }
        isNeedToShowLoader = false
        isNeedToShowLongWaitingView = false
        isGenerationReady = true
        Analytic.Event.screen.log(.name, .result)
    }
    
    func showLongWaitingAlert() {
        isNeedToShowLongWaitingView = true
        isNeedToShowLoader = false
    }
    
    func showServerAlert() {
        generationWorkItem?.cancel()
        isNeedToShowLoader = false
        isNeedToShowLongWaitingView = false
        NavigationService.shared.isNeedToShowServerAlert = true
    }
    
    func showNoInternetAlert() {
        generationWorkItem?.cancel()
        isNeedToShowLoader = false
        isNeedToShowLongWaitingView = false
        NavigationService.shared.isNeedToShowNoInternetAlert = true
    }
}

extension GenerationViewModel {
    
    func generatePressed() {
        guard generationsPerDay < AppSettings.Content.generationsDailyLimitFree || PurchaseManager.shared.isFullVersion else {
            AdsPresenter.shared.showInternalOffer(place: .limit)
            return
        }
        guard !textRequest.isEmpty, !textRequest.trimmingCharacters(in: .whitespaces).isEmpty else {
            isTextRequestEmpty = true
            return
        }
        
        isGenerationReady = false
        isNeedToShowLoader = true

        let audioParameters: AudioParameters = (textRequest, selectedGenre, selectedMood, selectedDuration)
        generationService.generate(with: audioParameters)
        
        let generationWork = DispatchWorkItem {
            if Service.shared.userSettings.isLongWaitingAlertShowed {
                self.isNeedToShowLoader = false
                NavigationService.shared.showLibrary()
            } else {
                self.showLongWaitingAlert()
                Service.shared.userSettings.isLongWaitingAlertShowed = true
            }
        }
        generationWorkItem = generationWork
        DispatchQueue.main.asyncAfter(deadline: .now() + 15, execute: generationWork)
    }
    
    func cancelBindings() {
        cancellables.forEach { $0.cancel() }
    }
    
}

extension GenerationViewModel: SBMonetizationListener {
    func updatePaidStatus(purchased: Bool) {
        isFullVersion = purchased
    }
}

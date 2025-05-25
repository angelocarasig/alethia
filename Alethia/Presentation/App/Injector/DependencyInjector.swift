//
//  DependencyInjector.swift
//  Alethia
//
//  Created by Angelo Carasig on 11/4/2025.
//

import Foundation

final class DependencyInjector {
    static let shared: DependencyInjector = DependencyInjector()
    
    private init() {}
    
    private lazy var mangaRepository: MangaRepository = {
        let local = MangaLocalDataSource()
        let remote = MangaRemoteDataSource()
        
        return MangaRepositoryImpl(local: local, remote: remote)
    }()
    
    private lazy var sourcesRepository: SourcesRepository = {
        let local = SourceLocalDataSource()
        let remote = SourceRemoteDataSource()
        
        return SourcesRepositoryImpl(local: local, remote: remote)
    }()
    
    private lazy var chapterRepository: ChapterRepository = {
        let local = ChapterLocalDataSource()
        let remote = ChapterRemoteDataSource()
        
        return ChapterRepositoryImpl(local: local, remote: remote)
    }()
}

// MARK: Manga

extension DependencyInjector {
    func makeGetLibraryUseCase() -> GetLibraryUseCase {
        return GetLibraryUseCaseImpl(repository: mangaRepository)
    }
    
    func makeGetMangaDetailUseCase() -> GetMangaDetailUseCase {
        return GetMangaDetailUseCaseImpl(repository: mangaRepository)
    }
    
    func makeToggleMangaInLibraryUseCase() -> ToggleMangaInLibraryUseCase {
        return ToggleMangaInLibraryUserCaseImpl(repository: mangaRepository)
    }
    
    func makeUpdateMangaOrientationUseCase() -> UpdateMangaOrientationUseCase {
        return UpdateMangaOrientationUseCaseImpl(repository: mangaRepository)
    }
    
    func makeAddMangaOriginUseCase() -> AddMangaOriginUseCase {
        return AddMangaOriginUseCaseImpl(repository: mangaRepository)
    }
    
    func makeGetRecommendationsUseCase() -> GetRecommendationsUseCase {
        return GetRecommendationsUseCaseImpl(repository: mangaRepository)
    }
    
    func makeResolveMangaOrientationUseCase() -> ResolveMangaOrientationUseCase {
        return ResolveMangaOrientationImpl(repository: mangaRepository)
    }
}

// MARK: Sources

extension DependencyInjector {
    func makeGetHostsUseCase() -> GetHostsUseCase {
        return GetHostsUseCaseImpl(repository: sourcesRepository)
    }
    
    func makeGetSourcesUseCase() -> GetSourcesUseCase {
        return GetSourcesUseCaseImpl(repository: sourcesRepository)
    }
    
    func makeTestHostUrlUseCase() -> TestHostUseCase {
        return TestHostUseCaseImpl(repository: sourcesRepository)
    }
    
    func makeCreateHostUseCase() -> CreateHostUseCase {
        return CreateHostUseCaseImpl(repository: sourcesRepository)
    }
    
    func makeDeleteHostUseCase() -> DeleteHostUseCase {
        return DeleteHostUseCaseImpl(repository: sourcesRepository)
    }
    
    func makeToggleSourcePinnedUseCase() -> ToggleSourcePinnedUseCase {
        return ToggleSourcePinnedUseCaseImpl(repository: sourcesRepository)
    }
    
    func makeToggleSourceDisabledUseCase() -> ToggleSourceDisabledUseCase {
        return ToggleSourceDisabledUseCaseImpl(repository: sourcesRepository)
    }
    
    func makeSearchSourceUseCase() -> SearchSourceUseCase {
        return SearchSourceUseCaseImpl(repository: sourcesRepository)
    }
    
    func makeGetSourceRouteContentUseCase() -> GetSourceRouteContentUseCase {
        return GetSourceRouteContentUseCaseImpl(repository: sourcesRepository)
    }
    
    func makeObserveMatchEntriesUseCase() -> ObserveMatchEntriesUseCase {
        return ObserveMatchEntriesUseCaseImpl(repository: sourcesRepository)
    }
}

// MARK: Chapters

extension DependencyInjector {
    func makeGetChapterContentsUseCase() -> GetChapterContentsUseCase {
        return GetChapterContentsUseCaseImpl(repository: chapterRepository)
    }
    
    func makeMarkChapterReadUseCase() -> MarkChapterReadUseCase {
        return MarkChapterReadUseCaseImpl(repository: chapterRepository)
    }
    
    func makeUpdateChapterProgressUseCase() -> UpdateChapterProgressUseCase {
        return UpdateChapterProgressUseCaseImpl(repository: chapterRepository)
    }
    
    func makeMarkAllChaptersUseCase() -> MarkAllChaptersUseCase {
        return MarkAllChaptersUseCaseImpl(repository: chapterRepository)
    }
}

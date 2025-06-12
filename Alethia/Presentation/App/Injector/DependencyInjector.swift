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
    
    private lazy var queueActor: QueueActor = {
        return QueueActor()
    }()
    
    private lazy var mangaRepository: MangaRepository = {
        let local = MangaLocalDataSource()
        let remote = MangaRemoteDataSource()
        
        return MangaRepositoryImpl(local: local, remote: remote, actor: queueActor)
    }()
    
    private lazy var sourcesRepository: SourcesRepository = {
        let local = SourceLocalDataSource()
        let remote = SourceRemoteDataSource()
        
        return SourcesRepositoryImpl(local: local, remote: remote)
    }()
    
    private lazy var chapterRepository: ChapterRepository = {
        let local = ChapterLocalDataSource()
        let remote = ChapterRemoteDataSource()
        
        return ChapterRepositoryImpl(local: local, remote: remote, actor: queueActor)
    }()
    
    private lazy var collectionRepository: CollectionRepository = {
        let local = CollectionLocalDataSource()
        
        return CollectionRepositoryImpl(local: local)
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
    
    func makeRefreshMetadataUseCase() -> RefreshMetadataUseCase {
        return RefreshMetadataUseCaseImpl(repository: mangaRepository)
    }
    
    func makeAddMangaToLibraryUseCase() -> AddMangaToLibraryUseCase {
        return AddMangaToLibraryUseCaseImpl(repository: mangaRepository)
    }
    
    func makeRemoveMangaFromLibraryUseCase() -> RemoveMangaFromLibraryUseCase {
        return RemoveMangaFromLibraryUseCaseImpl(repository: mangaRepository)
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
    
    func makeUpdateMangaCoverUseCase() -> UpdateMangaCoverUseCase {
        return UpdateMangaCoverUseCaseImpl(repository: mangaRepository)
    }
    
    func makeUpdateMangaCollectionsUseCase() -> UpdateMangaCollectionsUseCase {
        return UpdateMangaCollectionsUseCaseImpl(repository: mangaRepository)
    }
    
    func makeUpdateOriginPriorityUseCase() -> UpdateOriginPriorityUseCase {
        return UpdateOriginPriorityUseCaseImpl(repository: mangaRepository)
    }
    
    func makeUpdateScanlatorPriorityUseCase() -> UpdateScanlatorPriorityUseCase {
        return UpdateScanlatorPriorityUseCaseImpl(repository: mangaRepository)
    }
    
    func makeUpdateMangaSettingsUseCase() -> UpdateMangaSettingsUseCase {
        return UpdateMangaSettingsUseCaseImpl(repository: mangaRepository)
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
    
    func makeDownloadChapterUseCase() -> DownloadChapterUseCase {
        return DownloadChapterUseCaseImpl(repository: chapterRepository)
    }
    
    func makeRemoveChapterDownloadUseCase() -> RemoveChapterDownloadUseCase {
        return RemoveChapterDownloadUseCaseImpl(repository: chapterRepository)
    }
    
    func makeRemoveAllChapterDownloadsUseCase() -> RemoveAllChapterDownloadsUseCase {
        return RemoveAllChapterDownloadsUseCaseImpl(repository: chapterRepository)
    }
}

// MARK: Collections

extension DependencyInjector {
    func makeAddCollectionUseCase() -> AddCollectionUseCase {
        return AddCollectionUseCaseImpl(repository: collectionRepository)
    }
    
    func makeGetAllCollectionsUseCase() -> GetAllCollectionsUseCase {
        return GetAllCollectionsUseCaseImpl(repository: collectionRepository)
    }
    
    func makeUpdateCollectionUseCase() -> UpdateCollectionUseCase {
        return UpdateCollectionUseCaseImpl(repository: collectionRepository)
    }
    
    func makeDeleteCollectionUseCase() -> DeleteCollectionUseCase {
        return DeleteCollectionUseCaseImpl(repository: collectionRepository)
    }
    
    func makeUpdateCollectionOrderUseCase() -> UpdateCollectionOrderUseCase {
        return UpdateCollectionOrderUseCaseImpl(repository: collectionRepository)
    }
}

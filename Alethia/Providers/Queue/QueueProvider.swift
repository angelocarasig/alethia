//
//  QueueProvider.swift
//  Alethia
//
//  Created by Angelo Carasig on 26/5/2025.
//

import Foundation
import Combine

@MainActor
final class QueueProvider: ObservableObject {
    static let shared = QueueProvider()
    
    // MARK: - Published Properties
    @Published private(set) var activeJobs: [UUID: QueueJob] = [:]
    @Published private(set) var jobProgress: [UUID: QueueJobProgress] = [:]
    
    // MARK: - Use-cases
    private let downloadChapterUseCase: DownloadChapterUseCase
    private var cancellables = Set<AnyCancellable>()
    private var activeTasks: [UUID: Task<Void, Never>] = [:]
    
    private init() {
        self.downloadChapterUseCase = DependencyInjector.shared.makeDownloadChapterUseCase()
    }
}

// MARK: - Chapter Downloading
extension QueueProvider {
    func downloadChapter(_ chapter: Chapter, priority: QueuePriority = .normal) {
        let job = QueueJob(
            action: .downloadChapter(chapter),
            priority: priority,
            date: Date()
        )
        
        // Add to active jobs
        activeJobs[job.id] = job
        
        // Initialize progress
        jobProgress[job.id] = QueueJobProgress(
            jobId: job.id,
            completed: 0,
            total: 100,
            status: .pending,
            error: nil,
            startedAt: nil,
            completedAt: nil
        )
        
        // Start download task
        let task = Task { [weak self] in
            guard let self = self else { return }
            
            // Update status to running
            self.jobProgress[job.id]?.status = .running
            self.jobProgress[job.id]?.startedAt = Date()
            
            // Execute download
            for await state in self.downloadChapterUseCase.execute(chapter: chapter) {
                self.handleJobState(state, for: job.id)
            }
            
            // Clean up active task
            self.activeTasks[job.id] = nil
        }
        
        activeTasks[job.id] = task
    }
    
    func cancelDownload(jobId: UUID) {
        // Cancel the task
        activeTasks[jobId]?.cancel()
        activeTasks[jobId] = nil
        
        // Update status
        jobProgress[jobId]?.status = .cancelled
        jobProgress[jobId]?.completedAt = Date()
        
        // Remove from active jobs and progress
        activeJobs[jobId] = nil
        jobProgress[jobId] = nil
    }
    
    private func handleJobState(_ state: QueueJobState, for jobId: UUID) {
        switch state {
        case .pending(let progress):
            jobProgress[jobId]?.completed = Int(progress * 100)
            
        case .success:
            jobProgress[jobId]?.status = .completed
            jobProgress[jobId]?.completedAt = Date()
            jobProgress[jobId]?.completed = 100
            
        case .failure(let error):
            jobProgress[jobId]?.status = .failed
            jobProgress[jobId]?.error = error
            jobProgress[jobId]?.completedAt = Date()
        }
    }
    
    // MARK: - Convenience Methods
    func isDownloading(_ chapter: Chapter) -> Bool {
        activeJobs.values.contains { job in
            if case .downloadChapter(let ch) = job.action {
                return ch.id == chapter.id
            }
            return false
        }
    }
    
    func progressForChapter(_ chapter: Chapter) -> QueueJobProgress? {
        guard let job = activeJobs.values.first(where: { job in
            if case .downloadChapter(let ch) = job.action {
                return ch.id == chapter.id
            }
            return false
        }) else { return nil }
        
        return jobProgress[job.id]
    }
}

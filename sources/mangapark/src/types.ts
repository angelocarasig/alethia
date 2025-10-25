export type MangaParkStatus = 'Ongoing' | 'Completed' | 'Hiatus' | 'Cancelled';

export const GQL_QUERIES = {
  SEARCH: `query get_searchComic($select: SearchComic_Select) {
    get_searchComic(select: $select) {
      paging {
        total
        pages
        page
        next
      }
      items {
        data {
          id
          name
          urlCover600
          urlCoverOri
        }
      }
    }
  }`,

  MANGA: `query get_comic($comicId: ID!) {
    get_comicNode(id: $comicId) {
      data {
        id
        name
        altNames
        authors
        artists
        genres
        summary
        originalStatus
        uploadStatus
        urlCoverOri
        urlCover900
        tranLang
        sfw_result
        dateCreate
        max_chapterNode {
          data {
            dateCreate
          }
        }
      }
    }
  }`,

  CHAPTERS: `query get_comicChapterList($comicId: ID!) {
    get_comicChapterList(comicId: $comicId) {
      data {
        id
        dname
        title
        urlPath
        dateCreate
        serial
        lang
        srcTitle
        sourceId
        userNode {
          data {
            name
          }
        }
      }
    }
  }`,

  CHAPTER: `query Get_chapterNode($chapterId: ID!) {
    get_chapterNode(id: $chapterId) {
      data {
        imageFile {
          urlList
        }
      }
    }
  }`,
} as const;

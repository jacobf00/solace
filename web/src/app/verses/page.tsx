'use client'

import { useState, useEffect } from 'react'
import { graphqlRequest, VERSE_FRAGMENT } from '@/lib/graphql/client'
import { Verse } from '@/types'

export default function VersesPage() {
  const [books, setBooks] = useState<string[]>([])
  const [selectedBook, setSelectedBook] = useState('')
  const [chapters, setChapters] = useState<number[]>([])
  const [selectedChapter, setSelectedChapter] = useState<number | null>(null)
  const [verses, setVerses] = useState<Verse[]>([])
  const [searchQuery, setSearchQuery] = useState('')
  const [searchResults, setSearchResults] = useState<Verse[]>([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    async function loadBooks() {
      try {
        const data = await graphqlRequest<{ allBooks: string[] }>(
          `
          query AllBooks {
            allBooks
          }
        `
        )
        setBooks(data.allBooks || [])
      } catch {
        setError('Failed to load books')
      }
    }

    loadBooks()
  }, [])

  useEffect(() => {
    if (!selectedBook) return

    async function loadChapters() {
      try {
        const data = await graphqlRequest<{ versesByBook: Verse[] }>(
          `
          query VersesByBook($book: String!) {
            versesByBook(book: $book) {
              ...VerseFields
            }
          }
          ${VERSE_FRAGMENT}
        `,
          { book: selectedBook }
        )

        const chapterSet = new Set<number>()
        data.versesByBook.forEach((v: Verse) => chapterSet.add(v.chapter))
        setChapters(Array.from(chapterSet).sort((a, b) => a - b))
      } catch {
        setError('Failed to load chapters')
      }
    }

    loadChapters()
  }, [selectedBook])

  useEffect(() => {
    if (!selectedBook || selectedChapter === null) return

    async function loadVerses() {
      setLoading(true)
      try {
        const data = await graphqlRequest<{ versesByBook: Verse[] }>(
          `
          query VersesByBook($book: String!, $chapter: Int) {
            versesByBook(book: $book, chapter: $chapter) {
              ...VerseFields
            }
          }
          ${VERSE_FRAGMENT}
        `,
          { book: selectedBook, chapter: selectedChapter }
        )
        setVerses(data.versesByBook || [])
      } catch {
        setError('Failed to load verses')
      } finally {
        setLoading(false)
      }
    }

    loadVerses()
  }, [selectedBook, selectedChapter])

  async function searchVerses() {
    if (!searchQuery.trim()) {
      setSearchResults([])
      return
    }

    setLoading(true)
    try {
      const data = await graphqlRequest<{ searchVerses: Verse[] }>(
        `
        query SearchVerses($query: String!, $limit: Int) {
          searchVerses(query: $query, limit: $limit) {
            ...VerseFields
          }
        }
        ${VERSE_FRAGMENT}
      `,
        { query: searchQuery, limit: 10 }
      )
      setSearchResults(data.searchVerses || [])
    } catch {
      setError('Search failed')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="max-w-4xl mx-auto">
      <h1 className="text-2xl font-bold text-gray-900 mb-6">Bible Verses</h1>

      {error && (
        <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
          {error}
        </div>
      )}

      <div className="mb-8">
        <h2 className="text-lg font-semibold text-gray-900 mb-4">
          Search Verses
        </h2>
        <div className="flex gap-2">
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search by keyword or topic..."
            className="flex-1 border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
          />
          <button
            onClick={searchVerses}
            disabled={loading}
            className="bg-indigo-600 text-white px-4 py-2 rounded-md hover:bg-indigo-500 disabled:opacity-50"
          >
            Search
          </button>
        </div>

        {searchResults.length > 0 && (
          <div className="mt-4 space-y-2">
            {searchResults.map((verse) => (
              <div key={verse.id} className="bg-white p-4 rounded shadow">
                <p className="font-semibold text-gray-900">
                  {verse.book} {verse.chapter}:{verse.verse}
                </p>
                <p className="text-gray-700 mt-1">{verse.text}</p>
              </div>
            ))}
          </div>
        )}
      </div>

      <div className="mb-8">
        <h2 className="text-lg font-semibold text-gray-900 mb-4">
          Browse by Book
        </h2>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-2">
          {books.map((book) => (
            <button
              key={book}
              onClick={() => {
                setSelectedBook(book)
                setSelectedChapter(null)
                setVerses([])
              }}
              className={`px-3 py-2 text-sm rounded-md transition-colors ${
                selectedBook === book
                  ? 'bg-indigo-600 text-white'
                  : 'bg-white text-gray-700 hover:bg-gray-100 border border-gray-300'
              }`}
            >
              {book}
            </button>
          ))}
        </div>
      </div>

      {selectedBook && (
        <div className="mb-8">
          <h2 className="text-lg font-semibold text-gray-900 mb-4">
            Select Chapter
          </h2>
          <div className="flex flex-wrap gap-2">
            {chapters.map((chapter) => (
              <button
                key={chapter}
                onClick={() => setSelectedChapter(chapter)}
                className={`px-3 py-2 text-sm rounded-md transition-colors ${
                  selectedChapter === chapter
                    ? 'bg-indigo-600 text-white'
                    : 'bg-white text-gray-700 hover:bg-gray-100 border border-gray-300'
                }`}
              >
                {chapter}
              </button>
            ))}
          </div>
        </div>
      )}

      {loading ? (
        <div className="text-center py-8">
          <span className="text-gray-500">Loading...</span>
        </div>
      ) : verses.length > 0 ? (
        <div className="space-y-4">
          <h2 className="text-lg font-semibold text-gray-900">
            {selectedBook} {selectedChapter}
          </h2>
          {verses.map((verse) => (
            <div key={verse.id} className="bg-white p-4 rounded shadow">
              <p className="font-semibold text-gray-900">
                <span className="text-indigo-600">
                  {verse.chapter}:{verse.verse}
                </span>
              </p>
              <p className="text-gray-700 mt-1">{verse.text}</p>
            </div>
          ))}
        </div>
      ) : null}
    </div>
  )
}

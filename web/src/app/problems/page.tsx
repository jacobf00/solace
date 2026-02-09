'use client'

import { useState, useEffect } from 'react'
import Link from 'next/link'
import { useAuth } from '@/components/providers/auth-provider'

interface Verse {
  id: string
  book: string
  chapter: number
  verse: number
  text: string
}

interface ReadingPlanItem {
  id: string
  item_order: number
  is_read: boolean
  verses: Verse
}

interface ReadingPlan {
  id: string
  created_at: string
  reading_plan_items: ReadingPlanItem[]
}

interface Problem {
  id: string
  title: string
  description: string
  context: string | null
  category: string | null
  created_at: string
  advice: string | null
  reading_plans: ReadingPlan[]
}

export default function ProblemsPage() {
  const [problems, setProblems] = useState<Problem[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const { user } = useAuth()

  useEffect(() => {
    if (!user) {
      setLoading(false)
      return
    }

    async function loadProblems() {
      try {
        const response = await fetch('/api/problems', {
          credentials: 'include',
        })
        
        if (!response.ok) {
          throw new Error('Failed to load problems')
        }
        
        const data = await response.json()
        setProblems(data || [])
      } catch (err) {
        setError('Failed to load problems')
        console.error(err)
      } finally {
        setLoading(false)
      }
    }

    loadProblems()
  }, [user])

  return (
    <div className="max-w-4xl mx-auto">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-2xl font-bold text-gray-900">My Problems</h1>
        <Link
          href="/problems/new"
          className="bg-indigo-600 text-white px-4 py-2 rounded-md hover:bg-indigo-500"
        >
          New Problem
        </Link>
      </div>

      {loading ? (
        <div className="text-center py-8">
          <span className="text-gray-500">Loading problems...</span>
        </div>
      ) : error ? (
        <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded">
          {error}
        </div>
      ) : problems.length === 0 ? (
        <div className="text-center py-8 bg-white rounded-lg shadow">
          <p className="text-gray-500 mb-4">
            You haven&apos;t submitted any problems yet
          </p>
          <Link
            href="/problems/new"
            className="text-indigo-600 hover:text-indigo-500"
          >
            Submit your first problem
          </Link>
        </div>
      ) : (
        <div className="space-y-4">
          {problems.map((problem) => (
            <div key={problem.id} className="bg-white rounded-lg shadow p-6">
              <div className="flex justify-between items-start">
                <div>
                  <h2 className="text-lg font-semibold text-gray-900">
                    {problem.title}
                  </h2>
                  {problem.category && (
                    <span className="inline-block bg-indigo-100 text-indigo-800 text-xs px-2 py-1 rounded mt-1">
                      {problem.category}
                    </span>
                  )}
                  <p className="text-gray-600 mt-2">{problem.description}</p>
                  {problem.context && (
                    <p className="text-gray-500 text-sm mt-1 italic">
                      Context: {problem.context}
                    </p>
                  )}
                  <p className="text-gray-400 text-sm mt-2">
                    {new Date(problem.created_at).toLocaleDateString()}
                  </p>
                </div>
                <Link
                  href={`/problems/${problem.id}`}
                  className="text-indigo-600 hover:text-indigo-500"
                >
                  View Details
                </Link>
              </div>

              {problem.reading_plans && problem.reading_plans.length > 0 && (
                <div className="mt-4 border-t pt-4">
                  <h3 className="text-sm font-medium text-gray-900 mb-2">
                    Reading Plan
                  </h3>
                  <div className="space-y-2">
                    {problem.reading_plans[0].reading_plan_items?.map((item) => (
                      <div
                        key={item.id}
                        className="flex items-start space-x-2 text-sm"
                      >
                        <input
                          type="checkbox"
                          checked={item.is_read}
                          disabled
                          className="mt-1 rounded border-gray-300 text-indigo-600 focus:ring-indigo-500"
                        />
                        <span
                          className={
                            item.is_read
                              ? 'line-through text-gray-400'
                              : 'text-gray-700'
                          }
                        >
                          {item.verses.book} {item.verses.chapter}:
                          {item.verses.verse}
                        </span>
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  )
}

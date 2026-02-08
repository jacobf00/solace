'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { useAuth } from '@/components/providers/auth-provider'
import { graphqlRequest } from '@/lib/graphql/client'
import { createClient } from '@/lib/supabase/client'

const categories = [
  'Relationships',
  'Work',
  'Health',
  'Finance',
  'Spiritual',
  'Family',
  'Other',
]

export default function NewProblemPage() {
  const [title, setTitle] = useState('')
  const [description, setDescription] = useState('')
  const [context, setContext] = useState('')
  const [category, setCategory] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)
  const router = useRouter()
  const { user } = useAuth()
  const supabase = createClient()

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setError(null)
    setLoading(true)

    if (!user) {
      setError('You must be logged in to submit a problem')
      setLoading(false)
      return
    }

    try {
      // Get the current session to retrieve the access token
      const { data: sessionData } = await supabase.auth.getSession()
      const token = sessionData.session?.access_token

      if (!token) {
        setError('Authentication error. Please log in again.')
        setLoading(false)
        return
      }

      const data = await graphqlRequest<{
        createProblem: { id: string }
      }>(
        `
        mutation CreateProblem($title: String!, $description: String!, $context: String, $category: String) {
          createProblem(title: $title, description: $description, context: $context, category: $category) {
            id
          }
        }
      `,
        {
          title,
          description,
          context: context || null,
          category: category || null,
        },
        token
      )

      if (data.createProblem?.id) {
        router.push(`/problems/${data.createProblem.id}`)
      }
    } catch (err) {
      setError('Failed to create problem. Please try again.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="max-w-2xl mx-auto">
      <h1 className="text-2xl font-bold text-gray-900 mb-6">
        Submit a Problem
      </h1>

      <p className="text-gray-600 mb-6">
        Share your life challenge and we&apos;ll provide you with relevant Bible
        verses and Biblical advice.
      </p>

      {error && (
        <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
          {error}
        </div>
      )}

      <form onSubmit={handleSubmit} className="space-y-6">
        <div>
          <label
            htmlFor="title"
            className="block text-sm font-medium text-gray-700"
          >
            Title
          </label>
          <input
            type="text"
            id="title"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            required
            placeholder="Brief summary of your problem"
            className="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
          />
        </div>

        <div>
          <label
            htmlFor="description"
            className="block text-sm font-medium text-gray-700"
          >
            Description
          </label>
          <textarea
            id="description"
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            required
            rows={5}
            placeholder="Describe your problem in detail..."
            className="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
          />
        </div>

        <div>
          <label
            htmlFor="context"
            className="block text-sm font-medium text-gray-700"
          >
            Additional Context (optional)
          </label>
          <textarea
            id="context"
            value={context}
            onChange={(e) => setContext(e.target.value)}
            rows={3}
            placeholder="Any additional details that might help provide better guidance..."
            className="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
          />
        </div>

        <div>
          <label
            htmlFor="category"
            className="block text-sm font-medium text-gray-700"
          >
            Category (optional)
          </label>
          <select
            id="category"
            value={category}
            onChange={(e) => setCategory(e.target.value)}
            className="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
          >
            <option value="">Select a category</option>
            {categories.map((cat) => (
              <option key={cat} value={cat}>
                {cat}
              </option>
            ))}
          </select>
        </div>

        <button
          type="submit"
          disabled={loading}
          className="w-full bg-indigo-600 text-white py-3 px-4 rounded-md hover:bg-indigo-500 disabled:opacity-50"
        >
          {loading ? 'Submitting...' : 'Submit Problem'}
        </button>
      </form>
    </div>
  )
}

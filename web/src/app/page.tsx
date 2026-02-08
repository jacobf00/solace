'use client'

import Link from 'next/link'
import { useAuth } from '@/components/providers/auth-provider'

export default function HomePage() {
  const { user, loading } = useAuth()

  return (
    <div className="text-center">
      <h1 className="text-4xl font-bold text-gray-900 mb-4">
        Welcome to Solace
      </h1>
      <p className="text-xl text-gray-600 mb-8">
        Bible reading plans and Biblical advice tailored to your life problems
      </p>

      {!loading && user ? (
        <div className="space-y-4">
          <Link
            href="/problems/new"
            className="inline-block bg-indigo-600 text-white px-6 py-3 rounded-md hover:bg-indigo-500"
          >
            Submit a New Problem
          </Link>
          <Link
            href="/problems"
            className="inline-block bg-white text-indigo-600 border border-indigo-600 px-6 py-3 rounded-md hover:bg-indigo-50 ml-4"
          >
            View My Problems
          </Link>
        </div>
      ) : (
        <div className="space-y-4">
          <p className="text-gray-600">
            Get started by creating an account or logging in
          </p>
          <div className="space-x-4">
            <Link
              href="/register"
              className="inline-block bg-indigo-600 text-white px-6 py-3 rounded-md hover:bg-indigo-500"
            >
              Create Account
            </Link>
            <Link
              href="/login"
              className="inline-block bg-white text-indigo-600 border border-indigo-600 px-6 py-3 rounded-md hover:bg-indigo-50"
            >
              Login
            </Link>
          </div>
        </div>
      )}

      <div className="mt-12 grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="bg-white p-6 rounded-lg shadow">
          <h3 className="text-lg font-semibold text-gray-900 mb-2">
            Submit Your Problem
          </h3>
          <p className="text-gray-600">
            Share your life challenges and get personalized Biblical guidance
          </p>
        </div>
        <div className="bg-white p-6 rounded-lg shadow">
          <h3 className="text-lg font-semibold text-gray-900 mb-2">
            AI-Powered Insights
          </h3>
          <p className="text-gray-600">
            Receive tailored Bible verses and advice using advanced AI
          </p>
        </div>
        <div className="bg-white p-6 rounded-lg shadow">
          <h3 className="text-lg font-semibold text-gray-900 mb-2">
            Reading Plans
          </h3>
          <p className="text-gray-600">
            Follow structured reading plans to grow spiritually
          </p>
        </div>
      </div>
    </div>
  )
}

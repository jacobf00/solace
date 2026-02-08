const USER_FRAGMENT = `
  fragment UserFields on User {
    id
    username
    email
  }
`

const VERSE_FRAGMENT = `
  fragment VerseFields on Verse {
    id
    book
    chapter
    verse
    text
  }
`

const PROBLEM_FRAGMENT = `
  fragment ProblemFields on Problem {
    id
    title
    description
    context
    category
    createdAt
    advice
  }
`

const READING_PLAN_FRAGMENT = `
  fragment ReadingPlanFields on ReadingPlan {
    id
    createdAt
    items {
      id
      itemOrder
      isRead
      verse {
        ...VerseFields
      }
    }
  }
  ${VERSE_FRAGMENT}
`

export async function graphqlRequest<T>(
  query: string,
  variables?: Record<string, unknown>,
  token?: string
): Promise<T> {
  const endpoint =
    process.env.NEXT_PUBLIC_GRAPHQL_ENDPOINT || 'http://localhost:8080/query'

  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
  }

  if (token) {
    headers['Authorization'] = `Bearer ${token}`
  }

  const response = await fetch(endpoint, {
    method: 'POST',
    headers,
    body: JSON.stringify({ query, variables }),
  })

  if (!response.ok) {
    throw new Error(`GraphQL request failed: ${response.statusText}`)
  }

  const result = await response.json()

  if (result.errors && result.errors.length > 0) {
    throw new Error(result.errors[0].message)
  }

  return result.data
}

export {
  USER_FRAGMENT,
  PROBLEM_FRAGMENT,
  VERSE_FRAGMENT,
  READING_PLAN_FRAGMENT,
}

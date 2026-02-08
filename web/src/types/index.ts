export interface User {
  id: string
  username: string
  email: string
}

export interface Verse {
  id: string
  book: string
  chapter: number
  verse: number
  text: string
}

export interface ReadingPlanItem {
  id: string
  itemOrder: number
  isRead: boolean
  verse: Verse
}

export interface ReadingPlan {
  id: string
  createdAt: string
  items: ReadingPlanItem[]
}

export interface Problem {
  id: string
  title: string
  description: string
  context?: string
  category?: string
  createdAt: string
  advice?: string
  readingPlan?: ReadingPlan
}

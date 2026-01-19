<script lang="ts">
	import { graphqlRequest } from '$lib/graphql';

	interface Verse {
		id: string;
		book: string;
		chapter: number;
		verse: number;
		text: string;
	}

	let books = $state<string[]>([]);
	let selectedBook = $state('');
	let chapters = $state<number[]>([]);
	let selectedChapter = $state<number | null>(null);
	let verses = $state<Verse[]>([]);
	let searchQuery = $state('');
	let searchResults = $state<Verse[]>([]);
	let loading = $state(false);
	let error = $state<string | null>(null);

	async function loadBooks() {
		try {
			const data = await graphqlRequest<{ allBooks: string[] }>(
				`
				query AllBooks {
					allBooks
				}
			`
			);
			books = data.allBooks || [];
		} catch {
			error = 'Failed to load books';
		}
	}

	async function loadChapters() {
		if (!selectedBook) return;
		
		try {
			const data = await graphqlRequest<{ versesByBook: Verse[] }>(
				`
				query VersesByBook($book: String!) {
					versesByBook(book: $book)
				}
			`,
				{ book: selectedBook }
			);
			
			const chapterSet = new Set<number>();
			(data.versesByBook || []).forEach((v: Verse) => chapterSet.add(v.chapter));
			chapters = Array.from(chapterSet).sort((a, b) => a - b);
		} catch {
			error = 'Failed to load chapters';
		}
	}

	async function loadVerses() {
		if (!selectedBook || !selectedChapter) return;
		
		loading = true;
		try {
			const data = await graphqlRequest<{ versesByBook: Verse[] }>(
				`
				query VersesByBook($book: String!, $chapter: Int) {
					versesByBook(book: $book, chapter: $chapter)
				}
			`,
				{ book: selectedBook, chapter: selectedChapter }
			);
			verses = data.versesByBook || [];
		} catch {
			error = 'Failed to load verses';
		} finally {
			loading = false;
		}
	}

	async function searchVerses() {
		if (!searchQuery.trim()) {
			searchResults = [];
			return;
		}
		
		loading = true;
		try {
			const data = await graphqlRequest<{ searchVerses: Verse[] }>(
				`
				query SearchVerses($query: String!, $limit: Int) {
					searchVerses(query: $query, limit: 10)
				}
			`,
				{ query: searchQuery, limit: 10 }
			);
			searchResults = data.searchVerses || [];
		} catch {
			error = 'Search failed';
		} finally {
			loading = false;
		}
	}

	$effect(() => {
		loadBooks();
	});

	$effect(() => {
		if (selectedBook) {
			loadChapters();
		}
	});

	$effect(() => {
		if (selectedBook && selectedChapter !== null) {
			loadVerses();
		}
	});
</script>

<div class="max-w-4xl mx-auto">
	<h1 class="text-2xl font-bold text-gray-900 mb-6">Bible Verses</h1>

	<div class="mb-8">
		<h2 class="text-lg font-semibold text-gray-900 mb-4">Search Verses</h2>
		<div class="flex gap-2">
			<input
				type="text"
				bind:value={searchQuery}
				placeholder="Search by keyword or topic..."
				class="flex-1 border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
			/>
			<button
				onclick={searchVerses}
				disabled={loading}
				class="bg-indigo-600 text-white px-4 py-2 rounded-md hover:bg-indigo-500 disabled:opacity-50"
			>
				Search
			</button>
		</div>

		{#if searchResults.length > 0}
			<div class="mt-4 space-y-2">
				{#each searchResults as verse}
					<div class="bg-white p-4 rounded shadow">
						<p class="font-semibold text-gray-900">
							{verse.book} {verse.chapter}:{verse.verse}
						</p>
						<p class="text-gray-700 mt-1">{verse.text}</p>
					</div>
				{/each}
			</div>
		{/if}
	</div>

	<div class="mb-8">
		<h2 class="text-lg font-semibold text-gray-900 mb-4">Browse by Book</h2>
		<div class="grid grid-cols-2 md:grid-cols-4 gap-2">
			{#each books as book}
				<button
					onclick={() => { selectedBook = book; selectedChapter = null; verses = []; }}
					class="px-3 py-2 text-sm rounded-md transition-colors
						{selectedBook === book 
							? 'bg-indigo-600 text-white' 
							: 'bg-white text-gray-700 hover:bg-gray-100 border border-gray-300'}"
				>
					{book}
				</button>
			{/each}
		</div>
	</div>

	{#if selectedBook}
		<div class="mb-8">
			<h2 class="text-lg font-semibold text-gray-900 mb-4">Select Chapter</h2>
			<div class="flex flex-wrap gap-2">
				{#each chapters as chapter}
					<button
						onclick={() => selectedChapter = chapter}
						class="px-3 py-2 text-sm rounded-md transition-colors
							{selectedChapter === chapter 
								? 'bg-indigo-600 text-white' 
								: 'bg-white text-gray-700 hover:bg-gray-100 border border-gray-300'}"
					>
						{chapter}
					</button>
				{/each}
			</div>
		</div>
	{/if}

	{#if loading}
		<div class="text-center py-8">
			<span class="text-gray-500">Loading...</span>
		</div>
	{:else if verses.length > 0}
		<div class="space-y-4">
			<h2 class="text-lg font-semibold text-gray-900">
				{selectedBook} {selectedChapter}
			</h2>
			{#each verses as verse}
				<div class="bg-white p-4 rounded shadow">
					<p class="font-semibold text-gray-900">
						<span class="text-indigo-600">{verse.chapter}:{verse.verse}</span>
					</p>
					<p class="text-gray-700 mt-1">{verse.text}</p>
				</div>
			{/each}
		</div>
	{/if}
</div>

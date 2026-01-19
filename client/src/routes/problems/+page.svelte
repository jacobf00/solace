<script lang="ts">
	import { graphqlRequest } from '$lib/graphql';
	import { auth } from '$lib/auth';

	interface Problem {
		id: string;
		title: string;
		description: string;
		context?: string;
		category?: string;
		createdAt: string;
		advice?: string;
		readingPlan?: {
			id: string;
			items: Array<{
				id: string;
				isRead: boolean;
				verse: {
					book: string;
					chapter: number;
					verse: number;
					text: string;
				};
			}>;
		};
	}

	let problems = $state<Problem[]>([]);
	let loading = $state(true);
	let error = $state<string | null>(null);

	async function loadProblems() {
		if (!$auth.token) return;
		
		try {
			const data = await graphqlRequest<{ myProblems: Problem[] }>(
				`
				query MyProblems {
					myProblems {
						id
						title
						description
						context
						category
						createdAt
						advice
						readingPlan {
							id
							items {
								id
								isRead
								verse {
									book
									chapter
									verse
									text
								}
							}
						}
					}
				}
			`,
				undefined,
				$auth.token
			);
			problems = data.myProblems || [];
		} catch (err) {
			error = 'Failed to load problems';
		} finally {
			loading = false;
		}
	}

	$effect(() => {
		if ($auth.token) {
			loadProblems();
		}
	});
</script>

<div class="max-w-4xl mx-auto">
	<div class="flex justify-between items-center mb-6">
		<h1 class="text-2xl font-bold text-gray-900">My Problems</h1>
		<a href="/problems/new" class="bg-indigo-600 text-white px-4 py-2 rounded-md hover:bg-indigo-500">
			New Problem
		</a>
	</div>

	{#if loading}
		<div class="text-center py-8">
			<span class="text-gray-500">Loading problems...</span>
		</div>
	{:else if error}
		<div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded">
			{error}
		</div>
	{:else if problems.length === 0}
		<div class="text-center py-8 bg-white rounded-lg shadow">
			<p class="text-gray-500 mb-4">You haven't submitted any problems yet</p>
			<a href="/problems/new" class="text-indigo-600 hover:text-indigo-500">
				Submit your first problem
			</a>
		</div>
	{:else}
		<div class="space-y-4">
			{#each problems as problem}
				<div class="bg-white rounded-lg shadow p-6">
					<div class="flex justify-between items-start">
						<div>
							<h2 class="text-lg font-semibold text-gray-900">{problem.title}</h2>
							{#if problem.category}
								<span class="inline-block bg-indigo-100 text-indigo-800 text-xs px-2 py-1 rounded mt-1">
									{problem.category}
								</span>
							{/if}
							<p class="text-gray-600 mt-2">{problem.description}</p>
							{#if problem.context}
								<p class="text-gray-500 text-sm mt-1 italic">Context: {problem.context}</p>
							{/if}
							<p class="text-gray-400 text-sm mt-2">
								{new Date(problem.createdAt).toLocaleDateString()}
							</p>
						</div>
						<a href="/problems/{problem.id}" class="text-indigo-600 hover:text-indigo-500">
							View Details
						</a>
					</div>

					{#if problem.readingPlan}
						<div class="mt-4 border-t pt-4">
							<h3 class="text-sm font-medium text-gray-900 mb-2">Reading Plan</h3>
							<div class="space-y-2">
								{#each problem.readingPlan.items as item}
									<div class="flex items-start space-x-2 text-sm">
										<input
											type="checkbox"
											checked={item.isRead}
											disabled
											class="mt-1 rounded border-gray-300 text-indigo-600 focus:ring-indigo-500"
										/>
										<span class="{item.isRead ? 'line-through text-gray-400' : 'text-gray-700'}">
											{item.verse.book} {item.verse.chapter}:{item.verse.verse}
										</span>
									</div>
								{/each}
							</div>
						</div>
					{/if}
				</div>
			{/each}
		</div>
	{/if}
</div>

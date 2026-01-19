<script lang="ts">
	import { graphqlRequest } from '$lib/graphql';
	import { auth } from '$lib/auth';
	import { goto } from '$app/navigation';

	let title = $state('');
	let description = $state('');
	let context = $state('');
	let category = $state('');
	let error = $state<string | null>(null);
	let loading = $state(false);

	const categories = [
		'Relationships',
		'Work',
		'Health',
		'Finance',
		'Spiritual',
		'Family',
		'Other',
	];

	async function handleSubmit(e: Event) {
		e.preventDefault();
		error = null;
		loading = true;

		if (!$auth.token) {
			error = 'You must be logged in to submit a problem';
			loading = false;
			return;
		}

		try {
			const data = await graphqlRequest<{ createProblem: { id: string } }>(
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
				$auth.token
			);

			if (data.createProblem?.id) {
				goto(`/problems/${data.createProblem.id}`);
			}
		} catch (err) {
			error = 'Failed to create problem. Please try again.';
		} finally {
			loading = false;
		}
	}
</script>

<div class="max-w-2xl mx-auto">
	<h1 class="text-2xl font-bold text-gray-900 mb-6">Submit a Problem</h1>

	<p class="text-gray-600 mb-6">
		Share your life challenge and we'll provide you with relevant Bible verses and Biblical advice.
	</p>

	{#if error}
		<div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
			{error}
		</div>
	{/if}

	<form onsubmit={handleSubmit} class="space-y-6">
		<div>
			<label for="title" class="block text-sm font-medium text-gray-700">Title</label>
			<input
				type="text"
				id="title"
				bind:value={title}
				required
				placeholder="Brief summary of your problem"
				class="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
			/>
		</div>

		<div>
			<label for="description" class="block text-sm font-medium text-gray-700">Description</label>
			<textarea
				id="description"
				bind:value={description}
				required
				rows="5"
				placeholder="Describe your problem in detail..."
				class="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
			></textarea>
		</div>

		<div>
			<label for="context" class="block text-sm font-medium text-gray-700">Additional Context (optional)</label>
			<textarea
				id="context"
				bind:value={context}
				rows="3"
				placeholder="Any additional details that might help provide better guidance..."
				class="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
			></textarea>
		</div>

		<div>
			<label for="category" class="block text-sm font-medium text-gray-700">Category (optional)</label>
			<select
				id="category"
				bind:value={category}
				class="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
			>
				<option value="">Select a category</option>
				{#each categories as cat}
					<option value={cat}>{cat}</option>
				{/each}
			</select>
		</div>

		<button
			type="submit"
			disabled={loading}
			class="w-full bg-indigo-600 text-white py-3 px-4 rounded-md hover:bg-indigo-500 disabled:opacity-50"
		>
			{loading ? 'Submitting...' : 'Submit Problem'}
		</button>
	</form>
</div>

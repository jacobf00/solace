<script lang="ts">
	import '../app.css';
	import { onMount } from 'svelte';
	import { auth } from '$lib/auth';

	let { children } = $props();

	onMount(() => {
		auth.initialize();
	});
</script>

<div class="min-h-screen bg-gray-50">
	<nav class="bg-white shadow-sm">
		<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
			<div class="flex justify-between h-16">
				<div class="flex">
					<div class="flex-shrink-0 flex items-center">
						<a href="/" class="text-xl font-bold text-indigo-600">Solace</a>
					</div>
					<div class="hidden sm:ml-6 sm:flex sm:space-x-8">
						<a href="/" class="border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium">Home</a>
						<a href="/problems" class="border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium">Problems</a>
						<a href="/verses" class="border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium">Bible Verses</a>
					</div>
				</div>
				<div class="flex items-center">
					{#if $auth.loading}
						<span class="text-gray-500">Loading...</span>
					{:else if $auth.user}
						<span class="text-gray-700 mr-4">{$auth.user.username}</span>
						<button onclick={() => auth.logout()} class="text-indigo-600 hover:text-indigo-500">Logout</button>
					{:else}
						<a href="/login" class="text-gray-700 hover:text-indigo-600 mr-4">Login</a>
						<a href="/register" class="bg-indigo-600 text-white px-4 py-2 rounded-md hover:bg-indigo-500">Register</a>
					{/if}
				</div>
			</div>
		</div>
	</nav>

	<main class="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
		{@render children()}
	</main>
</div>

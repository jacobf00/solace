<script lang="ts">
	import { auth, supabase } from '$lib';
	import { goto } from '$app/navigation';

	let email = $state('');
	let password = $state('');
	let error = $state<string | null>(null);
	let loading = $state(false);

	async function handleLogin(e: Event) {
		e.preventDefault();
		error = null;
		loading = true;

		try {
			const { data, error: authError } = await supabase.auth.signInWithPassword({
				email,
				password,
			});

			if (authError) {
				error = authError.message;
				return;
			}

			if (data.session) {
				auth.setUser(
					{
						id: data.user.id,
						username: data.user.user_metadata.username || data.user.email,
						email: data.user.email!,
					},
					data.session.access_token
				);
				goto('/');
			}
		} catch {
			error = 'An unexpected error occurred';
		} finally {
			loading = false;
		}
	}
</script>

<div class="max-w-md mx-auto">
	<h1 class="text-2xl font-bold text-gray-900 mb-6">Login to Solace</h1>

	{#if error}
		<div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
			{error}
		</div>
	{/if}

	<form onsubmit={handleLogin} class="space-y-4">
		<div>
			<label for="email" class="block text-sm font-medium text-gray-700">Email</label>
			<input
				type="email"
				id="email"
				bind:value={email}
				required
				class="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
			/>
		</div>

		<div>
			<label for="password" class="block text-sm font-medium text-gray-700">Password</label>
			<input
				type="password"
				id="password"
				bind:value={password}
				required
				class="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
			/>
		</div>

		<button
			type="submit"
			disabled={loading}
			class="w-full bg-indigo-600 text-white py-2 px-4 rounded-md hover:bg-indigo-500 disabled:opacity-50"
		>
			{loading ? 'Logging in...' : 'Login'}
		</button>
	</form>

	<p class="mt-4 text-center text-sm text-gray-600">
		Don't have an account? <a href="/register" class="text-indigo-600 hover:text-indigo-500">Register</a>
	</p>
</div>

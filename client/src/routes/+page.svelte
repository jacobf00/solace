<script lang="ts">
	import { auth, isAuthenticated } from '$lib/auth';
</script>

<div class="text-center">
	<h1 class="text-4xl font-bold text-gray-900 mb-4">Welcome to Solace</h1>
	<p class="text-xl text-gray-600 mb-8">
		Bible reading plans and Biblical advice tailored to your life problems
	</p>

	{#if $isAuthenticated}
		<div class="space-y-4">
			<a href="/problems/new" class="inline-block bg-indigo-600 text-white px-6 py-3 rounded-md hover:bg-indigo-500">
				Submit a New Problem
			</a>
			<a href="/problems" class="inline-block bg-white text-indigo-600 border border-indigo-600 px-6 py-3 rounded-md hover:bg-indigo-50 ml-4">
				View My Problems
			</a>
		</div>
	{:else}
		<div class="space-y-4">
			<p class="text-gray-600">Get started by creating an account or logging in</p>
			<div class="space-x-4">
				<a href="/register" class="inline-block bg-indigo-600 text-white px-6 py-3 rounded-md hover:bg-indigo-500">
					Create Account
				</a>
				<a href="/login" class="inline-block bg-white text-indigo-600 border border-indigo-600 px-6 py-3 rounded-md hover:bg-indigo-50">
					Login
				</a>
			</div>
		</div>
	{/if}

	<div class="mt-12 grid grid-cols-1 md:grid-cols-3 gap-6">
		<div class="bg-white p-6 rounded-lg shadow">
			<h3 class="text-lg font-semibold text-gray-900 mb-2">Submit Your Problem</h3>
			<p class="text-gray-600">Share your life challenges and get personalized Biblical guidance</p>
		</div>
		<div class="bg-white p-6 rounded-lg shadow">
			<h3 class="text-lg font-semibold text-gray-900 mb-2">AI-Powered Insights</h3>
			<p class="text-gray-600">Receive tailored Bible verses and advice using advanced AI</p>
		</div>
		<div class="bg-white p-6 rounded-lg shadow">
			<h3 class="text-lg font-semibold text-gray-900 mb-2">Reading Plans</h3>
			<p class="text-gray-600">Follow structured reading plans to grow spiritually</p>
		</div>
	</div>
</div>

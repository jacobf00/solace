import { writable, derived } from 'svelte/store';
import { supabase } from './supabase';
import { graphqlRequest } from './graphql';

interface User {
	id: string;
	username: string;
	email: string;
}

interface AuthState {
	user: User | null;
	token: string | null;
	loading: boolean;
	error: string | null;
}

function createAuthStore() {
	const { subscribe, set, update } = writable<AuthState>({
		user: null,
		token: null,
		loading: true,
		error: null,
	});

	return {
		subscribe,
		setUser: (user: User | null, token: string | null) => {
			update((state) => ({ ...state, user, token, loading: false, error: null }));
		},
		setLoading: (loading: boolean) => {
			update((state) => ({ ...state, loading }));
		},
		setError: (error: string | null) => {
			update((state) => ({ ...state, error, loading: false }));
		},
		logout: async () => {
			await supabase.auth.signOut();
			set({ user: null, token: null, loading: false, error: null });
		},
		initialize: async () => {
			const {
				data: { session },
			} = await supabase.auth.getSession();

			if (session) {
				const token = session.access_token;
				try {
					const data = await graphqlRequest<{ me: User }>(
						`
						query Me {
							me {
								id
								username
								email
							}
						}
					`,
						undefined,
						token
					);
					if (data.me) {
						set({ user: data.me, token, loading: false, error: null });
					} else {
						set({ user: null, token: null, loading: false, error: null });
					}
				} catch {
					set({ user: null, token: null, loading: false, error: null });
				}
			} else {
				set({ user: null, token: null, loading: false, error: null });
			}
		},
	};
}

export const auth = createAuthStore();
export const isAuthenticated = derived(auth, ($auth) => $auth.user !== null);

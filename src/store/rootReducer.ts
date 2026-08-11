/**
 * Root reducer aggregator.
 * Since the project uses Zustand for auth state, this file serves as a
 * central place to re-export combined stores. If migrating to Redux Toolkit,
 * individual feature slices (e.g. authSlice, ticketsSlice) would be combined here.
 */
export { useAuthStore } from './store';

// Placeholder for feature slices (Redux migration path)
// import authReducer from '@/features/auth/auth.slice';
// import ticketsReducer from '@/features/tickets/tickets.slice';
// export const rootReducer = combineReducers({ auth, tickets });

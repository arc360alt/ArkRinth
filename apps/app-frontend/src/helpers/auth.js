/**
 * All theseus API calls return serialized values (both return values and errors);
 * So, for example, addDefaultInstance creates a blank Profile object, where the Rust struct is serialized,
 *  and deserialized into a usable JS object.
 */
import { invoke } from '@tauri-apps/api/core'

const OFFLINE_ACCOUNTS_KEY = 'offlineAccounts'
const OFFLINE_DEFAULT_USER_KEY = 'offlineDefaultUser'

/**
 * Wrap backend invokes with a timeout to prevent indefinite hanging
 */
async function invokeWithTimeout(cmd, args = {}, timeoutMs = 5000) {
	return Promise.race([
		invoke(cmd, args),
		new Promise((_, reject) =>
			setTimeout(() => reject(new Error(`Backend timeout: ${cmd}`)), timeoutMs),
		),
	])
}

function getOfflineAccountsMap() {
	return JSON.parse(localStorage.getItem(OFFLINE_ACCOUNTS_KEY) || '{}')
}

function setOfflineAccountsMap(accounts) {
	localStorage.setItem(OFFLINE_ACCOUNTS_KEY, JSON.stringify(accounts))
}

export async function check_reachable() {
	try {
		await invokeWithTimeout('plugin:auth|check_reachable', {}, 3000)
	} catch (error) {
		console.warn('Backend not reachable:', error)
	}
}

export async function login() {
	// Microsoft auth can take several minutes (external browser + callback),
	// so this call must not use a frontend timeout.
	return await invoke('plugin:auth|login')
}

export async function get_default_user() {
	try {
		const defaultUser = await invokeWithTimeout('plugin:auth|get_default_user', {}, 3000)
		if (defaultUser) {
			localStorage.setItem(OFFLINE_DEFAULT_USER_KEY, defaultUser)
		}
		return defaultUser
	} catch (error) {
		console.warn('Could not get default user:', error)
		return localStorage.getItem(OFFLINE_DEFAULT_USER_KEY) || undefined
	}
}

export async function set_default_user(user) {
	if (user) {
		localStorage.setItem(OFFLINE_DEFAULT_USER_KEY, user)
	}

	try {
		return await invokeWithTimeout('plugin:auth|set_default_user', { user })
	} catch (error) {
		console.warn('Could not set default user:', error)
	}
}

export async function remove_user(user) {
	if (user && user.startsWith('offline-')) {
		const offlineAccounts = getOfflineAccountsMap()
		delete offlineAccounts[user]
		setOfflineAccountsMap(offlineAccounts)

		if (localStorage.getItem(OFFLINE_DEFAULT_USER_KEY) === user) {
			localStorage.removeItem(OFFLINE_DEFAULT_USER_KEY)
		}
		return
	}

	try {
		return await invokeWithTimeout('plugin:auth|remove_user', { user })
	} catch (error) {
		console.warn('Could not remove user:', error)
	}
}

export async function users() {
	const offlineAccounts = Object.values(getOfflineAccountsMap())

	try {
		const backendUsers = await invokeWithTimeout('plugin:auth|get_users', {}, 3000)
		if (!Array.isArray(backendUsers)) {
			return offlineAccounts
		}

		const seen = new Set(backendUsers.map((x) => x?.profile?.id).filter(Boolean))
		const uniqueOffline = offlineAccounts.filter((x) => !seen.has(x?.profile?.id || x?.id))
		return [...backendUsers, ...uniqueOffline]
	} catch (error) {
		console.warn('Using offline accounts only:', error)
		return offlineAccounts
	}
}

export async function create_offline_user(username) {
	if (!username || username.trim().length === 0) {
		throw new Error('Username cannot be empty')
	}

	const normalizedUsername = username.trim()

	// Create in the backend (SQLite) so the launcher can find credentials when launching
	const credentials = await invoke('plugin:auth|create_offline_user', { username: normalizedUsername })

	// Also keep a localStorage copy so the UI can display it even if backend is slow
	const offlineAccounts = getOfflineAccountsMap()
	offlineAccounts[credentials.profile.id] = {
		id: credentials.profile.id,
		username: normalizedUsername,
		offline: true,
		created: new Date().toISOString(),
		profile: credentials.profile,
	}
	setOfflineAccountsMap(offlineAccounts)

	return credentials
}

export async function get_offline_accounts() {
	return Object.values(getOfflineAccountsMap())
}

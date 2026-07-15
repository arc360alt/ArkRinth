<template>
	<div
		v-if="accounts.length === 0"
		class="flex flex-col gap-3 bg-button-bg border border-solid border-surface-5 rounded-xl p-3 mt-2"
	>
		<span>{{ formatMessage(messages.notSignedIn) }}</span>
		<ButtonStyled color="brand">
			<button color="primary" :disabled="loginDisabled" @click="login()">
				<LogInIcon v-if="!loginDisabled" />
				<SpinnerIcon v-else class="animate-spin" />
				{{ formatMessage(messages.signInToMinecraft) }}
			</button>
		</ButtonStyled>
	</div>
	<Accordion
		v-else
		class="w-full mt-2 bg-button-bg border border-solid border-surface-5 rounded-xl overflow-clip"
		button-class="button-base w-full bg-transparent px-3 py-2 border-0 cursor-pointer"
		:open-by-default="false"
	>
		<template #title>
			<div class="flex gap-2 w-full min-w-0">
				<Avatar
					size="36px"
					:src="
						selectedAccount
							? avatarUrl
							: 'https://launcher-files.modrinth.com/assets/steve_head.png'
					"
				/>
				<div class="flex flex-col items-start w-full min-w-0">
					<span class="truncate w-full text-left">{{
						selectedAccount ? selectedAccount.profile.name : formatMessage(messages.selectAccount)
					}}</span>
					<span class="text-secondary text-xs">{{ formatMessage(messages.minecraftAccount) }}</span>
				</div>
			</div>
		</template>
		<div class="bg-button-bg pt-1 pb-2 border border-solid border-surface-5">
			<template v-if="accounts.length > 0">
				<div v-for="account in accounts" :key="account.profile.id" class="flex gap-1 items-center">
					<button
						class="flex items-center flex-shrink flex-grow overflow-clip gap-2 p-2 border-0 bg-transparent cursor-pointer button-base min-w-0"
						@click="setAccount(account)"
					>
						<RadioButtonCheckedIcon
							v-if="selectedAccount && selectedAccount.profile.id === account.profile.id"
							class="w-5 h-5 text-brand shrink-0"
						/>
						<RadioButtonIcon v-else class="w-5 h-5 text-secondary shrink-0" />
						<Avatar :src="getAccountAvatarUrl(account)" size="24px" />
						<p
							class="m-0 truncate min-w-0"
							:class="
								selectedAccount && selectedAccount.profile.id === account.profile.id
									? 'text-contrast font-semibold'
									: 'text-primary'
							"
						>
							{{ account.profile.name }}
						</p>
					</button>
					<ButtonStyled circular color="red" color-fill="none" hover-color-fill="background">
						<button
							v-tooltip="formatMessage(messages.removeAccount)"
							class="mr-2"
							@click="logout(account.profile.id)"
						>
							<TrashIcon />
						</button>
					</ButtonStyled>
				</div>
			</template>
			<div class="flex flex-col gap-2 px-2 pt-2">
				<ButtonStyled v-if="accounts.length > 0" class="w-full">
					<button :disabled="loginDisabled" @click="login()">
						<PlusIcon />
						{{ formatMessage(messages.addAccount) }}
					</button>
				</ButtonStyled>
			</div>
			<Button v-if="accounts.length > 0" @click="login()">
				<PlusIcon />
				Add account
			</Button>
			<div class="offline-section">
				<p class="offline-label">Play offline</p>
				<div class="offline-input-row">
					<input
						v-model="offlineUsername"
						class="offline-username-input"
						placeholder="Enter username"
						maxlength="16"
						@keydown.enter="loginOffline"
					/>
					<Button
						:disabled="loginDisabled || !offlineUsername.trim()"
						color="primary"
						@click="loginOffline"
					>
						<SpinnerIcon v-if="loginDisabled" class="animate-spin" />
						<LogInIcon v-else />
					</Button>
				</div>
			</div>
		</Card>
	</transition>
</template>

<script setup lang="ts">
import {
	LogInIcon,
	PlusIcon,
	RadioButtonCheckedIcon,
	RadioButtonIcon,
	SpinnerIcon,
	TrashIcon,
} from '@modrinth/assets'
import {
	Accordion,
	Avatar,
	ButtonStyled,
	defineMessages,
	injectNotificationManager,
	useVIntl,
} from '@modrinth/ui'
import type { Ref } from 'vue'
import { computed, onUnmounted, ref } from 'vue'

import { trackEvent } from '@/helpers/analytics'
import {
	create_offline_user,
	get_default_user,
	login as login_flow,
	remove_user,
	set_default_user,
	users,
} from '@/helpers/auth'
import { process_listener } from '@/helpers/events'
import { getPlayerHeadUrl } from '@/helpers/rendering/batch-skin-renderer.ts'
import type { Skin } from '@/helpers/skins'
import { get_available_skins } from '@/helpers/skins'
import { handleSevereError } from '@/store/error.js'

const { formatMessage } = useVIntl()
const { handleError } = injectNotificationManager()

defineProps({
	mode: {
		type: String,
		required: true,
		default: 'normal',
	},
})

const emit = defineEmits(['change'])

const accounts = ref([])
const loginDisabled = ref(false)
const defaultUser = ref()
const equippedSkin = ref(null)
const headUrlCache = ref(new Map())
const offlineUsername = ref('')

function normalizeAccount(account) {
	if (!account) return null

	// Always set offline flag if id starts with offline-
	if (account.profile?.id && account.profile?.name) {
		if (account.profile.id.startsWith('offline-')) {
			return { ...account, offline: true }
		}
		return account
	}

	if (account.id && account.username) {
		const isOffline = account.id.startsWith('offline-')
		return {
			...account,
			offline: isOffline,
			profile: {
				id: account.id,
				name: account.username,
			},
		}
	}

	return null
}

async function refreshValues() {
	defaultUser.value = await get_default_user().catch(handleError)
	const loadedUsers = await users().catch(handleError)
	const normalizedAccounts = (Array.isArray(loadedUsers) ? loadedUsers : [])
		.map(normalizeAccount)
		.filter(Boolean)
	accounts.value = normalizedAccounts

	if (!defaultUser.value && normalizedAccounts.length > 0) {
		defaultUser.value = normalizedAccounts[0].profile.id
	}

	// Only fetch skins if there is a valid selected account and it is not offline
	const selected = accounts.value.find(a => a.profile.id === defaultUser.value)
	if (!selected || selected.offline) {
		equippedSkin.value = null
		return
	}

	try {
		const skins = await get_available_skins()
		equippedSkin.value = skins.find((skin) => skin.is_equipped) ?? null

		if (equippedSkin.value) {
			try {
				const headUrl = await getPlayerHeadUrl(equippedSkin.value)
				headUrlCache.value = new Map(headUrlCache.value).set(
					equippedSkin.value.texture_key,
					headUrl,
				)
			} catch (error) {
				console.warn('Failed to get head render for equipped skin:', error)
			}
		}
	} catch {
		equippedSkin.value = null
	}
}

async function setEquippedSkin(skin: Skin) {
	equippedSkin.value = skin

	try {
		const headUrl = await getPlayerHeadUrl(skin)
		headUrlCache.value = new Map(headUrlCache.value).set(skin.texture_key, headUrl)
	} catch (error) {
		console.warn('Failed to get head render for equipped skin:', error)
	}
}

function setLoginDisabled(value: boolean) {
	loginDisabled.value = value
}

defineExpose({
	refreshValues,
	setEquippedSkin,
	setLoginDisabled,
	loginDisabled,
})

await refreshValues()

const displayAccounts = computed(() => {
	if (!Array.isArray(accounts.value)) return []
	return accounts.value.filter((account) => defaultUser.value !== account.profile.id)
})

const avatarUrl = computed(() => {
	if (equippedSkin.value?.texture_key) {
		const cachedUrl = headUrlCache.value.get(equippedSkin.value.texture_key)
		if (cachedUrl) {
			return cachedUrl
		}
		return `https://mc-heads.net/avatar/${equippedSkin.value.texture_key}/128`
	}
	if (selectedAccount.value?.profile?.id) {
		return `https://mc-heads.net/avatar/${selectedAccount.value.profile.id}/128`
	}
	return 'https://launcher-files.modrinth.com/assets/steve_head.png'
})

function getAccountAvatarUrl(account: MinecraftCredential) {
	if (
		account.profile.id === selectedAccount.value?.profile?.id &&
		equippedSkin.value?.texture_key
	) {
		const cachedUrl = headUrlCache.value.get(equippedSkin.value.texture_key)
		if (cachedUrl) {
			return cachedUrl
		}
	}
	return `https://mc-heads.net/avatar/${account.profile.id}/128`
}

const selectedAccount = computed(() => {
	if (!Array.isArray(accounts.value)) return undefined
	return accounts.value.find((account) => account.profile.id === defaultUser.value)
})

async function setAccount(account) {
	if (!account?.profile?.id) return
	defaultUser.value = account.profile.id
	await set_default_user(account.profile.id).catch(handleError)
	await refreshValues()
	emit('change')
}

async function login() {
	loginDisabled.value = true
	// Clear all account state before login to avoid ghosts
	accounts.value = []
	defaultUser.value = null
	equippedSkin.value = null
	headUrlCache.value.clear()
	await refreshValues()
	const loggedIn = await login_flow().catch(handleSevereError)

	if (loggedIn) {
		await setAccount(loggedIn)
	}

	trackEvent('AccountLogIn')
	loginDisabled.value = false
}

async function loginOffline() {
	const username = offlineUsername.value.trim()
	if (!username) return

	loginDisabled.value = true
	// Clear all account state before offline login to avoid ghosts
	accounts.value = []
	defaultUser.value = null
	equippedSkin.value = null
	headUrlCache.value.clear()
	await refreshValues()
	const account = await create_offline_user(username).catch(handleError)

	if (account) {
		await setAccount(account)
		await refreshValues()
		offlineUsername.value = ''
	}

	trackEvent('AccountOfflineLogIn')
	loginDisabled.value = false
}

const logout = async (id) => {
	await remove_user(id).catch(handleError)
	// Clear all account state after removal to avoid ghosts
	accounts.value = []
	defaultUser.value = null
	equippedSkin.value = null
	headUrlCache.value.clear()
	await refreshValues()
	// Do NOT auto-select a new account after logout; just emit change
	emit('change')
	trackEvent('AccountLogOut')
}

const showCard = ref(false)
const card = ref(null)
const button = ref(null)
const handleClickOutside = (event) => {
	const elements = document.elementsFromPoint(event.clientX, event.clientY)
	if (
		card.value &&
		card.value.$el !== event.target &&
		!elements.includes(card.value.$el) &&
		button.value &&
		!button.value.contains(event.target)
	) {
		toggleMenu(false)
	}
}

function toggleMenu(override = true) {
	if (showCard.value || !override) {
		showCard.value = false
	} else {
		showCard.value = true
	}
}

const unlisten = await process_listener(async (e) => {
	if (e.event === 'launched') {
		await refreshValues()
	}
})

onUnmounted(() => {
	unlisten()
})

const messages = defineMessages({
	notSignedIn: {
		id: 'minecraft-account.not-signed-in',
		defaultMessage: 'Not signed in',
	},
	addAccount: {
		id: 'minecraft-account.add-account',
		defaultMessage: 'Add account',
	},
	removeAccount: {
		id: 'minecraft-account.remove-account',
		defaultMessage: 'Remove account',
	},
	selectAccount: {
		id: 'minecraft-account.select-account',
		defaultMessage: 'Select account',
	},
	minecraftAccount: {
		id: 'minecraft-account.label',
		defaultMessage: 'Minecraft account',
	},
	signInToMinecraft: {
		id: 'minecraft-account.sign-in',
		defaultMessage: 'Sign in to Minecraft',
	},
})
</script>

<style scoped lang="scss">
.selected {
	background: var(--color-brand-highlight);
	border-radius: var(--radius-lg);
	color: var(--color-contrast);
	gap: 1rem;
}

.logged-out {
	background: var(--color-bg);
	border-radius: var(--radius-lg);
	gap: 1rem;
}

.account {
	width: max-content;
	display: flex;
	align-items: center;
	text-align: left;
	padding: 0.5rem 1rem;

	h4,
	p {
		margin: 0;
	}
}

.account-card {
	position: fixed;
	display: flex;
	flex-direction: column;
	margin-top: 0.5rem;
	right: 2rem;
	z-index: 11;
	gap: 0.5rem;
	padding: 1rem;
	border: 1px solid var(--color-divider);
	width: max-content;
	user-select: none;
	-ms-user-select: none;
	-webkit-user-select: none;
	max-height: calc(100vh - 300px);
	overflow-y: auto;

	&::-webkit-scrollbar-track {
		border-top-right-radius: 1rem;
		border-bottom-right-radius: 1rem;
	}

	&::-webkit-scrollbar {
		border-top-right-radius: 1rem;
		border-bottom-right-radius: 1rem;
	}

	&.hidden {
		display: none;
	}

	&.expanded {
		left: 13.5rem;
	}

	&.isolated {
		position: relative;
		left: 0;
		top: 0;
	}
}

.accounts-title {
	font-size: 1.2rem;
	font-weight: bolder;
}

.account-group {
	width: 100%;
	display: flex;
	flex-direction: column;
	gap: 0.5rem;
}

.option {
	width: calc(100% - 2.25rem);
	background: var(--color-raised-bg);
	color: var(--color-base);
	box-shadow: none;

	img {
		margin-right: 0.5rem;
	}
}

.icon {
	--size: 1.5rem !important;
}

.account-row {
	display: flex;
	flex-direction: row;
	gap: 0.5rem;
	vertical-align: center;
	justify-content: space-between;
	padding-right: 1rem;
}

.fade-enter-active,
.fade-leave-active {
	transition:
		opacity 0.25s ease,
		translate 0.25s ease,
		scale 0.25s ease;
}

.fade-enter-from,
.fade-leave-to {
	opacity: 0;
	translate: 0 -2rem;
	scale: 0.9;
}

.avatar-button {
	display: flex;
	align-items: center;
	gap: 0.5rem;
	color: var(--color-base);
	background-color: var(--color-button-bg);
	border-radius: var(--radius-md);
	width: 100%;
	padding: 0.5rem 0.75rem;
	text-align: left;

	&.expanded {
		border: 1px solid var(--color-divider);
		padding: 1rem;
	}
}

.avatar-text {
	margin: auto 0 auto 0.25rem;
	display: flex;
	flex-direction: column;
}

.text {
	width: 6rem;
	white-space: nowrap;
	overflow: hidden;
	text-overflow: ellipsis;
}

.accounts-text {
	display: flex;
	align-items: center;
	gap: 0.25rem;
	margin: 0;
}

.qr-code {
	background-color: white !important;
	border-radius: var(--radius-md);
}

.modal-body {
	display: flex;
	flex-direction: row;
	gap: var(--gap-lg);
	align-items: center;
	padding: var(--gap-xl);

	.modal-text {
		display: flex;
		flex-direction: column;
		gap: var(--gap-sm);
		width: 100%;

		h2,
		p {
			margin: 0;
		}

		.code-text {
			display: flex;
			flex-direction: row;
			gap: var(--gap-xs);
			align-items: center;

			.code {
				background-color: var(--color-bg);
				border-radius: var(--radius-md);
				border: solid 1px var(--color-button-bg);
				font-family: var(--mono-font);
				letter-spacing: var(--gap-md);
				color: var(--color-contrast);
				font-size: 2rem;
				font-weight: bold;
				padding: var(--gap-sm) 0 var(--gap-sm) var(--gap-md);
			}

			.btn {
				width: 2.5rem;
				height: 2.5rem;
			}
		}
	}
}

.button-row {
	display: flex;
	flex-direction: row;
}

.modal {
	position: absolute;
}

.code {
	color: var(--color-brand);
	padding: 0.05rem 0.1rem;
	// row not column
	display: flex;

	.card {
		background: var(--color-base);
		color: var(--color-contrast);
		padding: 0.5rem 1rem;
	}
}

.offline-section {
	border-top: 1px solid var(--color-divider);
	padding-top: 0.75rem;
	margin-top: 0.5rem;
}

.offline-label {
	margin: 0 0 0.5rem 0;
	font-size: 0.85rem;
	font-weight: 500;
	color: var(--color-secondary);
	text-transform: uppercase;
	letter-spacing: 0.5px;
}

.offline-input-row {
	display: flex;
	gap: 0.5rem;
	align-items: center;
}

.offline-username-input {
	flex: 1;
	padding: 0.5rem 0.75rem;
	border: 1px solid var(--color-button-bg);
	border-radius: var(--radius-md);
	background: var(--color-bg);
	color: var(--color-contrast);
	font-size: 0.9rem;

	&::placeholder {
		color: var(--color-secondary);
	}

	&:focus {
		outline: none;
		border-color: var(--color-brand);
	}
}
</style>

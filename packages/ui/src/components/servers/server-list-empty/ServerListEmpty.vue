<template>
	<div class="grid grid-cols-2 gap-8 items-center justify-center py-10 max-w-[760px]">
		<!-- Left column -->
		<div class="flex flex-col gap-8 items-start pr-8 shrink-0">
			<!-- Heading -->
			<div class="flex flex-col gap-2 items-start w-[300px]">
				<p class="text-3xl leading-9 font-semibold text-contrast">
					Nodecraft servers
				</p>
				<p class="text-base font-normal text-primary">
					Server hosting made easy
				</p>
			</div>

			<!-- Feature list -->
			<div class="flex flex-col gap-4 items-start w-full">
				<div class="flex gap-3 items-start">
					<div
						class="bg-surface-4 border border-solid border-surface-5 rounded-full shrink-0 size-8 flex items-center justify-center"
					>
						<PackageOpenIcon class="size-5 text-secondary" aria-hidden="true" />
					</div>
					<p class="m-0 text-base text-primary">
						{{ formatMessage(messages.noServersDescription) }}
					</p>
				</div>

				<div class="flex w-full flex-col gap-6">
					<div v-for="feature in features" :key="feature.key" class="flex items-start gap-4">
						<div
							class="feature-icon relative flex size-10 shrink-0 items-center justify-center overflow-hidden rounded-[0.875rem] border border-solid bg-surface-1 text-brand"
						>
							<div class="feature-icon-gradient absolute left-[-1px] top-[-1px] size-[6.25rem]" />
							<div class="feature-icon-shade absolute left-[-1px] top-[-1px] size-[6.25rem]" />
							<img
								:src="iconTexture"
								alt=""
								class="absolute left-1/2 top-1/2 h-[6.25rem] w-[9.8125rem] max-w-none -translate-x-1/2 -translate-y-1/2 object-cover opacity-40 mix-blend-luminosity"
							/>
							<component
								:is="feature.icon"
								class="feature-icon-glyph relative size-5"
								aria-hidden="true"
							/>
						</div>
						<div class="flex min-w-0 flex-col gap-0.5">
							<p class="m-0 text-lg font-semibold leading-6 text-contrast">
								{{ feature.title }}
							</p>
							<p class="m-0 text-sm leading-5 text-primary">
								{{ feature.description }}
							</p>
						</div>
					</div>
				</div>

				<div class="flex gap-3 items-start">
					<div
						class="bg-surface-4 border border-solid border-surface-5 rounded-full shrink-0 size-8 flex items-center justify-center overflow-hidden"
					>
						<GlobeIcon class="size-5 text-secondary" aria-hidden="true" />
					</div>
					<div class="flex flex-col gap-0.5">
						<p class="text-base font-semibold text-contrast">
							{{ formatMessage(messages.simpleSetupTitle) }}
						</p>
						<p class="text-base font-normal text-primary">
							{{ formatMessage(messages.simpleSetupDescription) }}
						</p>
					</div>
				</div>

				<div class="flex gap-3 items-start">
					<div
						class="bg-surface-4 border border-solid border-surface-5 rounded-full shrink-0 size-8 flex items-center justify-center overflow-hidden"
					>
						<UsersIcon class="size-5 text-secondary" aria-hidden="true" />
					</div>
					<div class="flex flex-col gap-0.5">
						<p class="text-base font-semibold text-contrast">
							{{ formatMessage(messages.playWithFriendsTitle) }}
						</p>
						<p class="text-base font-normal text-primary">
							Invite friends and get them set up right in the NyxRinth App.
						</p>
					</div>
				</div>
			</div>

			<!-- CTA section -->
			<div class="flex flex-col gap-6 items-start">
				<div class="flex flex-col gap-3 items-start">
					<Button type="colored" color="brand">
						<PlusIcon aria-hidden="true" />
						Download App (Coming soon)
					</Button>

				<p class="this">This is a separate app from the NyxRinth App.</p>
				</div>

			</div>

			<ServerListEmptyPreview />
		</div>

		<div v-if="!loggedIn" class="flex flex-col items-center gap-4 text-center">
			<p class="m-0 text-sm text-secondary">
				{{ formatMessage(messages.alreadyHaveServerLabel) }}
			</p>
			<Button @click="onClickSignIn?.()">
				<LogInIcon aria-hidden="true" />
				{{ formatMessage(messages.signInButton) }}
			</Button>
		</div>
	</div>
</template>

<script setup lang="ts">
import {
	GlobeIcon,
	LogInIcon,
	PackageOpenIcon,
	PlusIcon,
	RightArrowIcon,
	UsersIcon,
} from '@modrinth/assets'
import { computed } from 'vue'

import iconTexture from '#ui/assets/welcome/icon-texture.png'
import AutoLink from '#ui/components/base/AutoLink.vue'
import { Button } from '#ui/components/base/buttons'

import { defineMessages, useVIntl } from '../../../composables/i18n'
import ServerListEmptyPreview from './ServerListEmptyPreview.vue'

defineProps<{
	onClickNewServer?: () => void
	onClickSignIn?: () => void
	loggedIn?: boolean
}>()

const { formatMessage } = useVIntl()

const messages = defineMessages({
	modrinthHostingLabel: {
		id: 'servers.list-empty.modrinth-hosting-label',
		defaultMessage: 'Nodecraft Servers',
	},
	noServersDescription: {
		id: 'servers.list-empty.no-servers-description',
		defaultMessage: 'Install mods, invite friends, and play together all from the Nodecraft App.',
	},
	oneClickModInstallsTitle: {
		id: 'servers.list-empty.one-click-mod-installs-title',
		defaultMessage: 'One-click mod installs',
	},
	oneClickModInstallsDescription: {
		id: 'servers.list-empty.one-click-mod-installs-description',
		defaultMessage: 'Pick your favorite mods and we handle the rest.',
	},
	simpleSetupTitle: {
		id: 'servers.list-empty.simple-setup-title',
		defaultMessage: 'Simple setup',
	},
	simpleSetupDescription: {
		id: 'servers.list-empty.simple-setup-description',
		defaultMessage: 'Set up your server just like a single player world.',
	},
	playWithFriendsTitle: {
		id: 'servers.list-empty.play-with-friends-title',
		defaultMessage: 'Play with friends',
	},
	playWithFriendsDescription: {
		id: 'servers.list-empty.play-with-friends-description',
		defaultMessage: 'Invite friends and get them set up right in the Nodecraft App!',
	},
	newServerButton: {
		id: 'servers.list-empty.new-server-button',
		defaultMessage: 'New server',
	},
	learnMoreLink: {
		id: 'servers.list-empty.learn-more-link',
		defaultMessage: 'Learn more about Nodecraft Hosting',
	},
	alreadyHaveServerLabel: {
		id: 'servers.list-empty.already-have-server-label',
		defaultMessage: 'Already have a server?',
	},
	signInButton: {
		id: 'servers.list-empty.sign-in-button',
		defaultMessage: 'Sign in to Modrinth',
	},
})

const features = computed(() => [
	{
		key: 'one-click-mod-installs',
		icon: PackageOpenIcon,
		title: formatMessage(messages.oneClickModInstallsTitle),
		description: formatMessage(messages.oneClickModInstallsDescription),
	},
	{
		key: 'simple-setup',
		icon: GlobeIcon,
		title: formatMessage(messages.simpleSetupTitle),
		description: formatMessage(messages.simpleSetupDescription),
	},
	{
		key: 'play-with-friends',
		icon: UsersIcon,
		title: formatMessage(messages.playWithFriendsTitle),
		description: formatMessage(messages.playWithFriendsDescription),
	},
])
</script>

<style scoped>
.feature-icon {
	border-color: color-mix(in srgb, var(--color-text-primary) 10%, transparent);
	box-shadow:
		0 0 0 1px color-mix(in srgb, var(--color-brand) 30%, var(--surface-1)),
		var(--shadow-card),
		0 0 3.75rem color-mix(in srgb, var(--color-brand) 10%, transparent);
}

.this {
	margin: 0;
	font-size: 10px;
}

@keyframes drift-right {
	from {
		transform: translateX(-33%);
	}
	to {
		transform: translateX(33%);
	}
}

.feature-icon-shade {
	background: linear-gradient(
		-14deg,
		color-mix(in srgb, var(--color-green-950) 37%, transparent) 8%,
		transparent 86%
	);
}

.feature-icon-glyph {
	filter: drop-shadow(0 1px 1px color-mix(in srgb, var(--color-green-950) 12%, transparent));
}
</style>

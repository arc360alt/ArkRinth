<template>
	<div class="flex flex-col gap-4">
		<span class="font-semibold text-contrast">
			{{ setupTypeTitle }}
		</span>

		<!-- Instance flow options -->
		<template v-if="ctx.flowType === 'instance'">
			<div class="flex flex-col gap-3">
				<BigOptionButton
					:icon="OAIcon"
					title="OptiArk Base"
					description="Start from an OptiArk renderer preset and version."
					@click="setSetupType('optiark')"
				/>
				<BigOptionButton
					:icon="BoxesIcon"
					:title="formatMessage(messages.customSetupTitle)"
					:description="formatMessage(messages.customSetupDescription)"
					@click="setSetupType('custom')"
				/>
				<BigOptionButton
					:icon="PackageIcon"
					:title="formatMessage(messages.modpackBaseTitle)"
					:description="formatMessage(messages.modpackBaseDescription)"
					@click="setSetupType('modpack')"
				/>
				<BigOptionButton
					:icon="BoxImportIcon"
					:title="formatMessage(messages.importInstanceTitle)"
					:description="formatMessage(messages.importInstanceDescription)"
					@click="ctx.setImportMode()"
				/>
			</div>
			<span class="text-sm text-secondary">
				{{ formatMessage(messages.instanceDescription) }}
			</span>
		</template>

		<!-- World / Server onboarding flow options -->
		<template v-else>
			<div class="flex flex-col gap-3">
				<BigOptionButton
					:icon="PackageIcon"
					:title="formatMessage(messages.modpackBaseTitle)"
					:description="formatMessage(messages.modpackBaseDescription)"
					@click="setSetupType('modpack')"
				/>
				<BigOptionButton
					:icon="BoxesIcon"
					:title="formatMessage(messages.customSetupTitle)"
					:description="formatMessage(messages.customSetupDescription)"
					@click="setSetupType('custom')"
				/>
				<BigOptionButton
					:icon="BoxIcon"
					:title="formatMessage(messages.vanillaMinecraftTitle)"
					:description="formatMessage(messages.vanillaMinecraftDescription)"
					@click="setSetupType('vanilla')"
				/>
			</div>
		</template>
	</div>
</template>

<script setup lang="ts">
import { BoxesIcon, BoxIcon, BoxImportIcon, PackageIcon } from '@modrinth/assets'
import { defineComponent, h } from 'vue'

import { useDebugLogger } from '#ui/composables/debug-logger'

import BigOptionButton from '../../../base/BigOptionButton.vue'
import { injectCreationFlowContext } from '../creation-flow-context'

const debug = useDebugLogger('SetupTypeStage')
const ctx = injectCreationFlowContext()
const { setSetupType: _setSetupType } = ctx

const OAIcon = defineComponent({
	name: 'OAIcon',
	render: () =>
		h(
			'span',
			{
				class:
					'flex h-full w-full items-center justify-center font-minecraft text-secondary font-bold text-lg leading-none',
			},
			'OA',
		),
})

function setSetupType(type: 'modpack' | 'custom' | 'vanilla' | 'optiark') {
	debug('selected:', type)
	_setSetupType(type)
}
</script>

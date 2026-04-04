<template>
	<NewModal ref="modal" :header="formatMessage(messages.header)" fade="brand" max-width="520px">
		<p class="m-0 text-secondary">
			{{ formatMessage(messages.description, { fileName }) }}
		</p>

		<template #actions>
			<div class="flex justify-end gap-2">
				<ButtonStyled type="outlined">
					<button class="!border !border-surface-4" @click="handleCancel">
						{{ formatMessage(commonMessages.cancelButton) }}
					</button>
				</ButtonStyled>
				<ButtonStyled type="outlined">
					<button @click="handleSelect('resourcepack')">
						{{ formatMessage(messages.resourcepack) }}
					</button>
				</ButtonStyled>
				<ButtonStyled>
					<button @click="handleSelect('shaderpack')">
						{{ formatMessage(messages.shaderpack) }}
					</button>
				</ButtonStyled>
			</div>
		</template>
	</NewModal>
</template>

<script setup lang="ts">
import { ButtonStyled, commonMessages, defineMessages, NewModal, useVIntl } from '@modrinth/ui'
import { ref } from 'vue'

type ZipContentType = 'resourcepack' | 'shaderpack'

const { formatMessage } = useVIntl()

const messages = defineMessages({
	header: {
		id: 'app.instance.modpack-zip-type.header',
		defaultMessage: 'Choose zip content type',
	},
	description: {
		id: 'app.instance.modpack-zip-type.description',
		defaultMessage:
			'Where should "{fileName}" be installed? Select Resource Pack or Shader Pack.',
	},
	resourcepack: {
		id: 'app.instance.modpack-zip-type.resourcepack',
		defaultMessage: 'Resource pack',
	},
	shaderpack: {
		id: 'app.instance.modpack-zip-type.shaderpack',
		defaultMessage: 'Shader pack',
	},
})

const modal = ref<InstanceType<typeof NewModal>>()
const fileName = ref('')
let resolver: ((value: ZipContentType | null) => void) | null = null

function cleanup(value: ZipContentType | null) {
	if (!resolver) return
	const resolve = resolver
	resolver = null
	resolve(value)
}

function show(targetFileName: string) {
	fileName.value = targetFileName
	modal.value?.show()
	return new Promise<ZipContentType | null>((resolve) => {
		resolver = resolve
	})
}

function handleCancel() {
	modal.value?.hide()
	cleanup(null)
}

function handleSelect(value: ZipContentType) {
	modal.value?.hide()
	cleanup(value)
}

defineExpose({
	show,
})
</script>

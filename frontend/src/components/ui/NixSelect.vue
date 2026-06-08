<template>
  <label class="nix-form-group">
    <span v-if="label" class="nix-label">{{ label }}</span>
    <select
      class="nix-select"
      :value="modelValue"
      :disabled="disabled"
      :required="required"
      @change="emit('update:modelValue', ($event.target as HTMLSelectElement).value)"
    >
      <option v-if="placeholder" value="" disabled>{{ placeholder }}</option>
      <option
        v-for="option in options"
        :key="String(option.value)"
        :value="option.value"
      >
        {{ option.label }}
      </option>
    </select>
    <span v-if="error" class="nix-error-text">{{ error }}</span>
    <span v-else-if="hint" class="nix-helper-text">{{ hint }}</span>
  </label>
</template>

<script setup lang="ts">
type SelectOption = {
  label: string
  value: string | number
}

withDefaults(
  defineProps<{
    modelValue?: string | number
    label?: string
    placeholder?: string
    options: SelectOption[]
    hint?: string
    error?: string
    disabled?: boolean
    required?: boolean
  }>(),
  {
    disabled: false,
    required: false,
  },
)

const emit = defineEmits<{
  'update:modelValue': [value: string]
}>()
</script>

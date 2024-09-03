<script setup lang="ts">
import '@azure/ai-chat-components';
</script>

<template>
  <nav>AI Chat</nav>
  <azc-chat></azc-chat>
</template>

<style scoped>
nav {
  background: #333;
  color: #fff;
  padding: 16px;
  font-family:
    'Segoe UI',
    -apple-system,
    BlinkMacSystemFont,
    Roboto,
    'Helvetica Neue',
    sans-serif;
  font-size: 1.25rem;
}
azc-chat {
  display: block;
  max-width: 1024px;
  margin: 0 auto;
}
</style>

<script setup lang="ts">
import '@azure/ai-chat-components';
</script>

<template>
  <nav>
    <div class="container">
      <img class="logo" src="../favicon.png" alt="AI Chat logo" width="36" height="36" />
      AI Chat
      <div class="spacer"></div>
      <azc-auth type="status"></azc-auth>
    </div>
  </nav>
  <div class="container">
    <azc-auth>
      <azc-chat></azc-chat>
    </azc-auth>
  </div>
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
.container {
  max-width: 1024px;
  margin: 0 auto;
  display: flex;
  align-items: center;
}
.logo {
  margin-right: 8px;
}
.spacer {
  flex: 100 1 0;
}
azc-chat, azc-auth {
  flex: auto;
}
azc-auth[type="status"] {
  font-size: 16px;
}
</style>

<script lang="ts">
  import '@azure/ai-chat-components';
</script>

<main>
  <nav>AI Chat</nav>
  <azc-chat></azc-chat>
</main>

<style>
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

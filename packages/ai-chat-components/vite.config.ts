import { resolve } from 'node:path';
import { defineConfig } from 'vite';

// Expose environment variables to the client
process.env.VITE_BACKEND_API_URI = process.env.BACKEND_API_URI ?? '';
console.log(`Using chat API base URL: "${process.env.VITE_BACKEND_API_URI}"`);

export default defineConfig({
  build: {
    outDir: './dist',
    emptyOutDir: true,
    lib: {
      // eslint-disable-next-line unicorn/prefer-module
      entry: resolve(__dirname, 'src/index.ts'),
      name: 'index',
      fileName: 'index',
    },
  },
  server: {
    proxy: {
      '/chat': 'http://127.0.0.1:3000',
    },
  },
});

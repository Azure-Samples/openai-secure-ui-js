# 🤖 AI Chat: Reusable Chat Web Component

[![NPM version](https://img.shields.io/npm/v/@azure/ai-chat-components.svg)](https://www.npmjs.com/package/@azure/ai-chat-components)
[![Build Status](https://github.com/Azure-Samples/secure-ui-js/actions/workflows/ci.yml/badge.svg)](https://github.com/Azure-Samples/secure-ui-js/actions/workflows/ci.yml)
![Node version](https://img.shields.io/node/v/@azure/ai-chat-components.svg)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

This package provides a reusable web component that can be used to add an AI chatbot compatible with the [Microsoft AI Chat protocol specification](https://github.com/microsoft/ai-chat-protocol/tree/main/spec#readme) to any website.

## Installation

```bash
npm install @azure/ai-chat-components
```

## Usage

Once the package is installed, you can use the web component in your HTML code:

```html
<azc-chat options="{ apiUrl: 'http://your-chat-backend.com' }"></azc-chat>
```

Depending of the framework and build system you're using, you'll have to import the web component in your JS code in different ways. You can have a look at the various integrations examples here:

- [Vanilla HTML](https://github.com/Azure-Samples/secure-ui-js/tree/main/packages/webapp-html)
- [Angular](https://github.com/Azure-Samples/secure-ui-js/tree/main/packages/webapp-angular)
- [React](https://github.com/Azure-Samples/secure-ui-js/tree/main/packages/webapp-react)
- [Vue](https://github.com/Azure-Samples/secure-ui-js/tree/main/packages/webapp-vue)
- [Svelte](https://github.com/Azure-Samples/secure-ui-js/tree/main/packages/webapp-svelte)

## Development

This project uses [Vite](https://vitejs.dev/) as a frontend build tool, and [Lit](https://lit.dev/) as a web components library.

### Available Scripts

In the project directory, you can run:

#### `npm run dev`

To start the app in dev mode.\
Open [http://localhost:8000](http://localhost:8000) to view it in the browser.

#### `npm run build`

To build the web component for production to the `dist` folder.

#### `npm run build:website`

To build the demo website for the component to the `dist` folder.

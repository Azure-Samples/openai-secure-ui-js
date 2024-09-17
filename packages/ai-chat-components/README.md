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

Once the package is installed, you can use the web components in your HTML code:

```html
<!-- When not logged in, display login buttons -->
<azc-auth>
  <!-- Customizable chat user interface -->
  <azc-chat></azc-chat>
</azc-auth>
```

Depending of the framework and build system you're using, you'll have to import the web component in your JS code in different ways. You can have a look at the various integrations examples here:

- [Vanilla HTML](https://github.com/Azure-Samples/secure-ui-js/tree/main/packages/webapp-html)
- [Angular](https://github.com/Azure-Samples/secure-ui-js/tree/main/packages/webapp-angular)
- [React](https://github.com/Azure-Samples/secure-ui-js/tree/main/packages/webapp-react)
- [Vue](https://github.com/Azure-Samples/secure-ui-js/tree/main/packages/webapp-vue)
- [Svelte](https://github.com/Azure-Samples/secure-ui-js/tree/main/packages/webapp-svelte)

### Configuration

### `azc-auth` web component

This web component is used to manage the authentication state of the user. Depending on its configuration, it can display the login buttons, the login status or a logout button.

#### Attributes

- `options`: JSON options to configure the authentication providers and display labels. See [AuthComponentOptions](src/components/auth.ts#L22) for more details.
- `type`: Display type of the component. Can be `login` (default), `logout` or `status`.
- `loginRedirect`: URL to redirect to after a successful login.
- `logoutRedirect`: URL to redirect to after a successful logout.

#### Display types

- `<azc-auth type="login"></azc-auth>`: Shows the login buttons when the user is not logged in, or the slot content when the user is logged in.
  * Optional named slot `loader`: Shown while the authentication state is being retrieved.

- `<azc-auth type="status"></azc-auth>`: Shows the login status when the user is logged in, or a simple user icon when the user is not logged in.
  * Optional named slot `logout`: Displayed after the login status when the user is logged in. Defaults to a logout button.

- `<azc-auth type="logout"></azc-auth>`: Shows a logout button.

### `azc-chat` web component

This web component is used to display the chat interface. It can be used with or without the `azc-auth` component.

#### Attributes

- `options`: JSON options to configure the chat component. See [ChatComponentOptions](src/components/chat.ts#L19) for more details.
- `question`: Initial question to display in the chat.
- `messages`: Array of [messages](https://github.com/microsoft/ai-chat-protocol) to display in the chat.

By default, the component expect the [Chat API implementation](https://github.com/microsoft/ai-chat-protocol) to be available at `/api/chat`. You can change this URL by setting the `options.apiUrl` property.

## Development

This project uses [Vite](https://vitejs.dev/) as a frontend build tool, and [Lit](https://lit.dev/) as a web components library.

### Available Scripts

In the project directory, you can run:

#### `npm run start`

To start the app in dev mode, using the [Static Web Apps CLI emulator](https://learn.microsoft.com/azure/static-web-apps/static-web-apps-cli-emulator) to also run the API and authentication locally.

Open [http://localhost:4280](http://localhost:4280) to view it in the browser.

#### `npm run build`

To build the web component for production to the `dist` folder.

#### `npm run build:website`

To build the demo website for the component to the `dist` folder.

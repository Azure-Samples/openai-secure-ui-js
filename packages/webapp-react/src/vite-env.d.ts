/// <reference types="vite/client" />

import type * as React from 'react';
import { ChatComponent, AuthComponent } from '@azure/ai-chat-components';

declare global {
  namespace JSX {
    interface IntrinsicElements {
      ['azc-chat']: React.HTMLProps<ChatComponent>;
      ['azc-auth']: React.HTMLProps<AuthComponent>;
    }
  }
}

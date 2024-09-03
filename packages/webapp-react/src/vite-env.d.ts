/// <reference types="vite/client" />

import type * as React from 'react';
declare global {
  namespace JSX {
    interface IntrinsicElements {
      ['azc-chat']: React.DetailedHTMLProps<React.HTMLAttributes<HTMLElement>, HTMLElement>;
    }
  }
}

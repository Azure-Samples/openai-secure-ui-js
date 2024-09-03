import { CUSTOM_ELEMENTS_SCHEMA, Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterOutlet } from '@angular/router';
import '@azure/ai-chat-components';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [CommonModule, RouterOutlet],
  schemas: [CUSTOM_ELEMENTS_SCHEMA],
  template: `
    <nav>AI Chat</nav>
    <azc-chat></azc-chat>
  `,
  styles: [
    `
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
    `,
  ],
})
export class AppComponent {}

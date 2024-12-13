import React from 'react';
import './App.css';
import { AuthComponent, ChatComponent } from '@azure/ai-chat-components';
import { createComponent } from '@lit/react';

const Auth = createComponent({ tagName: 'azc-auth', elementClass: AuthComponent, react: React });
const Chat = createComponent({ tagName: 'azc-chat', elementClass: ChatComponent, react: React });

function App() {
  return (
    <>
      <nav>
        <div className="container">
          <img className="logo" src="./favicon.png" alt="AI Chat logo" width="36" height="36" />
          AI Chat
          <div className="spacer"></div>
          <Auth type="status"/>
        </div>
      </nav>
      <div className="container">
        <Auth>
          <Chat/>
        </Auth>
      </div>
    </>
  );
}

export default App;

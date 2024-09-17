import './App.css';
import '@azure/ai-chat-components';

function App() {
  return (
    <>
      <nav>
        <div className="container">
          <img className="logo" src="./favicon.png" alt="AI Chat logo" width="36" height="36" />
          AI Chat
          <div className="spacer"></div>
          <azc-auth type="status"></azc-auth>
        </div>
      </nav>
      <div className="container">
        <azc-auth>
          <azc-chat></azc-chat>
        </azc-auth>
      </div>
    </>
  );
}

export default App;

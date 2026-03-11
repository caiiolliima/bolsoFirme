import React from 'react';
import ReactDOM from 'react-dom/client';

function App() {
  return (
    <div>
      <h1>BolsoFirme</h1>
      <p>App de controle financeiro pessoal</p>
    </div>
  );
}

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
);

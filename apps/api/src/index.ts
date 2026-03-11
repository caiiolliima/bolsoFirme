import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';

dotenv.config();

const app = express();
const PORT = process.env.PORT ?? 3000;

app.use(cors());
app.use(express.json());

app.get('/health', (_req, res) => {
  res.json({ status: 'ok', app: 'bolsofirme-api' });
});

app.listen(PORT, () => {
  console.log(`[api] Server running on http://localhost:${PORT}`);
});

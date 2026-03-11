const fs = require('fs');
const path = require('path');

const dirs = ['apps/api', 'apps/web', 'packages/shared'];
const basePath = 'C:\\Users\\caioa\\Desktop\\bolsoFirme';

dirs.forEach(d => {
  const fullPath = path.join(basePath, d);
  fs.mkdirSync(fullPath, { recursive: true });
  console.log(`Created: ${fullPath}`);
});

console.log('Done');

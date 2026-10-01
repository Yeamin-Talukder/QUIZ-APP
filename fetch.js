const fs = require('fs');
const https = require('https');

const categories = [9, 10, 23, 17, 25, 28];
const difficulties = ['easy', 'medium', 'hard'];
const results = [];

async function fetchQuestions(categoryId, difficulty, retries = 3) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'opentdb.com',
      port: 443,
      path: `/api.php?amount=50&category=${categoryId}&difficulty=${difficulty}&type=multiple`,
      method: 'GET',
      family: 4, // force IPv4
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
      }
    };

    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          const json = JSON.parse(data);
          if (json.results) {
            const parsed = json.results.map(q => ({
               ...q,
               category_id: categoryId.toString()
            }));
            resolve(parsed);
          } else {
            resolve([]);
          }
        } catch (e) {
          console.error("JSON parse error:", e);
          resolve([]);
        }
      });
    }).on('error', async (err) => {
      console.error(`Error fetching ${categoryId} ${difficulty}:`, err.message);
      if (retries > 0) {
        console.log(`Retrying... (${retries} left)`);
        await new Promise(r => setTimeout(r, 2000));
        resolve(await fetchQuestions(categoryId, difficulty, retries - 1));
      } else {
        resolve([]);
      }
    });

    req.setTimeout(15000, () => {
      req.destroy(new Error('Request timed out'));
    });
    
    req.end();
  });
}

async function run() {
  for (let cat of categories) {
    for (let diff of difficulties) {
      console.log(`Fetching category ${cat} | difficulty ${diff}`);
      const qs = await fetchQuestions(cat, diff);
      results.push(...qs);
      console.log(`Fetched ${qs.length} questions`);
      await new Promise(r => setTimeout(r, 5000)); // wait 5 seconds
    }
  }
  
  if (!fs.existsSync('assets')) fs.mkdirSync('assets');
  fs.writeFileSync('assets/questions.json', JSON.stringify(results, null, 2));
  console.log('Done, total:', results.length);
}

run();

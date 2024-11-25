// server.js

const express = require('express');
const multer = require('multer');
const axios = require('axios');
const cors = require('cors');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = 3000;

// Enable CORS for all routes (Adjust as needed)
app.use(cors());

// Configure multer for file uploads
const upload = multer({ dest: 'uploads/' });

// Endpoint to handle file conversion
app.post('/convert', upload.single('file'), async (req, res) => {
  const { target_format } = req.body;
  const file = req.file;

  if (!file || !target_format) {
    return res.status(400).json({ message: 'File and target format are required.' });
  }

  try {
    // Read the uploaded file
    const fileData = fs.readFileSync(file.path);
    const base64File = Buffer.from(fileData).toString('base64');

    // Prepare the request payload for api2convert
    const payload = {
      Parameters: [
        {
          Name: 'Files',
          FileValues: [
            {
              Name: file.originalname,
              Data: base64File,
            },
          ],
        },
        {
          Name: 'TargetFormat',
          Value: target_format,
        },
        {
          Name: 'StoreFile',
          Value: true,
        },
      ],
    };

    // Send the POST request to api2convert
    const response = await axios.post('https://v2.api2convert.com/convert', payload, {
      headers: {
        'Content-Type': 'application/json',
        Authorization: 'Bearer YOUR_API_KEY', // Replace with your actual API key
      },
    });

    // Extract the download URL from the response
    const downloadUrl = response.data.Files[0].Url;

    // Optional: Clean up the uploaded file
    fs.unlinkSync(file.path);

    // Send the download URL back to the Flutter app
    res.json({ downloadUrl });
  } catch (error) {
    console.error('Error during conversion:', error.message);
    res.status(500).json({ message: 'File conversion failed.', error: error.message });
  }
});

// Start the server
app.listen(PORT, () => {
  console.log(`ConvertAPI Proxy Server is running on http://localhost:${PORT}`);
});

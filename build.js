#!/usr/bin/env node

// Simple build script for Vercel deployment
console.log('🚀 SetupX Build Script');
console.log('=====================');
console.log('✅ Checking files...');

const fs = require('fs');
const path = require('path');

// Check if index.html exists
if (fs.existsSync('index.html')) {
    console.log('✅ index.html found');
} else {
    console.log('❌ index.html not found');
    process.exit(1);
}

// Check if vercel.json exists
if (fs.existsSync('vercel.json')) {
    console.log('✅ vercel.json found');
} else {
    console.log('❌ vercel.json not found');
    process.exit(1);
}

// Check if package.json exists
if (fs.existsSync('package.json')) {
    console.log('✅ package.json found');
} else {
    console.log('❌ package.json not found');
    process.exit(1);
}

console.log('🎉 Build completed successfully!');
console.log('Ready for Vercel deployment');

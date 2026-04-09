import { chromium } from 'playwright';
import { PDFDocument } from 'pdf-lib';
import { writeFileSync } from 'fs';
import { resolve } from 'path';

const htmlPath = process.argv[2];
if (!htmlPath) { console.error('Usage: node export-slides.mjs <path-to-html> [output.pdf]'); process.exit(1); }

const outputPath = process.argv[3] || htmlPath.replace(/\.html$/, '.pdf');
const absPath = resolve(htmlPath);

const browser = await chromium.launch();
const context = await browser.newContext({
  viewport: { width: 960, height: 540 },
  deviceScaleFactor: 2,
});
const page = await context.newPage();
await page.goto('file://' + absPath, { waitUntil: 'networkidle' });
await page.waitForTimeout(2000);

// Hide UI elements
await page.evaluate(() => {
  ['.nav-dots', '.progress-bar', '.edit-hotzone', '.edit-toggle', '.edit-banner'].forEach(sel => {
    const el = document.querySelector(sel);
    if (el) el.style.display = 'none';
  });
});

const slideCount = await page.evaluate(() => document.querySelectorAll('.slide').length);
console.log(`Found ${slideCount} slides`);

// Screenshot each slide
const screenshots = [];
for (let i = 0; i < slideCount; i++) {
  await page.evaluate((idx) => {
    const slides = document.querySelectorAll('.slide');
    slides[idx].scrollIntoView({ behavior: 'instant' });
    slides[idx].classList.add('visible');
  }, i);
  await page.waitForTimeout(400);
  const buf = await page.screenshot({ type: 'png' });
  screenshots.push(buf);
  console.log(`  Captured slide ${i + 1}/${slideCount}`);
}

await browser.close();

// Build PDF from screenshots
const pdfDoc = await PDFDocument.create();
for (const png of screenshots) {
  const img = await pdfDoc.embedPng(png);
  const pageWidth = 960;
  const pageHeight = 540;
  const pdfPage = pdfDoc.addPage([pageWidth, pageHeight]);
  pdfPage.drawImage(img, { x: 0, y: 0, width: pageWidth, height: pageHeight });
}

const pdfBytes = await pdfDoc.save();
writeFileSync(outputPath, pdfBytes);
console.log(`\nPDF saved to: ${outputPath} (${(pdfBytes.length / 1024 / 1024).toFixed(1)} MB)`);

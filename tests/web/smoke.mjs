// Exercise the shipped WebAssembly bundle, including real canvas input.
import assert from 'node:assert/strict';
import { createServer } from 'node:http';
import { readFile, mkdir, writeFile } from 'node:fs/promises';
import { chromium } from 'playwright';

const bundle = new URL('../../zig-out/web/', import.meta.url);
const artifacts = new URL('../../.tmp/web-check/', import.meta.url);
await mkdir(artifacts, { recursive: true });
const server = createServer(async (request, response) => {
  const name = new URL(request.url, 'http://localhost').pathname.slice(1) || 'index.html';
  if (!['index.html', 'index.js', 'index.wasm'].includes(name)) {
    response.writeHead(404).end();
    return;
  }
  try {
    response.setHeader('Content-Type', name.endsWith('.wasm') ? 'application/wasm' : name.endsWith('.js') ? 'text/javascript' : 'text/html');
    response.end(await readFile(new URL(name, bundle)));
  } catch (error) {
    response.writeHead(500).end(String(error));
  }
});
await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
let browser;
try {
  browser = await chromium.launch({
    executablePath: process.env.CHROMIUM_PATH || undefined,
    args: ['--autoplay-policy=no-user-gesture-required', '--enable-unsafe-swiftshader', '--mute-audio'],
  });
  for (const rejectShader of [false, true]) {
    const page = await browser.newPage({ viewport: { width: 1024, height: 768 } });
    const messages = [];
    const errors = [];
    page.on('console', message => messages.push(message.text()));
    page.on('pageerror', error => {
      if (!errors.includes(error.message)) {
        errors.push(error.message);
        console.error(error);
      }
    });
    await page.addInitScript(reject => {
      window.sceneDraws = 0;
      for (const context of [WebGLRenderingContext, WebGL2RenderingContext]) {
        for (const name of ['drawArrays', 'drawElements']) {
          const original = context.prototype[name];
          context.prototype[name] = function (...args) {
            window.sceneDraws++;
            return original.apply(this, args);
          };
        }
        const source = context.prototype.shaderSource;
        context.prototype.shaderSource = function (shader, code) {
          return source.call(this, shader, reject && code.includes('chromaFactor') ? 'invalid shader' : code);
        };
      }
    }, rejectShader);
    await page.goto(`http://127.0.0.1:${server.address().port}`);
    const canvas = page.locator('canvas');
    const advance = async () => {
      const previous = await page.evaluate(() => window.sceneDraws);
      try {
        await page.waitForFunction(start => window.sceneDraws > start + 100, previous, { timeout: 15000 });
      } catch (error) {
        await writeFile(new URL(`console-${rejectShader}.log`, artifacts), messages.join('\n'));
        console.error(messages.slice(-20).join('\n'));
        throw error;
      }
      assert.deepEqual(errors, [], 'the application must keep rendering without traps');
    };
    const click = async (x, y) => {
      await canvas.click({ position: { x, y }, delay: 100 });
      await advance();
    };
    await advance();
    // Save, replace and duplicate a preset: the old whole-library rollback
    // exhausted the web stack here even though compilation succeeded.
    await click(522, 36);
    await canvas.screenshot({ path: new URL(`presets-before-${rejectShader}.png`, artifacts).pathname });
    await click(95, 202);
    await click(95, 202);
    await click(245, 202);
    await canvas.screenshot({ path: new URL(`presets-after-${rejectShader}.png`, artifacts).pathname });
    await click(120, 286); // Load the saved look.
    await click(948, 36); // Settings.
    await click(76, 286); // Change the FPS limit before resetting it.
    await click(165, 146); // Reset all settings.
    await advance();
    await canvas.screenshot({ path: new URL(`reset-${rejectShader}.png`, artifacts).pathname });
    // A real dropped PCM file also drives the analysis stack on the main loop.
    const wav = Buffer.alloc(44 + 44100 * 2 * 2);
    wav.write('RIFF'); wav.writeUInt32LE(wav.length - 8, 4); wav.write('WAVEfmt ', 8);
    wav.writeUInt32LE(16, 16); wav.writeUInt16LE(1, 20); wav.writeUInt16LE(1, 22);
    wav.writeUInt32LE(44100, 24); wav.writeUInt32LE(88200, 28);
    wav.writeUInt16LE(2, 32); wav.writeUInt16LE(16, 34); wav.write('data', 36);
    wav.writeUInt32LE(wav.length - 44, 40);
    for (let i = 0; i < 88200; i++) wav.writeInt16LE(Math.round(2000 * Math.sin(i * Math.PI * 2 * 440 / 44100)), 44 + i * 2);
    await canvas.evaluate((element, encoded) => {
      const data = Uint8Array.from(atob(encoded), c => c.charCodeAt(0));
      const transfer = new DataTransfer();
      const file = new File([data], 'smoke.wav', { type: 'audio/wav' });
      transfer.items.add(file);
      // Supply the directory-entry wrapper absent from synthetic file drops.
      const original = DataTransferItem.prototype.webkitGetAsEntry;
      DataTransferItem.prototype.webkitGetAsEntry = function () {
        const dropped = this.getAsFile();
        return { fullPath: `/${dropped.name}`, isFile: true, file: done => done(dropped) };
      };
      try {
        element.dispatchEvent(new DragEvent('drop', { bubbles: true, cancelable: true, dataTransfer: transfer }));
      } finally {
        DataTransferItem.prototype.webkitGetAsEntry = original;
      }
    }, wav.toString('base64'));
    await advance();
    assert.ok(messages.some(message => message.includes('smoke.wav') && message.includes('successfully')), messages.join('\n'));
    await canvas.screenshot({ path: new URL(`audio-${rejectShader}.png`, artifacts).pathname });
    const fallback = messages.some(message => message.includes('post-processing shader unavailable'));
    assert.equal(fallback, rejectShader, 'the post shader should work, with a graceful fallback only when rejected');
    if (!rejectShader) assert.ok(!messages.some(message => /SHADER:.*(failed|error)/i.test(message)), messages.join('\n'));
    await writeFile(new URL(`console-${rejectShader}.log`, artifacts), messages.join('\n'));
    await page.close();
    console.log(`Web startup, presets, reset and dropped audio passed (shader fallback: ${rejectShader}).`);
  }
} finally {
  await browser?.close();
  await new Promise(resolve => server.close(resolve));
}

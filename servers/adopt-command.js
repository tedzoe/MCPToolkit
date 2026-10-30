#!/usr/bin/env node
// Parse a deliberately small command syntax into argv. Never invoke a shell.
const { spawnSync } = require('node:child_process');
const path = require('node:path');
function parse(text) {
  if (typeof text !== 'string' || /[\x00-\x1f\x7f;|&`<>\\]/.test(text) ||
      /\$/.test(text.replace(/\$\{[A-Z_][A-Z0-9_]*\}/g, ''))) {
    throw new Error('Use one line of plain arguments; only ${ENV_VAR} references are allowed.');
  }
  const args = [];
  let word = '', quote = '', started = false;
  for (const ch of text) {
    if (quote) {
      if (ch === quote) quote = ''; else word += ch;
    } else if (ch === '"' || ch === "'") {
      quote = ch; started = true;
    } else if (ch === ' ') {
      if (started) { args.push(word); word = ''; started = false; }
    } else { word += ch; started = true; }
  }
  if (quote) throw new Error('Unclosed quote.');
  if (started) args.push(word);
  if (!/^[a-z0-9][a-z0-9-]*$/.test(args[0] || '') ||
      !['stdio', 'http'].includes(args[1]) || !args[2]) {
    throw new Error('Expected <name> stdio|http <command-or-url> [arguments].');
  }
  return args;
}
module.exports = { parse };
if (require.main === module) {
  try {
    const [mode, text] = process.argv.slice(2);
    if (!['--check', '--run', '--yes'].includes(mode)) throw new Error('Invalid mode.');
    const args = parse(text);
    if (mode !== '--check') {
      const result = spawnSync('bash', [path.join(__dirname, 'adhoc.sh'), ...args,
        ...(mode === '--yes' ? ['--yes'] : [])], { stdio: 'inherit' });
      if (result.error) throw result.error;
      process.exitCode = result.status === null ? 1 : result.status;
    }
  } catch (error) { console.error(`Adoption refused: ${error.message}`); process.exitCode = 2; }
}

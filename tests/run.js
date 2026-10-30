#!/usr/bin/env node
// Offline checks: no credentials, assistant requests, package installs or network calls.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const os = require('node:os');
const { spawnSync } = require('node:child_process');
const { parse } = require('../servers/adopt-command.js');
const root = path.resolve(__dirname, '..');
let passed = 0;
function test(name, fn) { fn(); passed++; console.log(`PASS ${name}`); }
function exec(command, args, options = {}) {
  const p = spawnSync(command, args, { encoding: 'utf8', timeout: 20000, ...options });
  if (p.error) throw p.error;
  return p;
}
function walk(dir) {
  return fs.readdirSync(dir, { withFileTypes: true }).flatMap(e => {
    if (['.git', '.cache', '.handoff', 'outputs', 'evidence', 'node_modules'].includes(e.name)) return [];
    const p = path.join(dir, e.name);
    return e.isDirectory() ? walk(p) : [p];
  });
}
test('shell syntax, executable entry points and JSON', () => {
  for (const f of walk(root)) {
    if (f.endsWith('.sh')) {
      const p = exec('bash', ['-n', f]); assert.equal(p.status, 0, `${f}: ${p.stderr}`);
      if (!['_lib.sh', 'adhoc-runtime.sh'].includes(path.basename(f))) assert.ok(fs.statSync(f).mode & 0o111, `${f} needs executable permission`);
    }
    if (f.endsWith('.json')) JSON.parse(fs.readFileSync(f, 'utf8'));
  }
});
test('candidate public files have no local dependencies or obvious credentials', () => {
  const p = exec('git', ['ls-files', '--cached', '--others', '--exclude-standard', '-z'], { cwd: root });
  const candidates = fs.existsSync(path.join(root, '.git'))
    ? (assert.equal(p.status, 0, p.stderr), p.stdout.split('\0').filter(Boolean))
    : walk(root).map(f => path.relative(root, f)).filter(rel =>
      !(rel !== '.env.example' && /^\.env(?:\.|$)/.test(rel)) &&
      !/(?:last-result\.json|settings\.local\.json)$/.test(rel) &&
      !['drills/log.md', 'drills/events.log', '.claude/commands/run.md', '.DS_Store'].includes(rel));
  for (const rel of new Set(candidates)) {
    assert.ok(!/(^|\/)(\.env(?:\..*)?|[^/]+\.(?:pem|key|p12|pfx))$/.test(rel) || rel === '.env.example', `private file: ${rel}`);
    assert.ok(!/^(\.handoff|\.cache|evidence|outputs)\//.test(rel), `local artifact: ${rel}`);
    const f = path.join(root, rel);
    if (!fs.existsSync(f)) { assert.ok(!fs.lstatSync(f, { throwIfNoEntry: false })?.isSymbolicLink(), `broken link: ${rel}`); continue; }
    assert.ok(!fs.lstatSync(f).isSymbolicLink(), `nonportable link: ${rel}`);
    const text = fs.readFileSync(f, 'utf8');
    assert.ok(!/\/(?:Users|home)\/[a-zA-Z0-9._-]+\//.test(text), `private home path: ${rel}`);
    assert.ok(!/-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----/.test(text), `private key: ${rel}`);
    assert.ok(!/\b(?:ghp_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{30,}|sk-ant-[A-Za-z0-9_-]{20,})/.test(text), `credential: ${rel}`);
  }
});
test('adoption parser preserves quoted args and literal env references', () => {
  assert.deepEqual(parse('sample http https://example.com/mcp --header \'Authorization: Bearer ${API_KEY}\''),
    ['sample', 'http', 'https://example.com/mcp', '--header', 'Authorization: Bearer ${API_KEY}']);
  assert.deepEqual(parse('sample stdio uvx package==1.2.3 --query "two words"'),
    ['sample', 'stdio', 'uvx', 'package==1.2.3', '--query', 'two words']);
});
test('adoption parser rejects original injection and shell expansion paths', () => {
  for (const suffix of ['\nprintf INJECTED', '; echo x', ' | cat', ' $(id)', ' `id`', ' $HOME', ' $((2+2))', '\rprintf x', '\targ', ' "unclosed', ' \\x', ' > file']) {
    assert.throws(() => parse('probe stdio echo harmless' + suffix), suffix);
  }
  assert.throws(() => parse('../probe stdio echo'));
});

const temp = fs.mkdtempSync(path.join(os.tmpdir(), 'mcp-toolkit-test-'));
const kit = path.join(temp, 'checkout with spaces');
const bin = path.join(temp, 'bin'); fs.mkdirSync(bin);
fs.cpSync(path.join(root, 'servers'), path.join(kit, 'servers'), { recursive: true });
fs.copyFileSync(path.join(root, '.mcp.json'), path.join(kit, '.mcp.json'));
const env = { ...process.env, PATH: bin + path.delimiter + process.env.PATH };
for (const k of Object.keys(env)) if (/(?:_KEY|_TOKEN|_PAT|USER_AGENT)$/.test(k) || ['MCP_ALLOWED_TOOLS', 'DEMO_MODEL'].includes(k)) delete env[k];
function run(script, args = [], extra = {}) { return exec('bash', [path.join(kit, 'servers', script), ...args], { cwd: kit, env: { ...env, ...extra } }); }
function put(rel, text) { const p = path.join(kit, rel); fs.mkdirSync(path.dirname(p), { recursive: true }); fs.writeFileSync(p, text, { mode: 0o755 }); }
fs.writeFileSync(path.join(bin, 'uvx'), '#!/usr/bin/env bash\nexit 0\n', { mode: 0o755 });
fs.writeFileSync(path.join(bin, 'claude'), '#!/usr/bin/env node\nconsole.log(JSON.stringify(process.argv.slice(2)));\n', { mode: 0o755 });
fs.writeFileSync(path.join(bin, 'npx'), `#!/usr/bin/env node
const a=process.argv.slice(2), mode=process.env.MOCK_MODE||'pass';
const method=a[a.indexOf('--method')+1], tool=a[a.indexOf('--tool-name')+1];
const json=a.includes('--format');
let body, rc=0;
if(method==='tools/list') {
 if(mode==='oauth') process.exit(3);
 if(mode==='discovery-fail') process.exit(4);
 body={tools:[{name:'search_items',inputSchema:{type:'object',required:['query'],properties:{query:{type:'string'}}}}]};
} else if(tool==='tool_does_not_exist') {
 if(mode==='negative-fail') body={content:[{type:'text',text:'incorrectly accepted'}]};
 else {body={isError:true,code:'tool_not_found'};rc=5;}
} else if(a.includes('--tool-args-json')) {
 if(mode==='negative-fail') body={content:[{type:'text',text:'incorrectly accepted'}]};
 else {body={isError:true,content:[{type:'text',text:'query required'}]};rc=5;}
} else if(mode==='call-fail') {body={isError:true,content:[{type:'text',text:'failed'}]};rc=5;}
else body={content:[{type:'text',text:'fixture result'}]};
console.log(JSON.stringify(json?{result:body}:body));process.exit(rc);
`, { mode: 0o755 });
try {
  test('test runner rejects unknown server, crash and missing result', () => {
    assert.notEqual(run('test-all.sh', ['no-such-server']).status, 0);
    put('servers/probe/test.sh', '#!/usr/bin/env bash\nexit 42\n');
    assert.notEqual(run('test-all.sh', ['probe']).status, 0);
    put('servers/probe/test.sh', '#!/usr/bin/env bash\necho no-result\n');
    assert.notEqual(run('test-all.sh', ['probe']).status, 0);
    put('servers/probe/test.sh', '#!/usr/bin/env bash\necho "probe FAIL fixture"\necho "probe PASS tools=1 fixture"\n');
    assert.notEqual(run('test-all.sh', ['probe']).status, 0);
    put('servers/probe/test.sh', '#!/usr/bin/env bash\necho "probe PASS tools=1 fixture"\n');
    assert.equal(run('test-all.sh', ['probe']).status, 0);
  });
  test('launcher keeps approval/default model and accepts only exact tool overrides', () => {
    let p = run('claude.sh', ['hello']); assert.equal(p.status, 0);
    let args = JSON.parse(p.stdout); assert.ok(!args.includes('--allowedTools')); assert.ok(!args.includes('--model'));
    p = run('claude.sh', ['hello'], { DEMO_MODEL: 'available-model', MCP_ALLOWED_TOOLS: 'mcp__fetch__fetch' });
    assert.equal(p.status, 0); args = JSON.parse(p.stdout); assert.ok(args.includes('available-model')); assert.ok(args.includes('mcp__fetch__fetch'));
    assert.notEqual(run('claude.sh', [], { MCP_ALLOWED_TOOLS: 'mcp__fetch' }).status, 0);
    assert.notEqual(run('claude.sh', [], { MCP_ALLOWED_TOOLS: 'mcp__fetch__*' }).status, 0);
  });
  test('missing SEC contact is an explicit skip, not a crash or readiness PASS', () => {
    const p = run('test-all.sh', ['sec-edgar']); assert.equal(p.status, 0, p.stderr); assert.match(p.stdout, /KEY-NEEDED/);
    assert.notEqual(run('preflight.sh', ['--live', 'sec-edgar']).status, 0);
  });
  test('adoption rejects incomplete options, malformed names, raw credentials and shell headers', () => {
    for (const args of [
      ['bad', 'http', 'https://example.com/mcp', '--env'],
      ['../bad', 'http', 'https://example.com/mcp', '--yes'],
      ['bad', 'http', 'https://example.com/?key=value', '--yes'],
      ['bad', 'http', 'https://example.com/mcp', '--header', 'Authorization: raw-value', '--yes'],
      ['bad', 'http', 'https://example.com/mcp', '--header', 'Authorization: ${KEY}$(id)', '--yes'],
      ['bad', 'stdio', 'uvx', 'unpinned-package', '--yes']
    ]) assert.notEqual(run('adhoc.sh', args).status, 0, args.join(' '));
  });
  test('adopted data stays literal and all real/negative gates pass', () => {
    const p = run('adhoc.sh', ['sample', 'http', 'https://example.com/mcp', '--query', 'literal $(printf injected)', '--yes']);
    assert.equal(p.status, 0, p.stdout + p.stderr); assert.match(p.stdout, /Adopted and tested/);
    const data = JSON.parse(fs.readFileSync(path.join(kit, 'servers/sample/config.json')));
    assert.ok(data.call.includes('query=literal $(printf injected)'));
    assert.equal(run('negtest.sh', ['sample']).status, 0);
    assert.equal(run('test-all.sh', ['sample']).status, 0);
    const failure = run('negtest.sh', ['sample'], { MOCK_MODE: 'negative-fail' });
    assert.notEqual(failure.status, 0, failure.stdout);
  });
  test('adoption fails on discovery, real-call and negative-test failures', () => {
    for (const mode of ['discovery-fail', 'call-fail', 'negative-fail']) {
      const p = run('adhoc.sh', [mode, 'http', 'https://example.com/mcp', '--yes'], { MOCK_MODE: mode });
      assert.notEqual(p.status, 0, p.stdout + p.stderr); assert.doesNotMatch(p.stdout, /Adopted and tested/);
    }
  });
  test('header variables expand as data, generated config never contains the value', () => {
    const p = run('adhoc.sh', ['headers', 'http', 'https://example.com/mcp', '--header', 'Authorization: Bearer ${PROVIDER_KEY}', '--yes'], { PROVIDER_KEY: 'fixture $(printf literal)' });
    assert.equal(p.status, 0, p.stdout + p.stderr);
    const text = fs.readFileSync(path.join(kit, 'servers/headers/config.json'), 'utf8');
    assert.ok(text.includes('${PROVIDER_KEY}')); assert.ok(!text.includes('fixture'));
    const q = exec('bash', ['-c', '. servers/_lib.sh; expand_refs \'Authorization: Bearer ${PROVIDER_KEY}\''], { cwd: kit, env: { ...env, PROVIDER_KEY: 'fixture $(printf literal)' } });
    assert.equal(q.stdout, 'Authorization: Bearer fixture $(printf literal)');
  });
  test('OAuth stays explicitly skipped and cannot pass live readiness', () => {
    const p = run('adhoc.sh', ['oauth', 'http', 'https://example.com/mcp', '--yes'], { MOCK_MODE: 'oauth' });
    assert.equal(p.status, 0, p.stdout + p.stderr); assert.match(p.stdout, /NOT verified/);
    const q = run('test-all.sh', ['oauth']); assert.equal(q.status, 0); assert.match(q.stdout, /OAUTH/);
    assert.notEqual(run('preflight.sh', ['--live', 'oauth']).status, 0);
  });
  test('retirement validates names and removes adopted servers from active location', () => {
    assert.notEqual(run('adhoc.sh', ['--retire', '../sample']).status, 0);
    assert.equal(run('adhoc.sh', ['--retire', 'sample']).status, 0);
    assert.ok(fs.existsSync(path.join(kit, 'servers/_retired/sample/config.json')));
  });
} finally { fs.rmSync(temp, { recursive: true, force: true }); }
console.log(`\n${passed} offline checks passed`);

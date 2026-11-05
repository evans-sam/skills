import { expect, mock, test } from 'claude-code/testing'
import type { TestBody } from 'claude-code/testing'

type On = Parameters<TestBody>[1]

const MARK = '<testing-guidance>'
const TOOL = 'mcp__testing-guidance__set_guidance'
const COMPOSER = { kind: 'composer' } as const

const notesOf = (session: ReturnType<typeof mock.session>) =>
  session.appended().filter(row => row.door === 'note')

const noteText = (session: ReturnType<typeof mock.session>, index = 0) =>
  JSON.stringify(notesOf(session)[index]?.message.content ?? '')

// The engine beneath a session start: the two registrations it answers.
const engineForStart = (on: On) => {
  on('command.register', () => ({ value: { command: 'testing-guidance' } }))
  on('tool.register', () => ({ value: { tool: 'mcp__testing-guidance__set_guidance' } }))
  on('session.start', (_, e) => ({ cwd: e.cwd }))
}

const command = (args: string) => ({
  command: 'testing-guidance',
  args,
  origin: COMPOSER,
  presentation: { isFullscreen: false, columns: 80 },
})

test('a prompt about tests appends the guidance once', async ($, on) => {
  const session = mock.session(on)
  mock.store(on)
  engineForStart(on)
  on('prompt.submit', (_, e) => ({ text: e.text }))
  on('ui.toast', () => ({ value: undefined }))
  await $.session.start({ cwd: '/', surface: 'desktop', isInteractive: true })

  await $.prompt.submit({ text: 'write unit tests for the copay calculator', wait: false, origin: COMPOSER })
  await $.prompt.submit({ text: 'now add an integration test for the endpoint', wait: false, origin: COMPOSER })

  expect(notesOf(session).length).toBe(1)
  expect(noteText(session)).toContain(MARK)
  expect(noteText(session)).toContain('Bundled default guidance')
})

test('an unrelated prompt appends nothing', async ($, on) => {
  const session = mock.session(on)
  mock.store(on)
  engineForStart(on)
  on('prompt.submit', (_, e) => ({ text: e.text }))
  await $.session.start({ cwd: '/', surface: 'desktop', isInteractive: true })

  await $.prompt.submit({ text: 'rename the copay helper and update its callers', wait: false, origin: COMPOSER })

  expect(notesOf(session).length).toBe(0)
})

test('a slash command is not read as a prompt about tests', async ($, on) => {
  const session = mock.session(on)
  mock.store(on)
  on('prompt.submit', (_, e) => ({ text: e.text }))

  await $.prompt.submit({
    text: '/commit add the tests',
    wait: false,
    origin: COMPOSER,
    command: { name: 'commit', args: 'add the tests' },
  })

  expect(notesOf(session).length).toBe(0)
})

test('the first write to a test file is refused and loads the guidance', async ($, on) => {
  const session = mock.session(on)
  mock.store(on)
  on('tool.call', () => ({ result: {} }))

  const first = await $.tool.call({ tool: 'Write', file_path: '/repo/src/copay.spec.ts', content: 'x' })
  const refused = 'deny' in first || ('isError' in first && first.isError === true)
  expect(refused).toBe(true)
  expect(notesOf(session).length).toBe(1)

  const second = await $.tool.call({ tool: 'Write', file_path: '/repo/src/copay.spec.ts', content: 'x' })
  expect('deny' in second).toBe(false)
  expect(notesOf(session).length).toBe(1)
})

test('a write to a source file passes untouched', async ($, on) => {
  const session = mock.session(on)
  mock.store(on)
  on('tool.call', () => ({ result: {} }))

  const ran = await $.tool.call({ tool: 'Edit', file_path: '/repo/src/copay.ts', old_string: 'a', new_string: 'b' })

  expect('deny' in ran).toBe(false)
  expect(notesOf(session).length).toBe(0)
})

test('a subagent gets its own copy', async ($, on) => {
  const session = mock.session(on)
  mock.store(on)
  on('tool.call', () => ({ result: {} }))

  await $.tool.call({ tool: 'Write', file_path: '/repo/a.test.ts', content: 'x' })
  await $.tool.call({ tool: 'Write', file_path: '/repo/b.test.ts', content: 'x', agentId: 'a1' })
  await $.tool.call({ tool: 'Write', file_path: '/repo/c.test.ts', content: 'x', agentId: 'a1' })

  const notes = notesOf(session)
  expect(notes.length).toBe(2)
  expect(notes.filter(row => row.agentId === 'a1').length).toBe(1)
})

test('/testing-guidance loads the guidance, again if asked again', async ($, on) => {
  const session = mock.session(on)
  mock.store(on)
  engineForStart(on)
  await $.session.start({ cwd: '/', surface: 'desktop', isInteractive: true })

  const ran = await $.command.run(command(''))
  expect(ran.text ?? '').toContain('loaded')
  await $.command.run(command(''))

  expect(notesOf(session).length).toBe(2)
})

test('sync hands the model an instruction naming the tool and the source', async ($, on) => {
  mock.session(on)
  mock.store(on)
  mock.clock(on)
  engineForStart(on)
  await $.session.start({ cwd: '/', surface: 'desktop', isInteractive: true })

  const given = await $.command.run(command('sync https://example.com/testing.md'))
  expect(given.text ?? '').toContain('https://example.com/testing.md')
  expect(given.context?.[0] ?? '').toContain(TOOL)
  expect(given.context?.[0] ?? '').toContain('https://example.com/testing.md')

  const defaulted = await $.command.run(command('sync'))
  expect((defaulted.context ?? []).length).toBe(0)
  expect(defaulted.text ?? '').toContain('source')
})

test('set_guidance stores the copy, loads it, and status reports it', async ($, on) => {
  const session = mock.session(on)
  mock.store(on)
  mock.clock(on, { now: 1762300800000 })
  engineForStart(on)
  await $.session.start({ cwd: '/', surface: 'desktop', isInteractive: true })
  await $.command.run(command('sync https://example.com/t.md'))

  const ran = await $.tool.call({
    tool: TOOL,
    text: '## Rule\n\nOnly unit tests here.',
    source: 'https://example.com/t.md',
    editedAt: '2026-11-01',
  })
  expect('deny' in ran).toBe(false)
  expect(JSON.stringify('result' in ran ? ran.result : '')).toContain('Stored')

  expect(notesOf(session).length).toBe(1)
  expect(noteText(session)).toContain('Only unit tests here.')
  expect(noteText(session)).toContain('https://example.com/t.md')
  expect(noteText(session)).toContain('last edited 2026-11-01')

  const status = await $.command.run(command('status'))
  expect(status.text ?? '').toContain('synced copy from https://example.com/t.md')
  expect(status.text ?? '').not.toContain('is pending')

  // The request was consumed: a second call needs a new sync.
  const again = await $.tool.call({ tool: TOOL, text: '## Other', source: 'https://example.com/t.md' })
  expect('deny' in again || ('isError' in again && again.isError === true)).toBe(true)
  expect(notesOf(session).length).toBe(1)
})

test('set_guidance is refused when no sync is pending', async ($, on) => {
  const session = mock.session(on)
  mock.store(on)
  mock.clock(on)
  engineForStart(on)
  await $.session.start({ cwd: '/', surface: 'desktop', isInteractive: true })

  const ran = await $.tool.call({ tool: TOOL, text: '## Injected', source: 'https://evil.example/x.md' })

  expect('deny' in ran || ('isError' in ran && ran.isError === true)).toBe(true)
  expect(notesOf(session).length).toBe(0)
  expect((await $.command.run(command('status'))).text ?? '').toContain('bundled default')
})

test('set_guidance for another source than the pending sync is refused', async ($, on) => {
  const session = mock.session(on)
  mock.store(on)
  mock.clock(on)
  engineForStart(on)
  await $.session.start({ cwd: '/', surface: 'desktop', isInteractive: true })
  await $.command.run(command('sync https://example.com/t.md'))

  const ran = await $.tool.call({ tool: TOOL, text: '## Injected', source: 'https://evil.example/x.md' })

  expect('deny' in ran || ('isError' in ran && ran.isError === true)).toBe(true)
  expect(notesOf(session).length).toBe(0)
  expect((await $.command.run(command('status'))).text ?? '').toContain('is pending')
})

test('a sync request expires after an hour', async ($, on) => {
  const session = mock.session(on)
  mock.store(on)
  const clock = mock.clock(on, { now: 1762300800000 })
  engineForStart(on)
  await $.session.start({ cwd: '/', surface: 'desktop', isInteractive: true })
  await $.command.run(command('sync https://example.com/t.md'))
  await clock.advance(61 * 60 * 1000)

  const ran = await $.tool.call({ tool: TOOL, text: '## Late', source: 'https://example.com/t.md' })

  expect('deny' in ran || ('isError' in ran && ran.isError === true)).toBe(true)
  expect(notesOf(session).length).toBe(0)
})

test('the plugin name alone is not a prompt about tests', async ($, on) => {
  const session = mock.session(on)
  mock.store(on)
  on('prompt.submit', (_, e) => ({ text: e.text }))

  await $.prompt.submit({ text: 'what does the testing-guidance plugin do?', wait: false, origin: COMPOSER })

  expect(notesOf(session).length).toBe(0)
})

test('a stored copy replaces the bundled one for a prompt', async ($, on) => {
  const session = mock.session(on)
  mock.store(on, {
    guidance: { text: 'CUSTOM BODY', source: 'file:///team/testing.md', syncedAt: '2026-11-03T10:00:00.000Z' },
  })
  engineForStart(on)
  on('prompt.submit', (_, e) => ({ text: e.text }))
  on('ui.toast', () => ({ value: undefined }))
  await $.session.start({ cwd: '/', surface: 'desktop', isInteractive: true })

  await $.prompt.submit({ text: 'write a test plan for onboarding', wait: false, origin: COMPOSER })

  expect(noteText(session)).toContain('CUSTOM BODY')
  expect(noteText(session)).toContain('file:///team/testing.md')
  expect(noteText(session)).not.toContain('Bundled default guidance')
})

test('set_guidance without text is refused and stores nothing', async ($, on) => {
  const session = mock.session(on)
  mock.store(on)
  mock.clock(on)
  engineForStart(on)
  await $.session.start({ cwd: '/', surface: 'desktop', isInteractive: true })
  await $.command.run(command('sync https://example.com/t.md'))

  const ran = await $.tool.call({ tool: TOOL, source: 'https://example.com/t.md' })
  const refused = 'deny' in ran || ('isError' in ran && ran.isError === true)
  expect(refused).toBe(true)
  expect(notesOf(session).length).toBe(0)

  const status = await $.command.run(command('status'))
  expect(status.text ?? '').toContain('bundled default')
})

test('reset removes the stored copy; show prints the guidance', async ($, on) => {
  mock.session(on)
  mock.store(on, { guidance: { text: 'CUSTOM BODY', source: 'file:///team/testing.md' } })
  engineForStart(on)
  await $.session.start({ cwd: '/', surface: 'desktop', isInteractive: true })

  const before = await $.command.run(command('show'))
  expect(before.text ?? '').toContain('CUSTOM BODY')

  await $.command.run(command('reset'))

  const after = await $.command.run(command('status'))
  expect(after.text ?? '').toContain('bundled default')
  const shown = await $.command.run(command('show'))
  expect(shown.text ?? '').toContain(MARK)
  expect(shown.text ?? '').not.toContain('CUSTOM BODY')
})

import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register } from 'claude-code'

import { DEFAULT_GUIDANCE, render } from './guidance'
import type { Guidance } from './guidance'

const PLUGIN = 'testing-guidance'
const COMMAND = 'testing-guidance'
const TOOL = 'set_guidance'
const TOOL_FULL = `mcp__${PLUGIN}__${TOOL}`
const STORE_KEY = 'guidance'

const injected = atom({ plugin: 'testing-guidance', key: 'injected' } as const, false)
const agents = atom({ plugin: 'testing-guidance', key: 'agents' } as const, [])

// A prompt that is about tests, specs, coverage, TDD, or a test plan.
const PROMPT_SIGNAL =
  /\b(tests?|testing|tested|specs?|tdd|coverage|unit[- ]tests?|integration[- ]tests?|e2e|end[- ]to[- ]end|jest|vitest|playwright|cypress|supertest|nock|test[- ]plans?)\b/i

// A test file by name or by folder.
const TEST_FILE =
  /(\.(spec|test|e2e-spec)\.[cm]?[jt]sx?$)|(^|\/)(__tests__|tests?|e2e|cypress|playwright)\//i

const isGuidance = (value: unknown): value is Guidance =>
  typeof value === 'object' &&
  value !== null &&
  typeof (value as Guidance).text === 'string' &&
  (value as Guidance).text.trim() !== '' &&
  typeof (value as Guidance).source === 'string'

// The guidance in force: a copy /testing-guidance sync stored on this machine,
// else the bundled default.
const stored = async ($: EngineInterface) => {
  const value = await $.store.get(STORE_KEY)

  return isGuidance(value) ? value : undefined
}

const current = async ($: EngineInterface) => (await stored($)) ?? DEFAULT_GUIDANCE

// Appends the guidance to a conversation once: the main one, or the subagent
// loop `agentId` names. Resolves true when it appended now.
const inject = async ($: EngineInterface, agentId?: string, force = false) => {
  if (agentId === undefined) {
    if (!force && (await read($, injected))) {
      return false
    }
    await update($, injected, () => true)
  } else {
    const seen = await read($, agents)
    if (!force && seen.includes(agentId)) {
      return false
    }
    await update($, agents, list => [...list, agentId])
  }

  await $.session.append({
    message: { type: 'user', content: [{ type: 'text', text: render(await current($)) }] },
    ...(agentId === undefined ? {} : { agentId }),
  })

  return true
}

// What the model is told when the person runs /testing-guidance sync.
const syncInstruction = (source: string) => `Update the testing-guidance guidance from ${source}.

1. Fetch it. A Notion URL goes through the Notion connector's fetch tool; an http(s) URL through WebFetch; anything else is a local file path for Read. If it cannot be fetched, say why and stop; do not invent content.
2. Condense it into markdown the model can apply when writing or planning tests. Keep every definition and every rule (what each kind of test may and may never do) in the source's own words where they are short; keep decision rules, named tools, and named systems. Drop images, diagrams, memes, comments, and anecdotes. Headings at level 2 only. Aim for 600 to 1200 words. Add no rule the source does not state.
3. Call the tool ${TOOL_FULL} (load it with ToolSearch if it is not loaded) with: text, the condensed markdown; source, "${source}" as given; editedAt, the source's own last-edited date when the fetch reported one, as YYYY-MM-DD.
4. Report what changed against the previous guidance in a few lines. If the current project holds plugins/testing-guidance/hooks/guidance.ts, offer to update the bundled default there too, so it ships to everyone.`

const describe = async ($: EngineInterface) => {
  const copy = await stored($)
  const loaded = await read($, injected)
  const lines = copy
    ? [
        `Guidance in force: synced copy from ${copy.source}`,
        `  last edited ${copy.editedAt ?? 'unknown'}, synced ${copy.syncedAt ?? 'unknown'}, ${copy.text.length} characters`,
      ]
    : [
        `Guidance in force: bundled default${DEFAULT_GUIDANCE.source ? ` from ${DEFAULT_GUIDANCE.source}` : ''}`,
        `  ${DEFAULT_GUIDANCE.text.length} characters${DEFAULT_GUIDANCE.editedAt ? `, last edited ${DEFAULT_GUIDANCE.editedAt}` : ''}`,
      ]
  lines.push(loaded ? 'Loaded into this conversation.' : 'Not loaded into this conversation yet.')
  lines.push('Subcommands: sync <source>, status, show, reset.')

  return lines.join('\n')
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await $.command.register({
      name: COMMAND,
      description:
        'Load the testing guidance into this session; sync <source> refreshes it from a Notion page, a URL or a file; status, show, reset',
    })
    await $.tool.register({
      name: TOOL,
      description:
        'Stores new testing guidance for the testing-guidance plugin on this machine and loads it into the conversation. Call it only when /testing-guidance sync asked for it.',
      inputSchema: {
        type: 'object',
        properties: {
          text: { type: 'string', description: 'The condensed guidance as markdown, no outer wrapper' },
          source: { type: 'string', description: 'Where it came from: the URL or file path as given' },
          editedAt: { type: 'string', description: "The source's last-edited date, YYYY-MM-DD, when known" },
        },
        required: ['text', 'source'],
      },
    })

    return next(e)
  })

  on('command.run', { command: COMMAND }, async ($, e) => {
    const [verb = '', ...rest] = e.args.trim().split(/\s+/).filter(Boolean)
    const arg = rest.join(' ')

    switch (verb) {
      case '': {
        await inject($, undefined, true)
        return { text: `Testing guidance loaded into this session. ${await describe($)}` }
      }
      case 'sync': {
        const source = arg || (await current($)).source
        if (!source) {
          return {
            text: 'Give a source to sync from: /testing-guidance sync <Notion URL, http(s) URL, or file path>.',
          }
        }
        return {
          text: `Syncing the testing guidance from ${source}. The assistant fetches it, condenses it, and stores it with ${TOOL_FULL}.`,
          context: [syncInstruction(source)],
        }
      }
      case 'status':
        return { text: await describe($) }
      case 'show':
        return { text: render(await current($)) }
      case 'reset': {
        await $.store.delete(STORE_KEY)
        return { text: 'Synced guidance removed; the bundled default is in force again.' }
      }
      default:
        return { text: `Unknown subcommand "${verb}". Use /testing-guidance, or sync [source], status, show, reset.` }
    }
  }).catch(() => ({ text: `${PLUGIN}: the command failed.` }))

  // The model hands back condensed guidance; it is stored for this machine and
  // loaded into the conversation at once.
  on('tool.call', { tool: /^mcp__testing-guidance__set_guidance$/ }, async ($, e) => {
    const input = e as Record<string, unknown>
    const text = typeof input.text === 'string' ? input.text.trim() : ''
    const source = typeof input.source === 'string' ? input.source.trim() : ''
    const editedAt = typeof input.editedAt === 'string' && input.editedAt.trim() !== '' ? input.editedAt.trim() : undefined

    if (text === '' || source === '') {
      return { deny: `${TOOL_FULL}: text and source are both required.` }
    }

    const syncedAt = new Date(await $.clock.now()).toISOString()
    const guidance: Guidance = { text, source, syncedAt, ...(editedAt ? { editedAt } : {}) }
    await $.store.set(STORE_KEY, guidance)
    await inject($, e.agentId, true)

    return {
      result: {
        content: [
          {
            type: 'text',
            text: `Stored ${text.length} characters of guidance from ${source} and loaded it into this conversation. It now replaces the bundled copy on this machine until /testing-guidance reset.`,
          },
        ],
      },
    }
  }).catch(() => ({ deny: `${TOOL_FULL}: storing the guidance failed.` }))

  // A prompt about tests loads the guidance before the turn starts.
  on('prompt.submit', async ($, e, next) => {
    if (e.command === undefined && e.isMeta === undefined && PROMPT_SIGNAL.test(e.text)) {
      if (await inject($)) {
        $.ui.toast('Testing guidance loaded')
      }
    }

    return next(e)
  }).catch(($, e, next) => next(e))

  // A write to a test file without the guidance in context loads it and
  // refuses that one write, so the test is written with the guidance read.
  on('tool.call', { tool: ['Write', 'Edit'] }, async ($, e, next) => {
    if (!TEST_FILE.test(e.file_path)) {
      return next(e)
    }
    if (!(await inject($, e.agentId))) {
      return next(e)
    }

    return {
      deny: `${PLUGIN}: ${e.file_path} is a test file and the testing guidance was not in this conversation yet. It has been added as a message above; read it, then re-issue this write.`,
    }
  }).catch(($, e, next) => next(e))
}

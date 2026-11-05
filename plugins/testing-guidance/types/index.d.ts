declare module 'claude-code' {
  interface PluginState {
    'testing-guidance': {
      /** The guidance has been appended to the main conversation. */
      injected: boolean
      /** Subagent loops the guidance has been appended to. */
      agents: string[]
    }
  }

  interface McpToolInputs {
    /** The tool the mod registers for /testing-guidance sync to hand back condensed guidance. */
    'mcp__testing-guidance__set_guidance': {
      text: string
      source: string
      editedAt?: string
    }
  }
}

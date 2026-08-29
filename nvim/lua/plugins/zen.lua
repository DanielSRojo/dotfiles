return {
  {
    "folke/zen-mode.nvim",
    opts = {
      window = {
        -- Applied to the zen float only; the float is destroyed on close, so
        -- these never leak back into the normal windows.
        options = {
          -- LazyVim keeps `wrap` off globally, which makes zen mode useless for
          -- prose: the window is narrowed to 120 columns but long lines still
          -- run off the right edge.
          wrap = true,
          linebreak = true, -- break at whitespace, not mid-word
          breakindent = true, -- keep the continuation aligned with the indent
          showbreak = "↳ ", -- mark continuations so they aren't read as new lines
        },
      },
    },
  },
}

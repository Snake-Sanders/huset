[
  import_deps: [:phoenix, :phoenix_live_view],
  inputs: [
    "*.{ex,exs,heex}",
    "{config,lib,priv,test,spec,dev}/**/*.{ex,exs,heex}"
  ],
  plugins: [Phoenix.LiveView.HTMLFormatter]
]

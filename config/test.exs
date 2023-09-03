import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :huset, HusetWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "xTVlG6Mt2wC8wVhFGK76FyiQi+tJsTDNx8fJXmk8Em+H7yZqpsBbKLf8CutmNAq5",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

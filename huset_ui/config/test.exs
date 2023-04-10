import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :huset_ui, HusetUIWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "IGT954oLnulLjSEbvaKL8VDhhF75dE4S6jWZroxPI+KK4PsxYSfK2cE/dqi42ZEc",
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

defmodule HusetWeb.Router do
  use HusetWeb, :router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, html: {HusetWeb.Layouts, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/", HusetWeb do
    pipe_through(:browser)

    live("/", SonoffLive)
    get("/page", PageController, :home)
  end

  # Other scopes may use custom stacks.
  # scope "/api", HusetWeb do
  #   pipe_through :api
  # end
end

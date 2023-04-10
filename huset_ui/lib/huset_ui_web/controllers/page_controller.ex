defmodule HusetUIWeb.PageController do
  use HusetUIWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end

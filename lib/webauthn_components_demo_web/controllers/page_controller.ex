defmodule WebauthnComponentsDemoWeb.PageController do
  use WebauthnComponentsDemoWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end

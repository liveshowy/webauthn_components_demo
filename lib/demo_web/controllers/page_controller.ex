defmodule DemoWeb.PageController do
  alias Hex.API.User
  alias Demo.Identity
  alias Demo.Identity.User
  use DemoWeb, :controller

  def home(conn, _params) do
    with user_id when is_binary(user_id) <- get_session(conn, "user_id"),
         {:ok, %User{} = user} <- Identity.get(user_id) do
      conn
      |> assign(:current_user, user)
      |> render(:home, layout: false)
    else
      _no_user ->
        conn
        |> assign(:current_user, nil)
        |> render(:home, layout: false)
    end
  end
end

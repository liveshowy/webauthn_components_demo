defmodule DemoWeb.Hooks.User do
  @moduledoc """
  Session hook for setting a user assign
  """
  require Logger
  import Phoenix.LiveView, only: [connected?: 1, get_connect_params: 1]
  import Phoenix.Component, only: [assign: 3, assign_new: 3]
  alias Demo.Accounts.User
  alias Demo.Authentication

  @doc """
  Assign a `current_user` key to the socket.

  If the socket is connected, a user lookup is attempted, using `_user_token` from `app.js`.
  """
  def on_mount(name, params, session, socket)

  def on_mount(:default, _, _, %{assigns: %{current_user: %User{}}} = socket) do
    {:cont, socket}
  end

  def on_mount(:default, _, _, socket) do
    with true <- connected?(socket),
         socket_params <- get_connect_params(socket),
         user_token <- Map.get(socket_params, "_user_token", ""),
         {:ok, binary_token} <- Base.url_decode64(user_token, padding: false),
         current_user <- Authentication.get_user_by_session_token(binary_token) do
      {
        :cont,
        socket
        |> assign(:current_user, current_user)
      }
    else
      false ->
        # Socket is not yet connected
        {
          :cont,
          socket
          |> assign_new(:current_user, fn -> nil end)
        }

      other_result ->
        Logger.warn(unhandled_result: {__MODULE__, other_result})

        {
          :cont,
          socket
          |> assign_new(:current_user, fn -> nil end)
        }
    end
  end
end

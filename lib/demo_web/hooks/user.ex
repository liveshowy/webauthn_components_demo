defmodule DemoWeb.Hooks.User do
  @moduledoc """
  Session hook for setting a user assign
  """
  require Logger
  import Phoenix.LiveView
  import Phoenix.Component, only: [assign: 3, assign_new: 3]
  alias Demo.Accounts.User
  alias Demo.Authentication

  @doc """
  Assign a `current_user` key to the socket.

  If the socket is connected, a user lookup is attempted, using `_user_token` from `app.js`.
  """
  def on_mount(name, params, session, socket)

  def on_mount(:assign_user, _, _, %{assigns: %{current_user: %User{}}} = socket) do
    {
      :halt,
      socket
      |> push_navigate(to: "/user/profile", replace: true)
    }
  end

  def on_mount(:assign_user, _, _, socket) do
    with {:connected, true} <- {:connected, connected?(socket)},
         {:socket_params, socket_params} <- {:socket_params, get_connect_params(socket)},
         {:user_token, user_token} when is_binary(user_token) <-
           {:user_token, get_user_token(socket_params)},
         {:user, %User{} = current_user} <-
           {:user, Authentication.get_user_by_session_token(user_token)} do
      {
        :cont,
        socket
        |> assign(:current_user, current_user)
      }
    else
      {:connected, false} ->
        {
          :cont,
          socket
          |> assign_new(:current_user, fn -> nil end)
        }

      {:user_token, invalid_token} ->
        Logger.warn(invalid_user_token: invalid_token)

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

  def on_mount(:require_user, _, _, socket) do
    socket_connected? = connected?(socket)
    current_user = socket.assigns[:current_user]

    cond do
      socket_connected? and is_struct(current_user, User) ->
        {:cont, socket}

      socket_connected? ->
        {
          :halt,
          socket
          |> assign_new(:current_user, fn -> nil end)
          |> push_navigate(to: "/passkey", replace: true)
        }

      true ->
        {
          :cont,
          socket
          |> assign_new(:current_user, fn -> nil end)
        }
    end
  end

  defp get_user_token(socket_params) do
    case Map.get(socket_params, "_user_token") do
      user_token when is_binary(user_token) ->
        Base.decode64!(user_token, padding: false)

      nil ->
        nil
    end
  end
end

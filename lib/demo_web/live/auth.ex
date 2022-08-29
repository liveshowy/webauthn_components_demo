defmodule DemoWeb.Live.Auth do
  @moduledoc """
  LiveView for registering and authenticating users.
  """
  use DemoWeb, :live_view
  require Logger
  alias Demo.Accounts
  alias Demo.Authentication

  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user

    if current_user do
      {
        :ok,
        socket
        |> push_redirect(to: Routes.page_path(socket, :index))
      }
    else
      {
        :ok,
        socket
        |> assign(:page_title, "Authentication")
      }
    end
  end

  def render(assigns) do
    ~H"""
    <h1>Authentication</h1>
    <.live_component
      module={WebAuthnLiveComponent}
      id="auth_form"
      authenticate_label="Sign In"
      register_label="New Account"
      app={:demo}
      />
    """
  end

  def handle_info({:webauthn_supported, false}, socket) do
    {
      :noreply,
      socket
      |> put_flash(:error, "This browser does not support passwordless accounts.")
    }
  end

  def handle_info({:webauthn_supported, _true}, socket) do
    {:noreply, socket}
  end

  def handle_info({:user_token, token: token}, socket) when is_binary(token) do
    {
      :noreply,
      socket
      |> push_event("clear_token", %{})
      |> clear_flash()
      |> put_flash(:info, "You have been signed out.")
    }
  end

  def handle_info({:user_token, token: nil}, socket) do
    {:noreply, socket}
  end

  def handle_info({:find_user_by_username, username: username}, socket) do
    user = Accounts.get_user_by(:username, username, [:keys])
    send_update(WebAuthnLiveComponent, id: "auth_form", found_user: user)
    {:noreply, socket}
  end

  def handle_info({:register_user, user: user, key: key}, socket) do
    with {:ok, %{user: new_user}} <- Accounts.create_user_with_key(user, key),
         session_token <- Authentication.generate_user_session_token(new_user),
         token_64 <- Base.url_encode64(session_token, padding: false) do
      {
        :noreply,
        socket
        |> clear_flash()
        |> put_flash(:info, "New account for #{new_user.username} registered!")
        |> assign(:current_user, new_user)
        |> push_event("store_token", %{token: token_64})
      }
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        {
          :noreply,
          socket
          |> put_flash(:error, "Failed to register a new account.")
          |> send_update(WebAuthnLiveComponent, %{changeset: changeset})
        }

      other_error ->
        Logger.warn(unhandled_error: {__MODULE__, other_error})

        {
          :noreply,
          socket
          |> put_flash(:error, "Failed to register a new account.")
        }
    end
  end

  def handle_info({:authentication_successful, key_id: key_id}, socket) do
    user_key = Authentication.get_user_key_by_key_id(key_id, [:user])
    %{user: user} = user_key
    session_token = Authentication.generate_user_session_token(user)
    token = Base.url_encode64(session_token, padding: false)
    Authentication.update_user_key(user_key, %{last_used: DateTime.utc_now()})

    {
      :noreply,
      socket
      |> assign(:current_user, user)
      |> push_event("store_token", %{token: token})
      |> clear_flash()
      |> put_flash(:info, "Welcome back, #{user.username}!")
    }
  end

  def handle_info({:redirect}, socket) do
    {
      :noreply,
      socket
      |> redirect(to: Routes.page_path(socket, :index))
    }
  end

  def handle_info({:error, error}, socket) do
    Logger.error(error: {__MODULE__, error})
    {:noreply, socket}
  end

  def handle_info(message, socket) do
    Logger.debug(unhandled_message: {__MODULE__, message})
    {:noreply, socket}
  end
end

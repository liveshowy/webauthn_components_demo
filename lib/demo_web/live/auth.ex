defmodule DemoWeb.Live.Auth do
  @moduledoc """
  LiveView for registering and authenticating users.
  """
  use DemoWeb, :live_view
  require Logger

  def mount(_params, _session, socket) do
    {
      :ok,
      socket
      |> assign(:page_title, "Authentication")
    }
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
    }
  end

  def handle_info({:user_token, token: nil}, socket) do
    {:noreply, socket}
  end

  def handle_info({:register_user, user: user, user_keys: user_keys}, socket) do
    # TODO: Persist the user
    # TODO: Create a session
    # TODO: Assign @current_user to socket
    Logger.info(register_user: {__MODULE__, user: user, user_keys: user_keys})

    {
      :noreply,
      socket
      |> put_flash(:info, "#{user.username} registered!")
    }
  end

  def handle_info({:authenticate_user, username: username}, socket) do
    # TODO: Get user by username
    # TODO: Create a session
    # TODO: Assign @current_user to socket
    Logger.info(authenticate_user: {__MODULE__, username})

    {
      :noreply,
      socket
      |> put_flash(:info, "Authenticate #{username}")
    }
  end

  def handle_info({:find_user_by_username, username: username}, socket) do
    # TODO: perform a real user lookup
    Logger.info(find_user_by_username: {__MODULE__, username})
    user = %{username: username, id: 1234, keys: []}
    send_update(WebAuthnLiveComponent, id: "auth_form", found_user: user)
    {:noreply, socket}
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

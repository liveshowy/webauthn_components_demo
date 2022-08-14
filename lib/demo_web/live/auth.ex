defmodule DemoWeb.Live.Auth do
  @moduledoc """
  LiveView for registering and authenticating users.
  """
  use DemoWeb, :live_view

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

  def handle_info({:register_user, username: username}, socket) do
    # TODO: Persist the user
    # TODO: Create a session
    # TODO: Assign @current_user to socket
    IO.inspect(username, label: :register_user)
    {
      :noreply,
      socket
      |> put_flash(:info, "Register #{username}")
    }
  end

  def handle_info({:authenticate_user, username: username}, socket) do
    # TODO: Get user by username
    # TODO: Create a session
    # TODO: Assign @current_user to socket
    IO.inspect(username, label: :authenticate_user)
    {
      :noreply,
      socket
      |> put_flash(:info, "Authenticate #{username}")
    }
  end

  def handle_info({:find_user_by_username, username: username}, socket) do
    # TODO: perform a real user lookup
    user = %{username: username, id: 1234, keys: []}
    send_update(WebAuthnLiveComponent, id: "auth_form", found_user: user)
    {:noreply,socket}
  end
end

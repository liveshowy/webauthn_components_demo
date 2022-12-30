defmodule DemoWeb.Live.SignOut do
  @moduledoc """
  LiveView for handling sign out.

  Uses `PasskeyHook` to send and receive token events.
  """
  use DemoWeb, :live_view

  def mount(_params, _session, socket) do
    {
      :ok,
      socket
      |> push_event("clear-token", %{})
    }
  end

  def render(assigns) do
    ~H"""
    <section id="sign-out-section" phx-hook="PasskeyHook" class="flex items-center justify-center w-full h-full">
      <h1 class="text-3xl">Signing Out</h1>
    </section>
    """
  end

  @doc """
  Handles `"token-cleared"` event from the `PasskeyHook` and ignores all other events.
  """
  def handle_event("token-cleared", _payload, socket) do
    {
      :noreply,
      socket
      |> assign(:current_user, nil)
      |> redirect(to: "/")
    }
  end

  def handle_event(_event, _payload, socket) do
    {:noreply, socket}
  end
end

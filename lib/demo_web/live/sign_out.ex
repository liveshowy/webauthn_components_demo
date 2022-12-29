defmodule DemoWeb.Live.SignOut do
  @moduledoc """
  LiveView for handling sign out.
  """
  use DemoWeb, :live_view
  alias WebAuthnLiveComponent.PasskeyComponent

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    send_update_after(PasskeyComponent, [id: "passkey-component", token: :clear], 3_000)

    ~H"""
    <div class="contents">
      <section class="flex items-center justify-center w-full h-full">
        <h1 class="text-3xl animate-pulse">Signing Out</h1>

      </section>

      <div class="opacity-0">
        <.live_component module={PasskeyComponent} app={:demo_app} id="passkey-component" />
      </div>
    </div>
    """
  end

  def handle_info({:token_cleared}, socket) do
    IO.inspect(token_cleared: __MODULE__)

    {
      :noreply,
      socket
      |> assign(:current_user, nil)
      |> redirect(to: "/")
    }
  end

  def handle_info(_message, socket) do
    {:noreply, socket}
  end
end

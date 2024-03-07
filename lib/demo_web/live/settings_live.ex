defmodule DemoWeb.SettingsLive do
  @moduledoc """
  LiveView for registering new keys to an existing user.
  """
  use DemoWeb, :live_view
  require Logger

  alias Demo.Identity
  alias Demo.Identity.UserKey

  alias WebauthnComponents.RegistrationComponent
  alias WebauthnComponents.WebauthnUser

  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user

    webauthn_user = %WebauthnUser{
      id: generate_encoded_id(),
      name: current_user.email,
      display_name: current_user.email
    }

    if connected?(socket) do
      send_update(RegistrationComponent,
        id: "registration-component",
        webauthn_user: webauthn_user
      )
    end

    {:ok, current_user} = Identity.get(current_user.id, [:keys])

    {
      :ok,
      socket
      |> assign(:page_title, "Settings")
      |> assign(:form, build_form())
      |> assign(:webauthn_user, webauthn_user)
      |> assign(:token_form, nil)
      |> assign(:keys, current_user.keys)
    }
  end

  def render(assigns) do
    ~H"""
    <.simple_form
      :let={form}
      :if={@form}
      for={@form}
      phx-change="update-form"
      phx-submit={JS.dispatch("click", to: "#registration-component")}
      class="grid gap-8"
    >
      <fieldset
        id="fieldset-registration"
        class="grid gap-4 bg-gray-50 ring-1 ring-gray-200 shadow-lg p-6 rounded-lg"
      >
        <p>Register a <strong>new</strong> passkey:</p>

        <.input
          type="text"
          field={form[:label]}
          placeholder="Apple device, 1Password, etc."
          label="Name"
          phx-debounce="250"
        />
        <.live_component
          disabled={!@form.source.valid?}
          module={RegistrationComponent}
          id="registration-component"
          app={Demo}
          display_text="Register"
          class={[
            "bg-gray-200 hover:bg-gray-300 hover:text-black rounded transition",
            "ring ring-transparent focus:ring-gray-400 focus:outline-none",
            "flex gap-2 items-center justify-center px-4 py-2 w-full",
            "disabled:cursor-not-allowed disabled:opacity-25"
          ]}
        />
      </fieldset>
    </.simple_form>
    <div class="pt-14 font-semibold flex justify-between underline">
      <div>Key Name</div>
      <div>Last Used</div>
    </div>
    <ul role="list" class="divide-y divide-gray-200">
      <li :for={key <- @keys} class="py-4 flex justify-between">
        <div><%= key.label %></div>
        <div><%= key.last_used_at %></div>
      </li>
    </ul>
    """
  end

  def handle_event("update-form", params, socket) do
    params = Map.put(params, "user_id", socket.assigns.current_user.id)

    {
      :noreply,
      socket
      |> assign(:form, build_form(params))
    }
  end

  def handle_event(event, params, socket) do
    Logger.warning(unhandled_event: {__MODULE__, event, params})
    {:noreply, socket}
  end

  def handle_info({:registration_successful, params}, socket) do
    %{form: form} = socket.assigns
    user = socket.assigns.current_user

    args =
      params[:key]
      |> Map.put(:label, form[:label].value)
      |> Map.put(:user_id, user.id)

    case Identity.create_key(args) do
      {:ok, user_key} ->
        {:ok, user} = Identity.get(user.id, [:keys])

        {
          :noreply,
          socket
          |> assign(:keys, user.keys)
          |> assign(:form, build_form())
          |> put_flash(:info, "Succesfully registered new key \"#{user_key.label}\"")
        }

      {:error, changeset} ->
        Logger.error(registration_error: {__MODULE__, changeset.changes, changeset.errors})

        {
          :noreply,
          socket
          |> assign(:form, to_form(changeset))
        }
    end
  end

  def handle_info(message, socket) do
    Logger.warning(unhandled_message: {__MODULE__, message})
    {:noreply, socket}
  end

  defp build_form(attrs \\ %{label: ""}) do
    %UserKey{}
    |> UserKey.new_changeset(attrs)
    |> Map.put(:action, :insert)
    |> to_form()
  end

  defp generate_encoded_id do
    :crypto.strong_rand_bytes(64)
    |> Base.encode64(padding: false)
  end
end

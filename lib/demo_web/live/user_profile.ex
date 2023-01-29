defmodule DemoWeb.Live.UserProfile do
  @moduledoc """
  LiveView for creating or updating a user's profile.
  """
  use DemoWeb, :live_view
  require Logger
  alias Demo.Accounts
  alias Demo.Accounts.User
  alias Demo.Accounts.UserProfile, as: UserProfileStruct
  alias Demo.Repo

  def mount(_params, _session, %{assigns: %{current_user: %User{} = current_user}} = socket) do
    user = Accounts.get_user!(current_user.id, [:profile, :keys])
    user_profile = user.profile || %UserProfileStruct{}

    {
      :ok,
      socket
      |> assign(:current_user, user)
      |> assign(:changeset, UserProfileStruct.changeset(user_profile, %{}))
    }
  end

  def mount(_params, _session, socket) do
    {
      :ok,
      socket
      |> assign(:changeset, nil)
    }
  end

  def render(assigns) do
    ~H"""
    <.form
    :if={@changeset}
    :let={profile}
    for={@changeset}
    phx-submit="submit"
    class="grid items-baseline grid-cols-1 gap-2 md:grid-cols-2"
    >
      <h1 class="text-4xl col-span-full">User Profile</h1>

      <.input
        field={{profile, :username}}
        type="text"
        label="Username"
        autofocus
      />

      <.input
        field={{profile, :email}}
        type="email"
        label="Email"
      />

      <.input
        field={{profile, :first_name}}
        type="text"
        label="First Name"
      />

      <.input
        field={{profile, :last_name}}
        type="text"
        label="Last Name"
      />


      <div class="flex justify-end gap-2 col-span-full">
        <.button type="submit">Save</.button>
      </div>

      <h2 class="text-3xl col-span-full">Passkeys</h2>

      <table class="font-mono text-left col-span-full">
        <thead>
          <tr>
            <th>Label</th>
            <th>Last Used</th>
            <th>Created</th>
            <th>Updated</th>
            <th class="select-none">&nbsp;</th>
          </tr>
        </thead>
        <tbody>
          <tr :for={key <- @current_user.keys}>
            <td><%= key.label %></td>
            <td><%= NaiveDateTime.to_date(key.last_used) %></td>
            <td><%= NaiveDateTime.to_date(key.inserted_at) %></td>
            <td><%= NaiveDateTime.to_date(key.updated_at) %></td>
            <td class="flex justify-end gap-1 text-right">
              <.button
                phx-click="delete-key"
                value={key.id}
                disabled={length(@current_user.keys) == 1}
                title={}
              >
                Delete
              </.button>
            </td>
          </tr>
        </tbody>
      </table>

      <%!-- TODO: Implement secondary key support --%>
      <%!--
      <hr class="opacity-50 col-span-full" />

      <div class="flex flex-wrap items-center justify-between gap-2 col-span-full">
        <h2 class="text-3xl">Passkey</h2>
        <button type="button" phx-click="add-key" class="w-8 rounded-full"><.plus_icon /></button>
      </div>

      <%= inputs_for f, :keys, fn key -> %>
        <%= label key, :label %>
        <div class="flex items-center gap-2">
          <%= text_input key, :label, class: "flex-grow" %>
          <button type="button" phx-click="save-key" phx-data={key.id} title="Save changes" class="w-8 rounded-full">
            <.check_icon />
          </button>
          <button type="button" phx-click="remove-key" phx-data={key.id} title="Delete this key" class="w-8 rounded-full">
            <.trash_icon />
          </button>
        </div>
      <% end %>
      --%>
    </.form>
    """
  end

  def handle_event("submit", %{"user_profile" => profile_params}, socket) do
    %{current_user: current_user} = socket.assigns
    profile = current_user.profile || %UserProfileStruct{}
    profile_params = Map.put(profile_params, "user_id", current_user.id)
    changeset = UserProfileStruct.changeset(profile, profile_params)

    case Repo.insert_or_update(changeset) do
      {:ok, upserted_profile} ->
        {
          :noreply,
          socket
          |> assign(:changeset, UserProfileStruct.changeset(upserted_profile, %{}))
          |> put_flash(:info, "Saved changes")
        }

      {:error, changeset} ->
        {
          :noreply,
          socket
          |> assign(:changeset, changeset)
        }
    end
  end

  def handle_event(event, payload, socket) do
    Logger.warn(unhandled_event: {__MODULE__, event, payload})
    {:noreply, socket}
  end
end

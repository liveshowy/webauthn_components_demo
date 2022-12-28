defmodule DemoWeb.Live.UserProfile do
  use DemoWeb, :live_view
  require Logger
  import Phoenix.HTML.Form
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
    let={profile}
    for={@changeset}
    phx-submit="submit"
    class="grid items-baseline grid-cols-1 gap-2"
    >
      <h1 class="text-4xl col-span-full">User Profile</h1>

      <.input
        field={{profile, :username}}
        type="text"
        label="Username"
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

  defp check_icon(assigns) do
    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" class="w-full h-full">
      <path fill-rule="evenodd" d="M9 1.5H5.625c-1.036 0-1.875.84-1.875 1.875v17.25c0 1.035.84 1.875 1.875 1.875h12.75c1.035 0 1.875-.84 1.875-1.875V12.75A3.75 3.75 0 0016.5 9h-1.875a1.875 1.875 0 01-1.875-1.875V5.25A3.75 3.75 0 009 1.5zm6.61 10.936a.75.75 0 10-1.22-.872l-3.236 4.53L9.53 14.47a.75.75 0 00-1.06 1.06l2.25 2.25a.75.75 0 001.14-.094l3.75-5.25z" clip-rule="evenodd" />
      <path d="M12.971 1.816A5.23 5.23 0 0114.25 5.25v1.875c0 .207.168.375.375.375H16.5a5.23 5.23 0 013.434 1.279 9.768 9.768 0 00-6.963-6.963z" />
    </svg>
    """
  end

  defp trash_icon(assigns) do
    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" class="w-full h-full">
      <path fill-rule="evenodd" d="M16.5 4.478v.227a48.816 48.816 0 013.878.512.75.75 0 11-.256 1.478l-.209-.035-1.005 13.07a3 3 0 01-2.991 2.77H8.084a3 3 0 01-2.991-2.77L4.087 6.66l-.209.035a.75.75 0 01-.256-1.478A48.567 48.567 0 017.5 4.705v-.227c0-1.564 1.213-2.9 2.816-2.951a52.662 52.662 0 013.369 0c1.603.051 2.815 1.387 2.815 2.951zm-6.136-1.452a51.196 51.196 0 013.273 0C14.39 3.05 15 3.684 15 4.478v.113a49.488 49.488 0 00-6 0v-.113c0-.794.609-1.428 1.364-1.452zm-.355 5.945a.75.75 0 10-1.5.058l.347 9a.75.75 0 101.499-.058l-.346-9zm5.48.058a.75.75 0 10-1.498-.058l-.347 9a.75.75 0 001.5.058l.345-9z" clip-rule="evenodd" />
    </svg>
    """
  end

  defp plus_icon(assigns) do
    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" class="w-full h-full">
      <path fill-rule="evenodd" d="M12 2.25c-5.385 0-9.75 4.365-9.75 9.75s4.365 9.75 9.75 9.75 9.75-4.365 9.75-9.75S17.385 2.25 12 2.25zM12.75 9a.75.75 0 00-1.5 0v2.25H9a.75.75 0 000 1.5h2.25V15a.75.75 0 001.5 0v-2.25H15a.75.75 0 000-1.5h-2.25V9z" clip-rule="evenodd" />
    </svg>
    """
  end
end

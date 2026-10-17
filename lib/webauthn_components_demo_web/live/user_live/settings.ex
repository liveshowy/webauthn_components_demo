defmodule WebauthnComponentsDemoWeb.UserLive.Settings do
  use WebauthnComponentsDemoWeb, :live_view
  require Logger

  on_mount {WebauthnComponentsDemoWeb.UserAuth, :require_sudo_mode}

  alias WebauthnComponentsDemo.Accounts
  alias WebauthnComponentsDemo.Accounts.PublicKeyCredential
  alias WebauthnComponentsDemo.Repo

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="text-center">
        <.header>
          Account Settings
          <:subtitle>Manage your account email address and password settings</:subtitle>
        </.header>
      </div>

      <.form for={@email_form} id="email_form" phx-submit="update_email" phx-change="validate_email">
        <.input
          field={@email_form[:email]}
          type="email"
          label="Email"
          autocomplete="username"
          spellcheck="false"
          required
        />
        <.button variant="primary" phx-disable-with="Changing...">Change Email</.button>
      </.form>

      <div class="divider" />

      <h2 class="font-semibold">Passkeys</h2>

      <div class="alert">
        <.icon name="hero-shield-check" />
        <span>A Passkey is the most secure way to access your account.</span>
      </div>

      <.live_component
        module={WebauthnComponents.ClientCapabilitiesComponent}
        id="client-capabilities"
      />

      <div
        :if={!@capabilities["userVerifyingPlatformAuthenticator"]}
        class="alert alert-error alert-soft"
      >
        <span>Passkeys not supported on this device</span>
      </div>

      <.live_component
        :if={@capabilities["userVerifyingPlatformAuthenticator"]}
        module={WebauthnComponents.RegistrationComponent}
        id="passkey-register-button"
        disabled={!@public_key_options}
        public_key_options={@public_key_options}
        class="btn btn-primary w-full disabled:btn-disabled"
      >
        <span>Add a Passkey</span>
      </.live_component>

      <div class="grid gap-x-1 gap-y-4 grid-cols-[1fr_auto_auto]">
        <div :for={credential <- @current_scope.user.public_key_credentials} class="contents">
          <% credential_id = Base.encode64(credential.id) %>
          <.form
            id={"credential-form-" <> credential_id}
            for={%{"label" => credential.label}}
            phx-submit="update-credential-label"
            phx-value-credential_id={credential_id}
            class="contents"
          >
            <input
              type="text"
              name="label"
              value={credential.label}
              placeholder="Passkey label"
              class="input w-full"
            />
            <button
              type="submit"
              phx-disable-with="Updating..."
              title="Update label"
              class="btn btn-info"
            >
              <.icon name="hero-check" />
            </button>
            <.button
              phx-click="delete-credential"
              phx-value-credential_id={credential_id}
              title="Delete credential"
              class="btn btn-error"
            >
              <.icon name="hero-trash" />
            </.button>
          </.form>
        </div>
      </div>

      <div class="divider" />

      <h2 class="font-semibold">Traditional Password</h2>

      <div class="alert">
        <.icon name="hero-shield-exclamation" />
        <span>A traditional password restricts access to anyone who knows the password.</span>
      </div>

      <.form
        for={@password_form}
        id="password_form"
        action={~p"/users/update-password"}
        method="post"
        phx-change="validate_password"
        phx-submit="update_password"
        phx-trigger-action={@trigger_submit}
      >
        <input
          name={@password_form[:email].name}
          type="hidden"
          id="hidden_user_email"
          spellcheck="false"
          value={@current_email}
        />
        <.input
          field={@password_form[:password]}
          type="password"
          label="New password"
          autocomplete="new-password"
          spellcheck="false"
          required
        />
        <.input
          field={@password_form[:password_confirmation]}
          type="password"
          label="Confirm new password"
          autocomplete="new-password"
          spellcheck="false"
        />
        <.button variant="primary" phx-disable-with="Saving...">
          Save Password
        </.button>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_user_email(socket.assigns.current_scope.user, token) do
        {:ok, _user} ->
          put_flash(socket, :info, "Email changed successfully.")

        {:error, _} ->
          put_flash(socket, :error, "Email change link is invalid or it has expired.")
      end

    {:ok, push_navigate(socket, to: ~p"/users/settings")}
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    email_changeset = Accounts.change_user_email(user, %{}, validate_unique: false)
    password_changeset = Accounts.change_user_password(user, %{}, hash_password: false)

    public_key_options = %WebauthnComponents.PublicKeyCredentialCreationOptions{
      user: %WebauthnComponents.User{
        id: user.id,
        name: user.email,
        display_name: user.email
      },
      rp: %WebauthnComponents.RelyingParty{
        id: socket.endpoint.host(),
        name: "Webauthn Components Demo"
      }
    }

    socket =
      socket
      |> update(
        :current_scope,
        &Map.update!(&1, :user, fn user -> Repo.preload(user, [:public_key_credentials]) end)
      )
      |> assign(:current_email, user.email)
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:trigger_submit, false)
      |> assign(:capabilities, %{})
      |> assign(:public_key_options, public_key_options)

    {:ok, socket}
  end

  @impl true
  def handle_info({:client_capabilities, capabilities}, socket) do
    {:noreply, assign(socket, :capabilities, capabilities)}
  end

  def handle_info({:error, webauthn_error}, socket) do
    Logger.error(webauthn_error)
    {:noreply, socket}
  end

  def handle_info(%Wax.AuthenticatorData{} = authenticator_data, socket) do
    %Wax.AuthenticatorData{
      attested_credential_data: %Wax.AttestedCredentialData{
        credential_id: credential_id,
        credential_public_key: credential_public_key
      }
    } = authenticator_data

    attrs = %{
      "id" => credential_id,
      "public_key" => credential_public_key,
      "user_id" => socket.assigns.current_scope.user.id
    }

    case Accounts.register_credential(attrs) do
      {:ok, _credential} ->
        {
          :noreply,
          socket
          |> push_navigate(to: ~p"/users/settings")
        }

      {:error, error} ->
        Logger.error(error)

        {
          :noreply,
          socket
          |> put_flash(:error, "Failed to register credential: #{inspect(error)}")
        }
    end
  end

  @impl true
  def handle_event("validate_email", params, socket) do
    %{"user" => user_params} = params

    email_form =
      socket.assigns.current_scope.user
      |> Accounts.change_user_email(user_params, validate_unique: false)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form)}
  end

  def handle_event("update_email", params, socket) do
    %{"user" => user_params} = params
    user = socket.assigns.current_scope.user
    true = Accounts.sudo_mode?(user)

    case Accounts.change_user_email(user, user_params) do
      %{valid?: true} = changeset ->
        Accounts.deliver_user_update_email_instructions(
          Ecto.Changeset.apply_action!(changeset, :insert),
          user.email,
          &url(~p"/users/settings/confirm-email/#{&1}")
        )

        info = "A link to confirm your email change has been sent to the new address."
        {:noreply, socket |> put_flash(:info, info)}

      changeset ->
        {:noreply, assign(socket, :email_form, to_form(changeset, action: :insert))}
    end
  end

  def handle_event("update-credential-label", params, socket) do
    %{"credential_id" => credential_id, "label" => label} = params

    with {:ok, credential_id} <- Base.decode64(credential_id),
         %PublicKeyCredential{} = credential <- Accounts.get_credential(credential_id),
         {:ok, _} <- Accounts.rename_credential(credential, %{"label" => label}) do
      {
        :noreply,
        socket
        # NOTE: The LiveView is reloaded here for simplicity.
        # Consider refreshing the current scope or user instead for a smoother experience.
        |> push_navigate(to: ~p"/users/settings")
        |> put_flash(:info, "Credential label updated successfully.")
      }
    else
      error ->
        # NOTE: The error is logged here for simplicity.
        # Consider handling failure cases more gracefully in a real application.
        Logger.error(error)
        {:noreply, socket |> put_flash(:error, "Failed to update credential label.")}
    end
  end

  def handle_event("delete-credential", params, socket) do
    %{"credential_id" => credential_id} = params

    with {:ok, credential_id} <- Base.decode64(credential_id),
         %PublicKeyCredential{} = credential <- Accounts.get_credential(credential_id),
         {:ok, _} <- Accounts.delete_credential(credential) do
      {
        :noreply,
        socket
        # NOTE: The LiveView is reloaded here for simplicity.
        # Consider refreshing the current scope or user instead for a smoother experience.
        |> push_navigate(to: ~p"/users/settings")
        |> put_flash(:info, "Credential label deleted successfully.")
      }
    else
      error ->
        # NOTE: The error is logged here for simplicity.
        # Consider handling failure cases more gracefully in a real application.
        Logger.error(error)
        {:noreply, socket |> put_flash(:error, "Failed to delete credential label.")}
    end
  end

  def handle_event("validate_password", params, socket) do
    %{"user" => user_params} = params

    password_form =
      socket.assigns.current_scope.user
      |> Accounts.change_user_password(user_params, hash_password: false)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form)}
  end

  def handle_event("update_password", params, socket) do
    %{"user" => user_params} = params
    user = socket.assigns.current_scope.user
    true = Accounts.sudo_mode?(user)

    case Accounts.change_user_password(user, user_params) do
      %{valid?: true} = changeset ->
        {:noreply, assign(socket, trigger_submit: true, password_form: to_form(changeset))}

      changeset ->
        {:noreply, assign(socket, password_form: to_form(changeset, action: :insert))}
    end
  end
end

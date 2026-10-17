defmodule WebauthnComponentsDemoWeb.UserLive.Login do
  use WebauthnComponentsDemoWeb, :live_view
  require Logger

  alias WebauthnComponentsDemo.Accounts
  alias WebauthnComponentsDemo.Accounts.User
  alias WebauthnComponents.FindUser

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-sm space-y-4">
        <div class="text-center">
          <.header>
            <p>Log in</p>
            <:subtitle>
              <%= if @current_scope do %>
                You need to reauthenticate to perform sensitive actions on your account.
              <% else %>
                Don't have an account? <.link
                  navigate={~p"/users/register"}
                  class="font-semibold text-brand hover:underline"
                  phx-no-format
                >Sign up</.link> for an account now.
              <% end %>
            </:subtitle>
          </.header>
        </div>

        <.live_component
          module={WebauthnComponents.ClientCapabilitiesComponent}
          id="client-capabilities-component"
        />

        <.live_component
          module={WebauthnComponents.AuthenticationComponent}
          id="passkey-authentication-component"
          class="btn btn-primary w-full"
        >
          <span>Log in with a Passkey</span>
        </.live_component>

        <.form
          :let={f}
          for={@credential_form}
          id="login_form_credential"
          action={~p"/users/log-in"}
          phx-submit="submit_credential"
          phx-trigger-action={@trigger_credential_submit}
        >
          <.input type="hidden" field={f[:credential_id]} />
        </.form>

        <div class="divider">or</div>

        <div :if={local_mail_adapter?()} class="alert alert-info">
          <.icon name="hero-information-circle" class="size-6 shrink-0" />
          <div>
            <p>You are running the local mail adapter.</p>
            <p>
              To see sent emails, visit <.link href="/dev/mailbox" class="underline">the mailbox page</.link>.
            </p>
          </div>
        </div>

        <.form
          :let={f}
          for={@form}
          id="login_form_magic"
          action={~p"/users/log-in"}
          phx-submit="submit_magic"
        >
          <.input
            readonly={!!@current_scope}
            field={f[:email]}
            type="email"
            label="Email"
            autocomplete="username"
            spellcheck="false"
            required
            phx-mounted={JS.focus()}
          />
          <.button class="btn btn-primary w-full">
            Log in with email <span aria-hidden="true">→</span>
          </.button>
        </.form>

        <div class="divider">or</div>

        <.form
          :let={f}
          for={@form}
          id="login_form_password"
          action={~p"/users/log-in"}
          phx-submit="submit_password"
          phx-trigger-action={@trigger_submit}
        >
          <.input
            readonly={!!@current_scope}
            field={f[:email]}
            type="email"
            label="Email"
            autocomplete="username"
            spellcheck="false"
            required
          />
          <.input
            field={@form[:password]}
            type="password"
            label="Password"
            autocomplete="current-password"
            spellcheck="false"
          />
          <.button class="btn btn-primary w-full" name={@form[:remember_me].name} value="true">
            Log in and stay logged in <span aria-hidden="true">→</span>
          </.button>
          <.button class="btn btn-primary btn-soft w-full mt-2">
            Log in only this time
          </.button>
        </.form>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    email =
      Phoenix.Flash.get(socket.assigns.flash, :email) ||
        get_in(socket.assigns, [:current_scope, Access.key(:user), Access.key(:email)])

    form = to_form(%{"email" => email}, as: "user")
    credential_form = to_form(%{"credential_id" => nil}, as: "credential")

    {:ok,
     assign(socket,
       form: form,
       credential_form: credential_form,
       trigger_submit: false,
       trigger_credential_submit: false
     )}
  end

  @impl true
  def handle_info({:client_capabilities, capabilities}, socket) do
    # Trigger autofill UI
    # See https://web.dev/articles/passkey-form-autofill for details
    if capabilities["conditionalGet"] do
      send_update(WebauthnComponents.AuthenticationComponent,
        id: "passkey-authentication-component",
        mediation: "conditional"
      )
    end

    {:noreply, socket}
  end

  def handle_info(%FindUser{user_handle: user_id}, socket) do
    %User{public_key_credentials: public_key_credentials} =
      Accounts.get_user!(user_id, [:public_key_credentials])

    send_update(WebauthnComponents.AuthenticationComponent,
      id: "passkey-authentication-component",
      credentials: public_key_credentials
    )

    {:noreply, socket}
  end

  def handle_info({credential_id, %Wax.AuthenticatorData{sign_count: 0}}, socket) do
    # NOTE: This example simply accepts authenticator data with a sign count of 0 to start a user session.
    # Consider checking other fields based on your security requirements.
    # See https://www.w3.org/TR/webauthn-1/#verifying-assertion for suggested verification steps.
    credential_form =
      to_form(%{"credential_id" => Base.url_encode64(credential_id)}, as: "credential")

    {
      :noreply,
      socket
      |> assign(:trigger_credential_submit, true)
      |> assign(:credential_form, credential_form)
    }
  end

  def handle_info(%Wax.InvalidClientDataError{} = error, socket) do
    Logger.warning(error)

    {
      :noreply,
      socket
      |> put_flash(:error, "Unable to sign in")
    }
  end

  def handle_info({:error, payload}, socket) do
    Logger.warning(payload)

    {
      :noreply,
      socket
    }
  end

  @impl true
  def handle_event("submit_password", _params, socket) do
    {:noreply, assign(socket, :trigger_submit, true)}
  end

  def handle_event("submit_magic", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_login_instructions(
        user,
        &url(~p"/users/log-in/#{&1}")
      )
    end

    info =
      "If your email is in our system, you will receive instructions for logging in shortly."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> push_navigate(to: ~p"/users/log-in")}
  end

  defp local_mail_adapter? do
    Application.get_env(:webauthn_components_demo, WebauthnComponentsDemo.Mailer)[:adapter] ==
      Swoosh.Adapters.Local
  end
end

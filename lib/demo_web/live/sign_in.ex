defmodule DemoWeb.Live.SignIn do
  @moduledoc """
  Example LiveView implementation of `WebauthnComponents`.

  Documentation may be found on [HexDocs](https://hexdocs.pm/webauthn_live_component/WebauthnComponents.html). See the [source code](https://github.com/liveshowy/webauthn_live_component_demo/blob/main/lib/demo_web/live/sign_in.ex) for complete implementation details.
  """
  use DemoWeb, :live_view
  require Logger
  alias Demo.Authentication
  alias Demo.Accounts.User
  alias Demo.Authentication.UserKey
  alias Demo.Authentication.UserToken
  alias Demo.Repo
  alias WebauthnComponents.SupportComponent
  alias WebauthnComponents.TokenComponent
  alias WebauthnComponents.RegistrationComponent
  alias WebauthnComponents.AuthenticationComponent

  @user_profile_path "/user/profile"

  def mount(_params, _session, socket) do
    current_user = socket.assigns[:current_user]
    action = socket.assigns[:live_action]

    cond do
      action == :sign_out ->
        send_update(TokenComponent, id: "token-component", token: :clear)
        {:ok, socket}

      connected?(socket) and is_struct(current_user, User) ->
        {
          :ok,
          socket
          |> push_navigate(to: @user_profile_path)
        }

      true ->
        {:ok, socket}
    end
  end

  def render(assigns) do
    ~H"""
    <section class="flex flex-col gap-4">
      <h1 class="text-3xl">Passkey Sign In</h1>

      <p class="text-lg">
        You may sign into <strong>Demo</strong> using a Passkey, which is more secure than a password.
      </p>

      <section class="flex gap-2">
        <.live_component module={SupportComponent} id="support-component" />
        <.live_component module={TokenComponent} id="token-component" />

        <.live_component
          module={RegistrationComponent}
          app={:demo}
          id="registration-component"
          class="px-2 py-1 border border-gray-300 hover:border-transparent bg-gray-200 hover:bg-blue-200 focus:bg-blue-300 text-gray-900 transition rounded text-base shadow-sm flex gap-2 items-center hover:-translate-y-px hover:shadow-md"
          />

        <.live_component
          module={AuthenticationComponent}
          id="authentication-component"
          class="px-2 py-1 border border-gray-300 hover:border-transparent bg-gray-200 hover:bg-blue-200 focus:bg-blue-300 text-gray-900 transition rounded text-base shadow-sm flex gap-2 items-center hover:-translate-y-px hover:shadow-md"
          />
      </section>
    </section>
    """
  end

  def handle_info({:passkeys_supported, boolean}, socket) do
    if boolean == true do
      # No need to alert the user here.
      {:noreply, socket}
    else
      {
        :noreply,
        socket
        |> put_flash(:error, "Sorry, Passkeys are not supported in this browser.")
      }
    end
  end

  def handle_info({:registration_successful, params}, socket) do
    multi = build_new_user_multi(params)

    case Repo.transaction(multi) do
      {:ok, %{user: user, key: _key, token: token}} ->
        send_update(TokenComponent,
          id: "token-component",
          token: Base.encode64(token.token, padding: false)
        )

        {
          :noreply,
          socket
          |> assign(:current_user, user)
        }

      {:error, %Ecto.Changeset{} = changeset} ->
        Logger.error(changeset_error: changeset)

        {
          :noreply,
          socket
          |> put_flash(:error, "Failed to create user")
        }

      unknown_error ->
        Logger.error(unknown_error: unknown_error)

        {
          :noreply,
          socket
          |> put_flash(:error, "Unknown error")
        }
    end
  end

  def handle_info({:registration_failure, message: message}, socket) do
    {
      :noreply,
      socket
      |> put_flash(:error, message)
    }
  end

  def handle_info({:find_credentials, user_handle: user_handle}, socket) do
    %{user: user} = Authentication.get_user_key_by_user_handle(user_handle, [:user])

    case user do
      %User{} ->
        Logger.info(authentication_success: {:user_handle, user_handle})
        {:ok, token} = Authentication.generate_user_session_token(user)
        token64 = Base.encode64(token.token, padding: false)
        send_update(TokenComponent, id: "token-component", token: token64)

        {
          :noreply,
          socket
          |> assign(:current_user, user)
        }

      _ ->
        Logger.error(authentication_failure: {:user_handle, user_handle})

        {
          :noreply,
          socket
          |> put_flash(:error, "Failed to sign in.")
        }
    end
  end

  def handle_info({:authentication_failure, message: message}, socket) do
    {
      :noreply,
      socket
      |> put_flash(:error, message)
    }
  end

  def handle_info({:token_exists, token: token}, socket) do
    decoded_token = Base.decode64!(token, padding: false)
    user = Authentication.get_user_by_session_token(decoded_token)

    case user do
      %User{} ->
        {
          :noreply,
          socket
          |> assign(:current_user, user)
          |> push_navigate(to: @user_profile_path)
        }

      _ ->
        send_update(TokenComponent, id: "token-component", token: :clear)
        {:noreply, socket}
    end
  end

  def handle_info({:token_stored, token: token}, socket) do
    decoded_token = Base.decode64!(token, padding: false)
    user = Authentication.get_user_by_session_token(decoded_token)

    case user do
      %User{} ->
        {
          :noreply,
          socket
          |> assign(:current_user, user)
          |> push_navigate(to: @user_profile_path)
        }

      _ ->
        send_update(TokenComponent, id: "token-component", token: :clear)
        {:noreply, socket}
    end
  end

  def handle_info({:token_cleared}, socket) do
    {
      :noreply,
      socket
      |> assign(:current_user, nil)
    }
  end

  def handle_info({:error, payload}, socket) do
    message = payload["message"]

    # Some errors don't need to be displayed to the user.
    ignored_errors = [
      "This request has been cancelled by the user."
    ]

    socket =
      if message not in ignored_errors do
        put_flash(socket, :error, payload["message"])
      else
        socket
      end

    {:noreply, socket}
  end

  def handle_info(event, socket) do
    Logger.warn(unhandled_event: event)
    {:noreply, socket}
  end

  defp build_new_user_key_attrs(params, new_user) do
    try do
      {
        :ok,
        %{
          user_id: new_user.id,
          key_id: params[:key_id],
          public_key: params[:public_key],
          user_handle: params[:user_handle]
        }
      }
    rescue
      error ->
        {:error, error}
    end
  end

  defp build_new_user_multi(params) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:user, %User{})
    |> Ecto.Multi.insert(:key, fn %{user: user} ->
      {:ok, attrs} = build_new_user_key_attrs(params, user)
      UserKey.new_changeset(%UserKey{}, attrs)
    end)
    |> Ecto.Multi.insert(:token, fn %{user: user} ->
      UserToken.build_session_token(user)
    end)
  end
end

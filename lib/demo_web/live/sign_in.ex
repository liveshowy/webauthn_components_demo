defmodule DemoWeb.Live.SignIn do
  @moduledoc """
  Example LiveView implementation of `WebauthnComponents`.

  Documentation may be found on [HexDocs](https://hexdocs.pm/webauthn_live_component/WebauthnComponents.html). See the [source code](https://github.com/liveshowy/webauthn_live_component_demo/blob/main/lib/demo_web/live/sign_in.ex) for complete implementation details.
  """
  use DemoWeb, :live_view
  require Logger
  alias Demo.Accounts.User
  alias Demo.Authentication
  alias Demo.Authentication.UserKey
  alias Demo.Authentication.UserToken
  alias Demo.Repo
  alias WebauthnComponents.AuthenticationComponent
  alias WebauthnComponents.RegistrationComponent
  alias WebauthnComponents.SupportComponent
  alias WebauthnComponents.TokenComponent
  alias WebauthnComponents.WebauthnUser

  @user_profile_path "/user/profile"

  def mount(_params, _session, socket) do
    user = %User{}
    changeset = User.changeset(user, %{"email" => nil})
    form = to_form(changeset, as: "user")

    {
      :ok,
      socket
      |> assign(:form, form)
      |> assign(:user, user)
    }
  end

  def handle_event("validate-email", %{"user" => params}, socket) do
    %{user: user} = socket.assigns

    changeset =
      user
      |> User.changeset(params)
      |> Map.put(:action, :insert)

    form = to_form(changeset, as: "user")
    user = Map.merge(user, changeset.changes)
    user_id = user.id || :crypto.strong_rand_bytes(64)

    webauthn_user = %WebauthnUser{
      id: Base.encode64(user_id, padding: false),
      name: user.email,
      display_name: user.email
    }

    send_update(RegistrationComponent, id: "registration-component", webauthn_user: webauthn_user)

    send_update(AuthenticationComponent,
      id: "authentication-component",
      webauthn_user: webauthn_user
    )

    {
      :noreply,
      socket
      |> assign(:form, form)
      |> assign(:user, user)
    }
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
    %{user: user} = socket.assigns
    user = Map.from_struct(user)
    multi = build_new_user_multi(%{key: params[:key], user: user})

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

  def handle_info({:find_credential, key_id: key_id}, socket) do
    user_key = Authentication.get_user_key_by_key_id(key_id, [:user])

    case user_key do
      %UserKey{} ->
        send_update(AuthenticationComponent, id: "authentication-component", user_key: user_key)
        {:noreply, socket}

      _ ->
        Logger.error(authentication_failure: {:user_key, user_key})

        {
          :noreply,
          socket
          |> put_flash(:error, "Failed to sign in.")
        }
    end
  end

  def handle_info({:authentication_successful, user: %User{} = user}, socket) do
    {:ok, token} = Authentication.generate_user_session_token(user)
    token64 = Base.encode64(token.token, padding: false)
    send_update(TokenComponent, id: "token-component", token: token64)

    {
      :noreply,
      socket
      |> assign(:current_user, user)
    }
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

  def handle_info({:invalid_token_returned, tokens}, socket) do
    Logger.warn(invalid_token_returned: tokens)

    {
      :noreply,
      socket
      |> put_flash(:error, "Failed to store token.")
    }
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
    %{key: key_params, user: user_params} = params

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:user, User.changeset(%User{}, user_params))
    |> Ecto.Multi.insert(:key, fn %{user: user} ->
      {:ok, attrs} = build_new_user_key_attrs(key_params, user)
      UserKey.new_changeset(%UserKey{}, attrs)
    end)
    |> Ecto.Multi.insert(:token, fn %{user: user} ->
      UserToken.build_session_token(user)
    end)
  end
end

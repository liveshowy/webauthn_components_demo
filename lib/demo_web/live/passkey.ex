defmodule DemoWeb.Live.Passkey do
  use DemoWeb, :live_view
  require Logger
  alias Demo.Authentication
  alias Demo.Accounts.User
  alias Demo.Authentication.UserKey
  alias Demo.Authentication.UserToken
  alias Demo.Repo
  alias WebAuthnLiveComponent.PasskeyComponent

  @user_profile_path "/user/profile"

  def mount(_params, _session, socket) do
    current_user = socket.assigns[:current_user]
    action = socket.assigns[:live_action]

    cond do
      action == :sign_out ->
        send_update(PasskeyComponent, id: "passkey-component", token: :clear)
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

      <.live_component module={PasskeyComponent} app={:demo_app} id="passkey-component" />
    </section>
    """
  end

  def handle_event(event, payload, socket) do
    Logger.warn(unhandled_event: event, payload: payload)
    {:noreply, socket}
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

  # TODO: verify token
  def handle_info({:user_token, _token}, socket) do
    {:noreply, socket}
  end

  def handle_info({:registration_successful, params}, socket) do
    multi = build_new_user_multi(params)

    case Repo.transaction(multi) do
      {:ok, %{user: user, key: _key, token: token}} ->
        send_update(PasskeyComponent, id: "passkey-component", token: token)

        {
          :noreply,
          socket
          |> assign(:current_user, user)
          |> put_flash(:info, "Successfully created a new account.")
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
        send_update(PasskeyComponent, id: "passkey-component", token: token64)

        {
          :noreply,
          socket
          |> assign(:current_user, user)
          |> put_flash(:info, "Successfully signed in.")
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
          |> put_flash(:info, "Already signed in.")
          |> push_navigate(to: @user_profile_path)
        }

      _ ->
        send_update(PasskeyComponent, id: "passkey-component", token: :clear)
        {:noreply, socket}
    end
  end

  def handle_info({:token_stored, token: token}, socket) do
    decoded_token = Base.decode64!(token, padding: false)
    user = Authentication.get_user_by_session_token(decoded_token, [:profile])

    case user do
      %User{profile: profile} ->
        {
          :noreply,
          socket
          |> assign(:current_user, user)
          |> push_navigate(to: @user_profile_path)
        }

      _ ->
        send_update(PasskeyComponent, id: "passkey-component", token: :clear)
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

defmodule Demo.Authentication do
  @moduledoc """
  The Authentication context.
  """

  import Ecto.Query, warn: false
  alias Demo.Repo
  alias Demo.Accounts.User
  alias Demo.Authentication.UserKey
  alias Demo.Authentication.UserToken

  # USER KEYS

  @doc """
  Returns the list of user_keys.

  ## Examples

      iex> list_user_keys()
      [%UserKey{}, ...]

  """
  def list_user_keys do
    Repo.all(UserKey)
  end

  @doc """
  Gets a single user_key.

  Raises `Ecto.NoResultsError` if the User key does not exist.

  ## Examples

      iex> get_user_key!(123)
      %UserKey{}

      iex> get_user_key!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user_key!(id), do: Repo.get!(UserKey, id)

  def get_user_key_by_key_id(key_id, preloads \\ []) do
    UserKey
    |> Repo.get_by(key_id: key_id)
    |> Repo.preload(preloads)
  end

  @doc """
  Creates a user_key.

  ## Examples

      iex> create_user_key(%{field: value})
      {:ok, %UserKey{}}

      iex> create_user_key(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user_key(attrs \\ %{}) do
    %UserKey{}
    |> UserKey.new_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user_key.

  ## Examples

      iex> update_user_key(user_key, %{field: new_value})
      {:ok, %UserKey{}}

      iex> update_user_key(user_key, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_key(%UserKey{} = user_key, attrs) do
    user_key
    |> UserKey.new_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a user_key.

  ## Examples

      iex> delete_user_key(user_key)
      {:ok, %UserKey{}}

      iex> delete_user_key(user_key)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user_key(%UserKey{} = user_key) do
    Repo.delete(user_key)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user_key changes.

  ## Examples

      iex> change_user_key(user_key)
      %Ecto.Changeset{data: %UserKey{}}

  """
  def change_user_key(%UserKey{} = user_key, attrs \\ %{}) do
    UserKey.update_changeset(user_key, attrs)
  end

  # USER TOKENS

  @doc """
  Gets a single user_token.

  Raises `Ecto.NoResultsError` if the User key does not exist.

  ## Examples

      iex> get_user_token!(123)
      %UserKey{}

      iex> get_user_token!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user_token!(id), do: Repo.get!(UserToken, id)

  @doc """
  Creates a user_token.

  ## Examples

      iex> create_user_token(%{field: value})
      {:ok, %UserKey{}}

      iex> create_user_token(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user_token(attrs \\ %{}) do
    UserToken
    |> UserToken.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Deletes a user_token.

  ## Examples

      iex> delete_user_token(user_token)
      {:ok, %UserKey{}}

      iex> delete_user_token(user_token)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user_token(%UserToken{} = user_token) do
    Repo.delete(user_token)
  end

  # SESSION TOKENS

  @doc """
  Generates a session token.
  """
  def generate_user_session_token(%User{} = user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  @doc """
  Gets the user with the given signed token.
  """
  def get_user_by_session_token(token, preloads \\ []) do
    {:ok, query} = UserToken.verify_session_token_query(token)

    query
    |> Repo.one()
    |> Repo.preload(preloads)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_session_token(token) do
    Repo.delete_all(UserToken.token_and_context_query(token, "session"))
    :ok
  end
end

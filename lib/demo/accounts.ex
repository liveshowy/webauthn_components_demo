defmodule Demo.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias Demo.Repo
  alias Ecto.Multi

  alias Demo.Accounts.User
  alias Demo.Authentication.UserKey

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users do
    Repo.all(User)
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  @doc """
  Lookup a user by key-value pair.

  ## Examples

      iex> get_user_by(:username, "owen)
      %User{}
  """
  def get_user_by(key, value, preloads \\ []) when is_atom(key) do
    keyword = [] |> Keyword.put(key, value)

    User
    |> Repo.get_by(keyword)
    |> Repo.preload(preloads)
  end

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  def create_user_with_key(user_attrs, key_attrs) do
    Multi.new()
    |> Multi.insert(:user, User.changeset(%User{}, user_attrs))
    |> Multi.merge(fn %{user: user} ->
      key_attrs = Map.put(key_attrs, :user_id, user.id)

      Multi.new()
      |> Multi.insert(:user_key, UserKey.new_changeset(%UserKey{}, key_attrs))
    end)
    |> Repo.transaction()
  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a user.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end
end

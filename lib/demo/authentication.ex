defmodule Demo.Authentication do
  @moduledoc """
  The Authentication context.
  """

  import Ecto.Query, warn: false
  alias Demo.Repo

  alias Demo.Authentication.UserKey

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
    |> UserKey.changeset(attrs)
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
    |> UserKey.changeset(attrs)
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
    UserKey.changeset(user_key, attrs)
  end
end

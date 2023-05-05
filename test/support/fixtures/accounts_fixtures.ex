defmodule Demo.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Demo.Accounts` context.
  """

  @doc """
  Generate a user.
  """
  def user_fixture(attrs \\ %{}) do
    user_attrs = Map.merge(%{email: "#{System.unique_integer([:positive])}@example.com"}, attrs)

    {:ok, user} = Demo.Accounts.create_user(user_attrs)

    user
  end
end

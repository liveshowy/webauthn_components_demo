defmodule Demo.AuthenticationFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Demo.Authentication` context.
  """
  import Demo.AccountsFixtures

  @doc """
  Generate a user_key.
  """
  def user_key_fixture(%{user: user} = attrs) do
    {:ok, user_key} =
      attrs
      |> Enum.into(%{
        key_id: :crypto.strong_rand_bytes(20),
        label: "some label",
        last_used: ~U[2022-08-28 00:10:00Z],
        public_key: :crypto.strong_rand_bytes(77),
        user_id: user.id
      })
      |> Demo.Authentication.create_user_key()

    user_key
  end
end

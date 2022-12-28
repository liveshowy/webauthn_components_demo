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
        key_id: :crypto.strong_rand_bytes(32),
        label: "some label",
        last_used: ~U[2022-08-28 00:10:00Z],
        public_key: public_key_fixture(),
        user_id: user.id,
        user_handle: :crypto.strong_rand_bytes(64)
      })
      |> Demo.Authentication.create_user_key()

    user_key
    |> Map.update!(:public_key, fn encoded_key ->
      {:ok, decoded_key, ""} = CBOR.decode(encoded_key)
      decoded_key
    end)
  end

  def public_key_fixture() do
    %{
      -3 => :crypto.strong_rand_bytes(32),
      -2 => :crypto.strong_rand_bytes(32),
      -1 => 1,
      1 => 2,
      3 => -7
    }
  end
end

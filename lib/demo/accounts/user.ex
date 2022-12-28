defmodule Demo.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias Demo.Accounts.UserProfile
  alias Demo.Authentication.UserKey
  alias Demo.Authentication.UserToken

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users" do
    has_many :keys, UserKey
    has_many :tokens, UserToken
    has_one :profile, UserProfile

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [])
    |> cast_assoc(:profile)
  end
end

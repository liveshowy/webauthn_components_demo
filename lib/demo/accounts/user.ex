defmodule Demo.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias Demo.Accounts.UserProfile
  alias Demo.Authentication.UserKey
  alias Demo.Authentication.UserToken

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users" do
    field :email, :string
    has_many :keys, UserKey
    has_many :tokens, UserToken
    has_one :profile, UserProfile

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email])
    |> validate_format(:email, ~r/@/)
    |> validate_length(:email, min: 6, max: 120)
    |> update_change(:email, &String.downcase/1)
    |> unique_constraint(:email)
  end
end

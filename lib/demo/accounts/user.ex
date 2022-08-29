defmodule Demo.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias Demo.Authentication.UserKey
  alias Demo.Authentication.UserToken

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users" do
    field :username, :string
    has_many :keys, UserKey
    has_many :tokens, UserToken

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:username])
    |> validate_required([:username])
    |> unique_constraint([:username])
    |> cast_assoc(:keys, with: &UserKey.new_changeset/2)
    |> cast_assoc(:tokens)
  end
end

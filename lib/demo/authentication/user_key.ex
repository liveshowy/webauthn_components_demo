defmodule Demo.Authentication.UserKey do
  use Ecto.Schema
  import Ecto.Changeset
  alias Demo.Accounts.User
  alias WebAuthnLiveComponent.CoseKey

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "user_keys" do
    field :key_id, :binary
    field :label, :string, default: "default"
    field :last_used, :utc_datetime
    field :public_key, CoseKey
    belongs_to :user, User

    timestamps()
  end

  @doc false
  def new_changeset(user_key, attrs) do
    user_key
    |> cast(attrs, [:user_id, :key_id, :public_key, :label, :last_used])
    |> validate_required([:user_id, :key_id, :public_key, :label])
    |> unique_constraint([:key_id])
    |> unique_constraint([:user_id, :label])
  end

  @doc false
  def update_changeset(user_key, attrs) do
    user_key
    |> cast(attrs, [:label, :last_used])
    |> validate_required([:label])
  end
end

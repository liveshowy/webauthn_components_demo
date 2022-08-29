defmodule Demo.Authentication.UserKey do
  use Ecto.Schema
  import Ecto.Changeset
  alias Demo.Accounts.User
  alias WebAuthnLiveComponent.CoseKey

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @derive {Jason.Encoder, only: [:key_id, :public_key, :label, :last_used]}
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
    |> update_change(:key_id, &Base.decode64!(&1, padding: false))
    |> foreign_key_constraint(:user_id)
    |> unique_constraint([:key_id], message: "key already registered")
    |> unique_constraint([:user_id, :label], message: "label already taken")
  end

  @doc false
  def update_changeset(user_key, attrs) do
    user_key
    |> cast(attrs, [:label, :last_used])
    |> validate_required([:label])
    |> unique_constraint([:user_id, :label], message: "label already taken")
  end
end

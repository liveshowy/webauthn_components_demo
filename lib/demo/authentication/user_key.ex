defmodule Demo.Authentication.UserKey do
  use Ecto.Schema
  import Ecto.Changeset
  alias Demo.Accounts.User
  alias WebAuthnLiveComponent.CoseKey

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @derive {Jason.Encoder, only: [:key_id, :public_key, :label, :last_used]}
  schema "user_keys" do
    field :label, :string, default: "default"
    field :key_id, :binary
    field :user_handle, :binary
    field :public_key, CoseKey
    belongs_to :user, User
    field :last_used, :utc_datetime

    timestamps()
  end

  def changeset(user_key, attrs \\ %{}) do
    user_key
    |> cast(attrs, [:user_id, :key_id, :public_key, :label, :user_handle])
  end

  @doc false
  def new_changeset(user_key, attrs) do
    user_key
    |> cast(attrs, [:user_id, :key_id, :public_key, :label, :user_handle])
    |> validate_required([:user_id, :key_id, :public_key, :label, :user_handle])
    |> foreign_key_constraint(:user_id)
    |> put_change(:last_used, get_timestamp())
    |> unique_constraint([:user_handle], message: "key already registered")
    |> unique_constraint([:key_id], message: "key already registered")
    |> unique_constraint([:user_id, :label], message: "label already taken")
  end

  @doc false
  def update_changeset(user_key, attrs) do
    user_key
    |> cast(attrs, [:label])
    |> validate_required([:label])
    |> unique_constraint([:user_id, :label], message: "label already taken")
    |> put_change(:last_used, get_timestamp())
  end

  def get_timestamp do
    DateTime.utc_now()
    |> DateTime.truncate(:second)
  end
end

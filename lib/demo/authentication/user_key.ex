defmodule Demo.Authentication.UserKey do
  use Ecto.Schema
  import Ecto.Changeset
  alias Demo.Accounts.User

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "user_keys" do
    field :key_id, :binary
    field :label, :string
    field :last_used, :utc_datetime
    field :public_key, :binary
    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(user_key, attrs) do
    user_key
    |> cast(attrs, [:user_id, :key_id, :public_key, :label, :last_used])
    |> validate_required([:user_id, :key_id, :public_key, :label])
  end
end

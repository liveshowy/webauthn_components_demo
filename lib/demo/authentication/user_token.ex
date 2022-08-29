defmodule Demo.Authentication.UserToken do
  use Ecto.Schema
  import Ecto.Changeset
  alias Demo.Accounts.User

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "user_tokens" do
    field :context, Ecto.Enum, values: [:session, :device_code], default: :session
    field :token, :binary
    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(user_token, attrs) do
    user_token
    |> cast(attrs, [:token, :context, :user_id])
    |> validate_required([:token, :context, :user_id])
  end
end

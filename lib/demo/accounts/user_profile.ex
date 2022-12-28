defmodule Demo.Accounts.UserProfile do
  use Ecto.Schema
  import Ecto.Changeset
  alias Demo.Accounts.User

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "user_profiles" do
    field :email, :string
    field :username, :string
    field :first_name, :string
    field :last_name, :string
    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(user_profile, attrs) do
    user_profile
    |> cast(attrs, [:user_id, :username, :email, :first_name, :last_name])
    |> foreign_key_constraint(:user_id)
    |> validate_required([:user_id, :username, :email])
    |> validate_length(:username, min: 2, max: 80)
    |> validate_length(:email, min: 6, max: 120)
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:email)
    |> unique_constraint(:username)
    |> unique_constraint(:user_id)
  end
end
